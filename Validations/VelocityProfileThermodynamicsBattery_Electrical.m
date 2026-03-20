clear 
close all 
clc 

%% Load CSV Data
% Define the file path directly
% filepath = 'prova54_3x8_HV_Cells_3mm-30deg(correct).csv';
filepath = 'prova53_3x4_HV_Cells_3mm-30deg(correct).csv';

% Import data from the specified CSV file
data = readtable(filepath, 'Delimiter', ';', 'HeaderLines', 4);

% Extract columns and convert units 
x = str2double(string(data.('X_M_'))) / 1.e9;
y = str2double(string(data.('Y_M_'))) / 1.e9;
velocity = str2double(string(data.('Velocity_MS__1_'))) / 1.e9;

% Check for NaNs
if any(isnan(x)) || any(isnan(y)) || any(isnan(velocity))
    warning('Some values could not be converted to numbers!');
end

% Rotate the coordinates 90 degrees counterclockwise
x_rotated = -y;      % New x = old y
y_rotated = x;       % New y = old x

%% Manual Zoomed-In Region

% Rotate the zoom box boundaries
x_min = min(x_rotated);
x_max = max(x_rotated);
y_min = min(y_rotated);
y_max = max(y_rotated);

% Extract data inside square (using rotated coordinates)
x_center = x_min + (x_max - x_min) / 2;
y_center = y_min + (y_max - y_min) / 2;

in_square = x_rotated >= x_min & x_rotated <= x_max & y_rotated >= y_min & y_rotated <= y_max;
x_square = x_rotated(in_square);
y_square = y_rotated(in_square);
v_square = velocity(in_square) / 1.e1;

%% Plot Velocity Map
figure('Position', [200, 200, 700, 700]);
scatter(x_square, y_square, 100, v_square, 'filled');
colormap(jet);
c = colorbar;
c.Label.String = 'Velocity [m/s]';
caxis([min(v_square), max(v_square)]);
hold on;

% Draw zoom box (using rotated coordinates)
plot([x_min, x_max, x_max, x_min, x_min], ...
     [y_min, y_min, y_max, y_max, y_min], 'b-', 'LineWidth', 2);

% Axis ticks
xtick_values = linspace(x_min, x_max, 10);
xtick_labels = arrayfun(@(v) sprintf('%.2f', v), xtick_values, 'UniformOutput', false);
ytick_values = linspace(y_min, y_max, 10);
ytick_labels = arrayfun(@(v) sprintf('%.2f', v), ytick_values, 'UniformOutput', false);
xticks(xtick_values); yticks(ytick_values);
xticklabels(xtick_labels); yticklabels(ytick_labels);

xlabel('X [m]');
ylabel('Y [m]');
title('Velocity Distribution with Hexagon Grid');
axis equal;

% Add light gray grid every 0.01 (using rotated coordinates)
x_grid = min(x_square)-0.05:0.01:max(x_square)+0.05;
y_grid = min(y_square)-0.05:0.01:max(y_square)+0.05;


% Display stats
stats_text = sprintf(['Square Region Stats:\n' ...
    'X: [%.2f, %.2f] m\nY: [%.2f, %.2f] m\n' ...
    'Mean Velocity: %.2f m/s\nMax Velocity: %.2f m/s'], ...
    x_min, x_max, y_min, y_max, mean(v_square), max(v_square));
annotation('textbox', [0.50, 0.15, 0.10, 0.10], 'String', stats_text, ...
           'BackgroundColor', 'white', 'FontSize', 9);

%% Draw Hexagons with Shared Sides (Rows and Columns)
% hex_radius = 0.09 + 0.0255;             % 3x8
% hex_height = sqrt(3) * hex_radius;      % 3x8 
% vertical_spacing =  hex_height;         % 3x8
% horizontal_spacing = 1.51 * hex_radius; % 3x8

hex_radius = 0.09 + 0.0255;             % 3x4
hex_height = sqrt(3) * hex_radius;      % 3x4 
vertical_spacing =  hex_height;         % 3x4
horizontal_spacing = 1.51 * hex_radius; % 3x4 

num_rows = 3; 
num_cols = 4;   
% num_cols = 8; 

x_start = 0;        
y_start = 0.5;       


angles_deg = 0:60:300;
angles_rad = deg2rad(angles_deg);

% Store x-center and y-center for each column
x_centers_all = [];

for row = 0:num_rows-1
    for col = -1:num_cols  % includes 1 ghost before and 1 after
        % Compute center of hexagon
        x_offset = x_start + col * horizontal_spacing;
        if mod(col, 2) == 1
            y_offset = y_start - row * vertical_spacing;
        else
            y_offset = y_start - row * vertical_spacing - hex_height/2;
        end

        xc = x_offset;
        yc = y_offset;

        % Store x-centers (once per column)
        if row == 0
            x_centers_all(end+1) = xc;
        end

        % Outer hexagon corners
        hex_x = xc + hex_radius * cos(angles_rad);
        hex_y = yc + hex_radius * sin(angles_rad);
        hexagon_points = [hex_x', hex_y'];

        % Plot outer hexagon
        if col == -1 || col == num_cols
            % Ghost columns (gray)
            plot([hex_x, hex_x(1)], [hex_y, hex_y(1)], 'Color', [0.6, 0.6, 0.6], 'LineWidth', 1);
        else
            % Real columns (red)
            plot([hex_x, hex_x(1)], [hex_y, hex_y(1)], 'r', 'LineWidth', 1.5);
        end

        % Compute triangles & barycenters
        barycenters = zeros(6, 2);
        for k = 1:6
            p1 = [xc, yc];
            p2 = hexagon_points(k, :);
            p3 = hexagon_points(mod(k,6)+1, :);
            barycenters(k, :) = (p1 + p2 + p3) / 3;

            if k ~= 1 && k ~= 4
                plot([p1(1), p2(1), p3(1), p1(1)], ...
                     [p1(2), p2(2), p3(2), p1(2)], 'b:');
            end
        end

        % Draw internal hexagon from barycenters
        plot([barycenters(:,1); barycenters(1,1)], ...
             [barycenters(:,2); barycenters(1,2)], 'k-', 'LineWidth', 2);
        plot(barycenters(:,1), barycenters(:,2), 'k.', 'MarkerSize', 8, 'LineWidth', 2);
       end
end

% Draw 10 vertical dashed lines through x-centers of each column
y_min_line = y_start - (num_rows + 0.5) * vertical_spacing;
y_max_line = y_start + vertical_spacing;

for i = 1:length(x_centers_all)
    x_val = x_centers_all(i);
    plot([x_val, x_val], [y_min_line, y_max_line], '--', 'Color', [0.6, 0.6, 0.6]);
end 

