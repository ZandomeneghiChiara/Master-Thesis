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

% Extract Data Columns 
x = str2double(string(data.('X_M_'))) / 1.e9; 
y = str2double(string(data.('Y_M_'))) / 1.e9;
velocity = str2double(string(data.('Velocity_MS__1_'))) / 1.e9; 

% Check NaNs
if any(isnan(x)) || any(isnan(y)) || any(isnan(velocity)) 
    warning('Some value could not be converted to numbers!'); 
end

%% Zoomed Region Parameters (Manual Zoom Box)
x_center = 0.205; 
y_center = -0.35; 
square_side = 0.4; 

x_min = x_center - square_side/2;
x_max = x_center + square_side/2;
y_min = y_center - square_side/2;
y_max = y_center + square_side/2;

% Extract data within square
in_square = x >= x_min & x <= x_max & y >= y_min & y <= y_max;
x_square = x(in_square);
y_square = y(in_square);
v_square = velocity(in_square) / 1.e1;

%% Detect Cluster Centers using DBSCAN
coords = [x_square, y_square];

% Tune these parameters based on spacing in your data
epsilon = 0.08;  % neighborhood radius
minpts = 5;      % minimum neighbors for a cluster

cluster_labels = dbscan(coords, epsilon, minpts);

% Get cluster centroids
unique_clusters = unique(cluster_labels);
unique_clusters(unique_clusters == -1) = [];  % Remove noise
centroids = zeros(length(unique_clusters), 2);

for i = 1:length(unique_clusters)
    pts = coords(cluster_labels == unique_clusters(i), :);
    centroids(i, :) = mean(pts, 1);
end

%% Plot Velocity Distribution
figure('Position', [200 200 700 700]);
scatter(x_square, y_square, 100, v_square, 'filled');
colormap(jet);
c = colorbar;
c.Label.String = 'Velocity [m/s]';
caxis([min(v_square), max(v_square)]);
hold on;

% Draw square boundary
plot([x_min, x_max, x_max, x_min, x_min], ...
     [y_min, y_min, y_max, y_max, y_min], 'r--', 'LineWidth', 2);

% Tick formatting
xtick_values = linspace(x_min, x_max, 10);
xtick_labels = arrayfun(@(v) sprintf('%.2f', v), xtick_values, 'UniformOutput', false);
ytick_values = linspace(y_min, y_max, 10);
ytick_labels = arrayfun(@(v) sprintf('%.2f', v), ytick_values, 'UniformOutput', false);
xticks(xtick_values); yticks(ytick_values);
xticklabels(xtick_labels); yticklabels(ytick_labels);

xlabel('X [m]');
ylabel('Y [m]');
title('Velocity Distribution with Auto-Detected Hexagons');
grid on;
axis equal;

% Stats
stats_text = sprintf(['Square Region Stats:\n' ...
    'X: [%.2f, %.2f] m\nY: [%.2f, %.2f] m\n' ...
    'Mean Velocity: %.2f m/s\nMax Velocity: %.2f m/s'], ...
    x_min, x_max, y_min, y_max, mean(v_square), max(v_square));
annotation('textbox', [0.10, 0.10, 0.10, 0.10], 'String', stats_text, ...
           'BackgroundColor', 'white', 'FontSize', 9);

%% Draw Hexagons Around Detected Centers
hex_radius = 0.09 + 0.03;        % Distance from center to corner
angles_deg = 0:60:300;
angles_rad = deg2rad(angles_deg);

for i = 1:size(centroids, 1)
    xc = centroids(i,1);
    yc = centroids(i,2);

    % Compute outer hexagon points
    hex_x = xc + hex_radius * cos(angles_rad);
    hex_y = yc + hex_radius * sin(angles_rad);
    hexagon_points = [hex_x', hex_y'];

    % Compute barycenters of 6 triangles
    barycenters = zeros(6, 2);
    for k = 1:6
        p1 = [xc, yc];
        p2 = hexagon_points(k, :);
        p3 = hexagon_points(mod(k,6)+1, :);
        barycenters(k, :) = (p1 + p2 + p3) / 3;

        % Plot triangle edges
        plot([p1(1), p2(1), p3(1), p1(1)], ...
             [p1(2), p2(2), p3(2), p1(2)], 'b:');
    end

    % Plot outer hexagon
    plot([hex_x, hex_x(1)], [hex_y, hex_y(1)], 'k-', 'LineWidth', 1.5);

    % Plot barycenters
    plot(barycenters(:,1), barycenters(:,2), 'ro', 'MarkerSize', 8, 'LineWidth', 2);

    % Connect barycenters to form internal hexagon
    plot([barycenters(:,1); barycenters(1,1)], ...
         [barycenters(:,2); barycenters(1,2)], 'r-', 'LineWidth', 2);
end






