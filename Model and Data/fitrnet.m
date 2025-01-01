%% Setup and Initialization 
clc; clear;
% close all; 
set(0,'DefaultFigureWindowStyle','docked') 

rng(42);

% Filenames
lhs_filename = "LHS_parameters_m.txt";
iv_filename = "iV_m.txt";
processed_lhs_filename = "lhs32DataFile.txt";
processed_iv_filename = "iDataFile.txt";

%% Figure configurarions
% Font
set(0, 'DefaultAxesFontName', 'Times New Roman'); % Set font to Times New Roman
set(0, 'DefaultTextFontName', 'Times New Roman'); % Set font for text
set(0, 'DefaultAxesFontSize', 10); % Font size for axes labels and ticks
set(0, 'DefaultTextFontSize', 10); % Font size for text labels

% Figure size
set(0, 'DefaultFigureUnits', 'centimeters');
set(0, 'DefaultFigurePosition', [2, 2, 2.3, 3]); % [x, y, width, height]

% % Set line width and marker size for better visibility (optional)
set(0, 'DefaultLineLineWidth', 1.5); % Line thickness
set(0, 'DefaultLineMarkerSize', 8); % Marker size

% Grid and box settings
set(0, 'DefaultAxesBox', 'on'); % Box around axes
set(0, 'DefaultAxesGridLineStyle', '-'); % Grid line style

%% Variations
FE = 0; % Feature Engineering 

autoHyperparams = 0; % Auto Optimize Hyperparameters

filter = 1; % Filter PSCs for FF >= 0.7

% folder to save figures
folder_name = '..\Results';

% name for saving figures
case_name = '';

if FE
    case_name = [case_name, 'T'];
else
    case_name = [case_name, 'F'];
end

if autoHyperparams
    case_name = [case_name, 'T'];
else
    case_name = [case_name, 'F'];
end

if filter
    case_name = [case_name, 'T'];
    boxplot_name = 'filtered';
else
    case_name = [case_name, 'F'];
    boxplot_name = 'not filtered';
end

% case_name = "FTF (Jsc)";
disp(case_name)
fprintf('\n');

%% Data Processing and Extraction
% process IV data to extract key points of interest
[~, ~, ~, ~, FF_values] = process_iv(lhs_filename, iv_filename, processed_lhs_filename, processed_iv_filename, filter);

% Define the file path
file_path = fullfile(folder_name, sprintf('%s %d boxplot.fig', boxplot_name, length(FF_values)));

% Check if the file already exists
if ~isfile(file_path)
    figure; 
    grid on;
    boxplot(FF_values);
    title("Fill Factor Values in Dataset");
    xlabel(sprintf('Dataset Size: %d', length(FF_values)));
    ylabel("FF Values");
    xticks([]);
    % saveas(gcf, file_path); % Save the figure if the file does not exist
end

