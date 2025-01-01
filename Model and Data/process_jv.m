function [Voc_values, Jsc_values, Vmpp_values, Jmpp_values, FF_values] = process_jv(lhs_filename, jv_filename, processed_lhs_filename, processed_jv_filename, filter)

rng(42);

% Read current from file (assuming two columns: Voltage and Current)
current = load(jv_filename); 
N = length(current);

% Read LHS data from file (600 cells (rows), 31 parameters)
lines = readlines(lhs_filename);  % Reads all lines into a string array

% Create or open a file to write the current data
fid = fopen(processed_jv_filename, 'w'); % Open the file for writing

% Create a new file to write the voltage and LHS data
hid = fopen(processed_lhs_filename, 'w');

% Initialize arrays to store Jsc, MPP, and Voc values
Jsc_values = [];
Vmpp_values = [];
Voc_values = [];
Jmpp_values = [];
FF_values = [];  % Store PCE values
Rseries_values = [];  % Store Rseries values
Rshunt_values = [];
MSE_values = [];

% figure;
% hold on;
% ylim([-10 450]);
% xlabel('Voltage (V)');
% ylabel('Current (A)');
% title('Reconstructed Curves');
% grid on;

% array = zeros(8, 32, N);

for i = 1:N
    V = [0:0.1:0.4, 0.425:0.025:1.4]; % applied voltage V
    J = current(i, :);  % Current row

    % Find Open-Circuit Voltage (Voc) by interpolation
    [V, J, Voc, ~, ~, Jsc, Vmpp, Jmpp, FF, Rseries, Rshunt] = extractPOI(V, J);

    if ~filter || FF >= 0.70
        idx_voc = find(V == Voc, 1, 'first');
        idx_jsc = find(J == Jsc, 1, 'first');
        idx_mpp = find(V == Vmpp, 1, 'first');
    
        % Select Additional Points for Reconstruction
        idx_selected = round(linspace(idx_jsc+1, idx_voc-1, 12));
        idx_combined = unique([idx_jsc, idx_mpp, idx_voc, idx_selected]);

        desired_num_points = 15;
        if length(idx_combined) < desired_num_points % If fewer than desired_num_points
            additional_points_needed = desired_num_points - length(idx_combined);
            all_indices = idx_jsc:idx_voc;
            idx_remaining = setdiff(all_indices, idx_combined);  % Indices not already selected
            % Randomly select additional points
            if length(idx_remaining) >= additional_points_needed
                idx_additional = randsample(idx_remaining, additional_points_needed);
                idx_combined = unique([idx_combined, idx_additional]);
            else
                V_combined = V(idx_combined);

                V_range = linspace(V(idx_jsc), Voc, 20);
                V_range = setdiff(V_range, V_combined);
                V_additional = randsample(V_range, additional_points_needed);
                J_additional = interp1(V, J, V_additional, 'pchip');

                V = sort([V, V_additional]);
                J = sort([J, J_additional], "descend");
                
                V_additional = sort([V_additional, V_combined]);

                for point = 1:15
                    idx_selected = find(V == V_additional(point), 1, 'first');
                    idx_combined = unique([idx_combined, idx_selected]);
                end
            end
        end

        idx_combined = sort(idx_combined);
    
        % Get the corresponding voltages and currents from these indices
        V_selected = V(idx_combined);
        J_selected = J(idx_combined);
    
        
        % % Perform Interpolation for Reconstruction
        % V_fine = linspace(0, Voc, 45);  % Create a finer voltage range
        % J_fine = interp1(V_selected, J_selected, V_fine, 'pchip');  % Interpolated current
    
    
        % % Plot the jv Curve
        % h1 = plot(V_fine, J_fine, 'r-', 'LineWidth', 2); % Reconstructed curve
        % h2 = plot(V_selected, J_selected, 'kx', 'MarkerSize', 8);
        % h3 = plot(V(idx_jsc), J(idx_jsc), 'o', 'MarkerSize', 5, 'MarkerFaceColor', 'g');
        % h4 = plot(V(idx_mpp), J(idx_mpp), 'o', 'MarkerSize', 5, 'MarkerFaceColor', 'c');
        % h5 = plot(V(idx_voc), J(idx_voc), 'o', 'MarkerSize', 5, 'MarkerFaceColor', 'y'); 
        
        % % Plot original jv Curve for comparison
        % h6 = plot(V, J, 'b-'); 

        % % Legend
        % legend([h1, h2, h3, h4, h5, h6], ...
        %     'Reconstructed Curve', 'Selected Points', 'Short Circuit Current', 'Maximum Power Point', 'Open Circuit Voltage', 'Original Curve', ...
        %     'Location','best') 
        
        % Save voltage data to LHS file
        line = lines{i};  % LHS parameters as a string
        cell = '';  % Initialize an empty string

        for x = 1:length(V_selected)
            cell = [cell, sprintf('%s,%.15g\n', line, V_selected(x))];  % Append each V_selected with the line
            fprintf(fid, '%.15g\n', J_selected(x));
            % array(x,:, i) = [str2num(line), V_selected(x)];
        end

        fprintf(hid, '%s', cell);  % Write the complete string to the file
        
        
        % Append to arrays for boxplot
        Voc_values = [Voc_values; Voc];  
        Jsc_values = [Jsc_values; Jsc];  
        Vmpp_values = [Vmpp_values; Vmpp];  
        Jmpp_values = [Jmpp_values; Jmpp]; 
        FF_values = [FF_values; FF];  
        Rseries_values = [Rseries_values; Rseries];  
        Rshunt_values = [Rshunt_values; Rshunt];


        % % Error between reconstructed curve and original curve
        % % find the range of voltage in V_fine
        % max_V_fine = max(V_fine);
        % error_sum = 0;
        % 
        % % find the last index in V where the voltage is <= max(V_fine)
        % idx_error = find(V <= max_V_fine, 1, 'last');
        % 
        % % for k to last index in V
        % for k = 1:idx_error
        %     J_true = J(k);
        %     J_intrp = interp1(V_selected, J_selected, V(k), 'pchip');
        %     curr_error = J_true - J_intrp;
        %     error_sum = error_sum + (curr_error)^2;
        % end
        % MSE = error_sum / length(idx_error);
        % MSE_values = [MSE_values; MSE];
    end



