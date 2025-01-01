clear; clc; close all;
set(0,'DefaultFigureWindowStyle','docked') 

param_file = "LHS_parameters_m.txt";
iv_file = "iV_m.txt";

% Load the data
params = load(param_file);
iv = load(iv_file);

% Identify missing data
missingParams = isnan(params);
missingIV = isnan(iv);

% Count the missing data
mcParams = sum(missingParams);
mcIV = sum(missingIV);

% Display missing data count
disp('Missing Data Count for Parameters (params):');
disp(mcParams);
disp('Missing Data Count for IV Data (iv):');
disp(mcIV);

% Visualize the missing data using heatmap (difficult since too many entries)
figure;
heatmap(double(missingParams), 'ColorbarVisible', 'off', 'Colormap', parula);
title('Missing Data in Parameters (params)');
xlabel('Parameter Index');
ylabel('PSC Index');

figure;
heatmap(double(missingIV), 'ColorbarVisible', 'off', 'Colormap', parula);
title('Missing Data in IV Curve (iv)');
xlabel('Datapoint Index');
ylabel('PSC Index');

% Summarize missing data counts in a table
missingParamsSummary = table(mcParams', 'VariableNames', {'MissingCountInParams'});
disp('Missing Data Summary for Parameters:');
disp(missingParamsSummary);

missingIVSummary = table(mcIV', 'VariableNames', {'MissingCountInIV'});
disp('Missing Data Summary for IV Data:');
disp(missingIVSummary);

% Calculate total missing data and its percentage
totalParams = numel(params);
totalIV = numel(iv);

totalMissingParams = sum(missingParams(:));
totalMissingIV = sum(missingIV(:));

missingPercentageParams = (totalMissingParams / totalParams) * 100;
missingPercentageIV = (totalMissingIV / totalIV) * 100;

% Display the missing data report
fprintf('Total missing data in params: %d (%.2f%%)\n', totalMissingParams, missingPercentageParams);
fprintf('Total missing data in iv: %d (%.2f%%)\n', totalMissingIV, missingPercentageIV);

% Count non-missing data per parameter (column-wise)
nonMissingDataPerParam = sum(~missingParams, 1); % Sum non-missing values for each column
nonMissingDataPerIV = sum(~missingIV, 1); % Sum non-missing values for each column in IV data

% Calculate the percentage of non-missing data for each parameter
nonMissingPercentagePerParam = (nonMissingDataPerParam / size(params, 1)) * 100;

% Calculate the percentage of non-missing data for each IV data point
nonMissingPercentagePerIV = (nonMissingDataPerIV / size(iv, 1)) * 100;

% Plot non-missing percentage per parameter as a bar chart
figure;
bar(nonMissingPercentagePerParam);
xlabel('Parameter Index');
ylabel('Percentage of Non-Missing Entries (%)');
title('Non-Missing Data Percentage in Input Parameter Dataset');
set(gca, 'FontSize', 8);
xticks(1:31); % Set x-axis ticks from 1 to 31
xticklabels(1:31); % Set x-axis labels from 1 to 31
ylim([0 100]); % Set y-axis limit to 0-100%

% Plot non-missing percentage per IV data as a bar chart
figure;
bar(nonMissingPercentagePerIV);
xlabel('IV Data Point Index');
ylabel('Percentage of Non-Missing Entries (%)');
title('Non-Missing Data Percentage in J-V Curve Dataset');
set(gca, 'FontSize', 8);
xticks(1:45); % Set x-axis ticks from 1 to 45
xticklabels(1:45); % Set x-axis labels from 1 to 45
ylim([0 100]); % Set y-axis limit to 0-100%

% Summary figure: Calculate overall non-missing percentage for both datasets
overallNonMissingParam = (sum(~missingParams(:)) / totalParams) * 100;
overallNonMissingIV = (sum(~missingIV(:)) / totalIV) * 100;

% Create a bar chart with the overall non-missing percentages for both datasets
figure;
b = bar([overallNonMissingParam, overallNonMissingIV]);

% Adjust the width of the bars (default is 0.8, lower value = thinner bars)
b.BarWidth = 0.5; 

xticks([1, 2]);
xticklabels({'Input Parameters', 'J-V Data Points'});
ylabel('Percentage of Valid Entries (%)');
title('Valid Entries in the Dataset');
ylim([0 103]); 
