%%------------------------------------------------------------------------
% Code to load and postprocess raw data from COMSOL simulations of a
% single-junction perovskite solar cell. See Zhao Xinhai's PhD thesis for
% more details on the generation of the data.

%% PREPROCESSING
clear
format long
close all
clc
set(0,'DefaultFigureWindowStyle','docked') 
%% LOAD DATA

% Load input and output data from the text files
Output = load('iV_m.txt'); % output in the form of current density, A/m^2
Input = load('LHS_parameters_m.txt'); % 31 input parameters

% see MATLAB file for COMSOL sweep that defines the applied voltage range
Va = [0:0.1:0.4,0.425:0.025:1.4]; % applied voltage, V;

N = length(Output); % number of cases


%% iV-curve for the first case
figure(1)
plot(Va,Output(1,:),'.')
ylim([0 400])
title('IV Curve for First Case')


%% iV-curves for all cases
figure(2)
% We visualise the raw data
for i=1:N
    plot(Va,Output(i,:),'.')
    hold on
end
ylim([-200 400])
title('IV Curve for All Cases')


%% Output current density
figure(3)
boxplot(Output)
ylim([-2500 400])
grid on
title('Output Current Density')


%% Input data
figure(4)
boxplot(Input)
set(gca, 'YScale', 'log');
% Typesetting: labels for the inputs
xlabel("Input Parameters (Symbol/Unit)")

labels = {'\textit{$l^{\mathrm{H}}$}(nm)', '\textit{$l^{\mathrm{P}}$}(nm)', '\textit{$l^{\mathrm{E}}$}(nm)', ... % Layer thickness of H, P, E
          '$\mu^{\mathrm{H}}_{h}$($\mathrm{m^{2}\cdot V^{-1}\cdot s^{-1}})$', '$\mu^{\mathrm{P}}_{h}$($\mathrm{m^{2}\cdot V^{-1}\cdot s^{-1}})$', ... % Hole mobility in H, P
          '$\mu^{\mathrm{P}}_{e}$($\mathrm{m^{2}\cdot V^{-1}\cdot s^{-1}})$', '$\mu^{\mathrm{E}}_{e}$($\mathrm{m^{2}\cdot V^{-1}\cdot s^{-1}})$', ... % Electron mobility in P, E
          '\textit{$N^{\mathrm{H}}_{v}$}($\mathrm{m^{-3}})$', '\textit{$N^{\mathrm{H}}_{c}$}($\mathrm{m^{-3}})$', ... % Valence and Conduction band density of state in H
          '\textit{$N^{\mathrm{E}}_{v}$}($\mathrm{m^{-3}})$', '\textit{$N^{\mathrm{E}}_{c}$}($\mathrm{m^{-3}})$', ... % Valence and Conduction band density of state in E
          '\textit{$N^{\mathrm{P}}_{v}$}($\mathrm{m^{-3}})$', '\textit{$N^{\mathrm{P}}_{c}$}($\mathrm{m^{-3}})$', ... % Valence and Conduction band density of state in P
          '$\chi^{\mathrm{H}}_{h}$(eV)', '$\chi^{\mathrm{H}}_{e}$(eV)', ... % Hole ionization potential and Electron affinity in H
          '$\chi^{\mathrm{P}}_{h}$(eV)', '$\chi^{\mathrm{P}}_{e}$(eV)', ... % Hole ionization potential and Electron affinity in P
          '$\chi^{\mathrm{E}}_{h}$(eV)', '$\chi^{\mathrm{E}}_{e}$(eV)', ... % Hole ionization potential and Electron affinity in E
          '\textit{$W_{\mathrm{B}}$}(eV)', '\textit{$W_{\mathrm{F}}$}(eV)', ... % Work function of B and F
          '$\varepsilon^{\mathrm{H}}$', '$\varepsilon^{\mathrm{P}}$', '$\varepsilon^{\mathrm{E}}$', ... % Relative permittivity in H, P, E
          '\textit{$G_{\mathrm{avg}}$}($\mathrm{m^{-3}\cdot s^{-1}}$)', ... % Average charge carrier generation rate in P
          '\textit{$A_{(e, h)}$}($\mathrm{m^{6}\cdot s^{-1}}$)', ... % Auger recombination coefficient in P
          '\textit{$B_{\mathrm{rad}}$}($\mathrm{m^{3}\cdot s^{-1}}$)', ... % Radiative recombination coefficient in P
          '$\tau_{e}$(s)', '$\tau_{h}$(s)', ... % Electron and Hole lifetime in P
          '$\nu_{\mathrm{II}}$($\mathrm{m^{4}\cdot s^{-1}}$)', '$\nu_{\mathrm{III}}$($\mathrm{m^{4}\cdot s^{-1}}$)', ... % Interface recombination velocity at II and III
          '$\mathrm{{V}_{a}}$($\mathrm{V}$)'}; % Applied Voltage

ax = gca; % Get current axes
ax.XTick = 1:31; % Ensure there are 32 ticks
set(gca,'TickLabelInterpreter','latex'); 
ax.XTickLabel= labels; % Assign labels
%set(gca,'fontsize',15)
title('Range of Input Parameters')
grid on;

%% Mean, Min, and Max Current Density
figure(5)
curr_den_mean = mean(Output);
curr_den_max = max(Output);
curr_den_min = min(Output);
plot(Va, curr_den_mean, 'LineWidth', 2)
hold on
plot(Va, curr_den_min, 'LineWidth', 2)
plot(Va, curr_den_max, 'LineWidth', 2)
hold off
% ylim([-2500 400])
ylim([-400 400])
legend(["Mean", "Min", "Max"], 'Location', 'best')
grid on
title('Mean, Minimum, and Maximum J-V Curves')

%% Input data - Split boxplot into subplots for multiple figures
% Set up parameter groups
groups = {1:3, 4:7, 8:13, 14:19, 20:21, 22:24, 25, 26, 27, 28:29, 30:31};
titles = {"Layer Thicknesses", ...
    "Charge Carrier Mobilities", ...
    "Band Densities of State", ...
    "Hole Ionization Potentials and Electron Affinities", ...
    "Work Function of Electrodes", ...
    "Relative Permittivities", ...
    "Average Charge Carrier Generation Rate", ...
    "Auger Recombination Coefficient", ...
    "Radiative Recombination Coefficient", ...
    "Charge Carrier Lifetimes in AL", ...
    "Interface Recombination Velocities"}

% Initialize figure counter
figureCounter = 1;

% Loop through each group
for i = 7:9
    % Create a new figure for the group
    figure;
    if i == 7 || i == 8 || i == 9
        subplot(2, 3, 1);
    end
    
    % Select the columns of input data for the current group
    groupData = Input(:, groups{i});
    
    % Plot the boxplot for the current group
    boxplot(groupData);
    set(gca, 'YScale', 'log');
    
    % Set x-tick labels corresponding to the current group
    labelsGroup = labels(groups{i});
    ax = gca; % Get current axes
    ax.XTick = 1:length(groups{i}); % Ensure correct number of ticks
    set(gca, 'TickLabelInterpreter', 'latex');
    ax.XTickLabel = labelsGroup; % Assign labels for the group
    grid on;
    
    % Add a title to the figure
    title(titles(i), 'Interpreter', 'latex');
    
    % Save the figure
    saveas(gcf, ['Group_' num2str(figureCounter) '.png']);
    
    % Increment the figure counter
    figureCounter = figureCounter + 1;
end