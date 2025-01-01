function [Voc_values, Isc_values, Vmpp_values, Impp_values, FF_values] = process_iv_Jsc(lhs_filename, iv_filename, processed_lhs_filename, processed_iv_filename, filter)

rng(42);

% Read current from file (assuming two columns: Voltage and Current)
current = load(iv_filename); 
N = length(current);

% Read LHS data from file (600 cells (rows), 31 parameters)
lines = readlines(lhs_filename);  % Reads all lines into a string array

% Create or open a file to write the current data
fid = fopen(processed_iv_filename, 'w'); % Open the file for writing

% Create a new file to write the voltage and LHS data
hid = fopen(processed_lhs_filename, 'w');

% Initialize arrays to store Isc, MPP, and Voc values
Isc_values = [];
Vmpp_values = [];
Voc_values = [];
Impp_values = [];
FF_values = []; 
Rseries_values = [];  
Rshunt_values = [];
MSE_values = [];


for i = 1:N
    V = [0:0.1:0.4, 0.425:0.025:1.4]; % applied voltage V
    I = current(i, :);  % Current row

    % Find Open-Circuit Voltage (Voc) by interpolation
    [V, I, Voc, ~, ~, Isc, Vmpp, Impp, FF, Rseries, Rshunt] = extractPOI(V, I);

    if ~filter || FF >= 0.70
        idx_voc = find(V == Voc, 1, 'first');
        idx_isc = find(I == Isc, 1, 'first');
        idx_mpp = find(V == Vmpp, 1, 'first');
    
        % Select Additional Points for Reconstruction
        idx_selected = round(linspace(idx_isc+1, idx_voc-1, 12));
        idx_combined = unique([idx_isc, idx_mpp, idx_voc, idx_selected]);

        desired_num_points = 15;
        if length(idx_combined) < desired_num_points % If fewer than desired_num_points
            additional_points_needed = desired_num_points - length(idx_combined);
            all_indices = idx_isc:idx_voc;
            idx_remaining = setdiff(all_indices, idx_combined);  % Indices not already selected
            % Randomly select additional points
            if length(idx_remaining) >= additional_points_needed
                idx_additional = randsample(idx_remaining, additional_points_needed);
                idx_combined = unique([idx_combined, idx_additional]);
            else
                V_combined = V(idx_combined);

                V_range = linspace(V(idx_isc), Voc, 20);
                V_range = setdiff(V_range, V_combined);
                V_additional = randsample(V_range, additional_points_needed);
                I_additional = interp1(V, I, V_additional, 'pchip');

                V = sort([V, V_additional]);
                I = sort([I, I_additional], "descend");
                
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
        I_selected = I(idx_combined);
    
        % Save voltage data to LHS file
        line = lines{i};  % LHS parameters as a string
        cell = '';  % Initialize an empty string

        cell = [cell, sprintf('%s,%.15g\n', line, V_selected(1))];
        fprintf(fid, '%.15g\n', I_selected(1));

        fprintf(hid, '%s', cell);  % Write the complete string to the file
        
        
        % Append to arrays for boxplot
        Voc_values = [Voc_values; Voc];  
        Isc_values = [Isc_values; Isc];  
        Vmpp_values = [Vmpp_values; Vmpp];  
        Impp_values = [Impp_values; Impp]; 
        FF_values = [FF_values; FF];  
        Rseries_values = [Rseries_values; Rseries];  
        Rshunt_values = [Rshunt_values; Rshunt];

    end



end


% Close the file after writing
fclose(fid);



end