%% Data Loading
if FE % Feature Engineering
    % Get most significant features according to other studies

    % ETL thickness: E_thickness (3)
    % charge carrier mobilities in hole transport layer (HTL), AL, and ETL:
    % H_muh (4), P_muh (5), P_mue (6), E_mue (7)
    % perovskite band gap: P_bg using hole ionization potential (16) and electron affinity (17)
    % electrode work functions: Wb (20), Wf (21)
    % applied voltage: Va (32)
    [E_thickness, H_muh, P_muh, P_mue, E_mue, P_xh, P_xe, Wb, Wf, Va] = ...
        getFeatures(processed_lhs_filename, 3, 4, 5, 6, 7, 16, 17, 20, 21, 32);
        
    % Calculate P-layer bandgaps
    P_bg = P_xh - P_xe;

    X = [E_thickness', H_muh', P_muh', P_mue', E_mue', P_bg', Wb', Wf', Va'];
    Y = load(processed_iv_filename);

else % no feature engineering
    X = load(processed_lhs_filename);
    % X = X(1:end, 1:31);

    Y = load(processed_iv_filename);
end

%% Data Validation
% Perform a size check and throw an error if the dimensions of X and Y do not match.
if size(X,1) ~= length(Y)
    error('X and Y have mismatched dimensions. Check data processing.');
end

%% Train Test Split
cv = cvpartition(size(X, 1), 'HoldOut', 0.2);  % 80% training, 20% testing
XTrain = X(training(cv), :);
YTrain = Y(training(cv));
XTest = X(test(cv), :);
YTest = Y(test(cv));


%% Model Setup and Training
if autoHyperparams
    netModel = fitrnet(XTrain, YTrain, 'Standardize', true, 'OptimizeHyperparameters', 'all');
    % Find ans save the optimization plot figure
    optFigure = findall(0, 'Type', 'Figure', 'Name', 'Min objective vs. Number of function evaluations');
    ax = findall(optFigure, 'Type', 'Axes');
    title(ax, sprintf('(%s) Min objective vs. Number of function evaluations', case_name));
    figureHandle = ancestor(optFigure, 'figure');
    % saveas(gcf, fullfile(folder_name, sprintf('%s hyperopt.fig', case_name)))
else
    netModel = fitrnet(XTrain, YTrain, ...
        'LayerSizes', [64, 32], ...
        'Activations', 'relu', ...
        'LayerWeightsInitializer', 'he', ...
        'LayerBiasesInitializer', 'zeros', ...
        'Lambda', 0, ...
        'Standardize', true);

    % % optimized hyperparams from FTF variant
    % netModel = fitrnet(XTrain, YTrain, ...
    % 'LayerSizes', [ 142, 124, 214], ...
    % 'Activations', 'sigmoid', ...
    % 'LayerWeightsInitializer', 'glorot', ...
    % 'LayerBiasesInitializer', 'zeros', ...
    % 'Lambda', 0.017029, ...
    % 'Standardize', true);
end


%% Model Prediction Evaluation
% Calculate Relative RMSE
YPred = predict(netModel, XTest);
rmse_test = sqrt(mean((YTest - YPred).^2));
meanYTest = mean(YTest);
RRMSE_test = (rmse_test / meanYTest) * 100;  % Relative RMSE as a percentage
disp(['Testing Relative RMSE: ', num2str(RRMSE_test), '%']);

% R-squared calculation
SStot_test = sum((YTest - meanYTest).^2);  % Total sum of squares
SSres_test = sum((YTest - YPred).^2);        % Residual sum of squares
R2_test = 1 - (SSres_test / SStot_test);               % R-squared formula
disp(['Testing R-squared: ', num2str(R2_test)]);
 

% Visual Assessment: Predicted vs. Observed
figure; hold on; grid on;
scatter(YTest, YPred, 'filled');
plot(xlim, xlim, 'r--', 'LineWidth', 1.5);  % y=x line
xlabel('Observed Values');
ylabel('Predicted Values');
title(sprintf('(%s) Predicted vs. Observed Values For Testing', case_name));
axis equal;  % Equal scaling on both axes
hold off;
% saveas(gcf, fullfile(folder_name, sprintf('%s testing.fig', case_name)));

%% Check for Overfitting 
% Calculate Relative RMSE
YPred_train = predict(netModel, XTrain);
rmse_train = sqrt(mean((YTrain - YPred_train).^2));
meanYTrain = mean(YTrain);
RRMSE_train = (rmse_train / meanYTrain) * 100;  % Relative RMSE as a percentage
disp(['Training Relative RMSE: ', num2str(RRMSE_train), '%']);

% R-squared calculation
SStot_train = sum((YTrain - meanYTrain).^2);  % Total sum of squares
SSres_train = sum((YTrain - YPred_train).^2);        % Residual sum of squares
R2_train = 1 - (SSres_train / SStot_train);               % R-squared formula
disp(['Training R-squared: ', num2str(R2_train)]);

fprintf('\n');

% Visual Assessment: Predicted vs. Observed
figure; hold on; grid on;
scatter(YTrain, YPred_train, 'filled');
plot(xlim, xlim, 'r--', 'LineWidth', 1.5);  % y=x line
xlabel('Observed Values');
ylabel('Predicted Values');
title(sprintf('(%s) Predicted vs. Observed Values For Training', case_name));
axis equal;  % Equal scaling on both axes
hold off;
% saveas(gcf, fullfile(folder_name, sprintf('%s training.fig', case_name)));
