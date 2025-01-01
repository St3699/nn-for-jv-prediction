% reconstruct JV
% Function to randomly choose an entry 'i', reconstruct its JV curve,
% and plot both the original and reconstructed JV curves.

set(0, 'DefaultAxesFontName', 'Times New Roman'); % Set font to Times New Roman
set(0, 'DefaultTextFontName', 'Times New Roman'); % Set font for text
set(0, 'DefaultAxesFontSize', 8); % Font size for axes labels and ticks
set(0, 'DefaultTextFontSize', 8); % Font size for text labels

% Figure size
set(0, 'DefaultFigureUnits', 'centimeters');
set(0, 'DefaultFigurePosition', [0, 0, 14, 13.5]); % [x, y, width, height]

% % Set line width and marker size for better visibility (optional)
set(0, 'DefaultLineLineWidth', 1.5); % Line thickness
set(0, 'DefaultLineMarkerSize', 8); % Marker size

% Grid and box settings
set(0, 'DefaultAxesBox', 'on'); % Box around axes
set(0, 'DefaultAxesGridLineStyle', '-'); % Grid line style

rng('shuffle'); % Shuffle the random seed for true randomness

lhs_filename = "LHS_parameters_m.txt";
jv_filename = "iV_m.txt";
methods = {'linear', 'pchip', 'makima', 'spline'};
method_names = {'Linear', 'PCHIP', 'Makima', 'Cubic Spline'};

% Load data
current = load(jv_filename); % Assuming two columns: Voltage and Current
lines = readlines(lhs_filename); % Load LHS data as string array

N = size(current, 1); % Total number of JV curves
V = [0:0.1:0.4, 0.425:0.025:1.4]; % Applied voltage (assume consistent across entries)

% Randomly choose an index i
% i = randi(N);
% i = 6;
% i = 15;
% i = 605;
% i = 121;
% i - 31;
i = 134; % i think this is best

% Extract current data for the chosen index
J = current(i, :);

figure;
legend_handles = []; % Store plot handles for legend
for n = 1:length(methods)
    method = methods{n};
    method_name = method_names{n};

    % Calculate open circuit voltage
    [J_unique, idx_unique] = unique(J);
    V_unique = V(idx_unique);
    Voc = interp1(J_unique, V_unique, 0, method); 
    Joc = 0;
    V = sort([V, Voc]);
    J = sort([J, Joc], "descend");
    
    % Calculate short circuit current
    [~, idx_jsc] = find(V == 0, 1, 'first');
    Jsc = J(idx_jsc);
    Vsc = V(idx_jsc);
    
    % Calculate maximum power point
    V_fine = linspace(min(V), max(V), 200);  % Create a fine voltage grid
    [J_unique, idx_unique] = unique(J);
    V_unique = V(idx_unique);
    J_fine = interp1(V_unique, J_unique, V_fine, method);
    P = V_fine .* J_fine; 
    dP_dV = gradient(P, V_fine);
    % Find where dP/dV crosses zero
    z = find(diff(sign(dP_dV)) ~= 0, 1, 'first');
    Vmpp = interp1(dP_dV(z:z+1), V_fine(z:z+1), 0, 'linear');
    Jmpp = interp1(V_unique, J_unique, Vmpp, method);  % Interpolate J at Vmpp
    V = sort([V, Vmpp]);
    J = sort([J, Jmpp], "descend");
    
    idx_voc = find(V == Voc, 1, 'first');
    idx_jsc = find(J == Jsc, 1, 'first');
    idx_mpp = find(V == Vmpp, 1, 'first');
    
    % Select Additional Points for Reconstruction
    idx_selected = round(linspace(idx_jsc+1, idx_voc-1, 12));
    idx_combined = unique([idx_jsc, idx_mpp, idx_voc, idx_selected]);
    
    % Ensure 15 points are selected
    desired_num_points = 15;
    if length(idx_combined) < desired_num_points
        additional_points_needed = desired_num_points - length(idx_combined);
        all_indices = idx_jsc:idx_voc;
        idx_remaining = setdiff(all_indices, idx_combined);
        if length(idx_remaining) >= additional_points_needed
            idx_additional = randsample(idx_remaining, additional_points_needed);
            idx_combined = unique([idx_combined, idx_additional]);
        end
    end
    
    idx_combined = sort(idx_combined);
    V_selected = V(idx_combined);
    J_selected = J(idx_combined);
    
    % Perform interpolation for reconstruction
    V_fine = linspace(0, Voc, 100); % Create a fine voltage grid
    J_fine = interp1(V_selected, J_selected, V_fine, method);
    
    % Plot original and reconstructed JV curves
    subplot(2, 2, n);
    % figure;
    h1 = plot(V, J, 'b-', 'LineWidth', 1); % Original JV curve
    hold on;
    h2 = plot(V_fine, J_fine, 'r--', 'LineWidth', 1); % Reconstructed curve
    h3 = plot(V_selected, J_selected, 'kx', 'MarkerSize', 8); % Selected points
    if n == 1
        legend_handles = [h1, h2, h3]; % Store handles for legend
    end
    xlabel('Voltage (V)');
    ylabel('Current (A)');
    title(sprintf('%s Reconstruction', method_name));
    ylimup = ceil(max(J) / 50) * 50;
    ylim([0 ylimup]);
    grid on;
    hold off;
end

% Add a single legend for the entire figure
legend(legend_handles, {'Original Curve', 'Reconstructed Curve', 'Selected Points'}, 'Position', [0.4, 0, 0.2, 0.05], 'Orientation', 'horizontal');

% Adjust overall figure appearance
sgtitle(sprintf('JV Curve Reconstruction for Entry No. %d', i)); % Super title for all subplots