end
avgMSE = mean(MSE_values);
% disp(avgMSE)

% Close the file after writing
fclose(fid);

% % Create subplots for each metric
% figure;
% 
% % Number of metrics to plot
% numMetrics = 7;
% 
% for j = 1:numMetrics
%     subplot(3, 3, j); % Create a 3x3 grid of subplots
% 
%     % Select data for the current metric
%     switch j
%         case 1
%             data = Jsc_values;
%             ylabelText = '$\mathrm{J_{sc}}$';
%         case 2
%             data = Vmpp_values;
%             ylabelText = '$\mathrm{V_{mpp}}$';
%         case 3
%             data = Jmpp_values;
%             ylabelText = '$\mathrm{J_{mpp}}$';
%         case 4
%             data = Voc_values;
%             ylabelText = '$\mathrm{V_{oc}}$';
%         case 5
%             data = Rseries_values;
%             ylabelText = '$\mathrm{R_{series}}$';
%         case 6
%             data = Rshunt_values;
%             ylabelText = '$\mathrm{R_{shunt}}$';
%         case 7 
%             data = FF_values;
%             ylabelText = 'Fill Factor';
%     end
% 
%     % Create boxplot for the current metric
%     boxplot(data, 'Labels', {ylabelText});
%     set(gca,'TickLabelInterpreter','latex');  
%     ylabel('Values');
%     title(['Boxplot of ', ylabelText], Interpreter='latex');
%     grid on;
% end

end