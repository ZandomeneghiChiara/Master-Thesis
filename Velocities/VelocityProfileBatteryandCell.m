clear 
close all 
clc 

% Ask user to select a CSV file
[filename, pathname] = uigetfile('*.csv', 'Select a CSV data file');
if isequal(filename, 0)
    disp('User canceled file selection.');
    return;
end

% Construct full file path
filepath = fullfile(pathname, filename);

% Import data from the selected CSV file
data = readtable(filepath, 'Delimiter', ';', 'HeaderLines', 4);

% Optional: Display variable names to help debugging
% disp(data.Properties.VariableNames);

%% Full Package
% Extract Data Columns 
x = str2double(string(data.('X_M_'))) / 1.e9; 
y = str2double(string(data.('Y_M_'))) / 1.e9;
velocity = str2double(string(data.('Velocity_MS__1_'))) / 1.e9; 

% Check NaNs
if any(isnan(x)) || any(isnan(y)) || any(isnan(velocity)) 
    warning('Some value could not be converted to numbers!'); 
end


% PLOT 1: Scatter Full Package
figure(1) 
scatter(x,y, 5, velocity / 1.e1, 'filled'); 
colorbar; 
xlabel('X [m]') 
ylabel('Y [m]') 
title('Velocity Distribution') 
axis equal 
grid on


%% Single Cell
% Define the center of the square (adjust as needed)
x_center = 0.3;      % Middle of X-range 
y_center = -0.18;     % Middle of Y-range 

% Define the square side length
square_side = 0.3;  % 0.3 m (half of X-range)

% Calculate square boundaries
x_min = x_center - square_side/2;
x_max = x_center + square_side/2;
y_min = y_center - square_side/2;
y_max = y_center + square_side/2;


% Extract data within the square
in_square = x >= x_min & x <= x_max & y >= y_min & y <= y_max;
x_square = x(in_square);
y_square = y(in_square);
v_square = velocity(in_square) / 1.e1;

% Define display scaling factors
x_scale = 1;     % For X-axis 
y_scale = 1;     % For Y-axis 
v_scale = 1;     % For velocity (keep in m/s)

% Format all numerical displays consistently
value_format = '%.2f';  % 2 decimal places for all values
sci_notation = true;    % Use scientific notation


% PLOT 2: Create the Square Zoom Plot
figure('Position', [200 200 700 700]);  % Square figure

% Velocity scatter plot (maintaining original colors)
scatter(x_square, y_square, 100, v_square, 'filled');
colormap(jet);
c = colorbar;
c.Label.String = 'Velocity [m/s]';
caxis([min(v_square), max(v_square)]);  % Global color scale

% Highlight the square boundaries (red dashed line)
hold on;
plot([x_min, x_max, x_max, x_min, x_min], ...
     [y_min, y_min, y_max, y_max, y_min], 'r--', 'LineWidth', 2);

% Mark the center point
plot(x_center, y_center, 'ro', 'MarkerSize', 5, 'LineWidth', 2);

% Uniform axis formatting
xlabel(sprintf('X [m]'), 'FontSize', 12);
ylabel(sprintf('Y [m]'), 'FontSize', 12);

% Format ticks uniformly
xtick_values = linspace(x_min, x_max, 10);
xtick_labels = arrayfun(@(v) sprintf(value_format, v/x_scale), ...
                xtick_values, 'UniformOutput', false);

ytick_values = linspace(y_min, y_max, 10);
ytick_labels = arrayfun(@(v) sprintf(value_format, v/y_scale), ... 
                ytick_values, 'UniformOutput', false);

xticks(xtick_values);
yticks(ytick_values);
xticklabels(xtick_labels);
yticklabels(ytick_labels); 

title('Velocity Distribution in Square Region', 'FontSize', 12);
grid on;
axis equal;
hold off;


% Format statistics display
stats_text = sprintf([ 'Square Region Stats:\n' ...
    'X: [' value_format ', ' value_format '] m\n' ...
    'Y: [' value_format ', ' value_format '] m\n' ...
    'Mean Velocity: ' value_format ' m/s\n' ...
    'Max Velocity: ' value_format ' m/s'], x_min/x_scale, x_max/x_scale, ...
    y_min/y_scale, y_max/y_scale, mean(v_square), max(v_square));

annotation('textbox', [0.10, 0.10, 0.10, 0.10], 'String', stats_text, ...
           'BackgroundColor', 'white', 'FontSize', 9);




