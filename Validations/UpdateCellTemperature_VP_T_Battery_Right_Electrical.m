clear 
close all
clc 

% Load CSV Data
% Define the file path directly
filepath = 'prova54_3x8_HV_Cells_3mm-30deg(correct).csv';
% filepath = 'prova53_3x4_HV_Cells_3mm-30deg(correct).csv'; 

% Import data from the specified CSV file
data = readtable(filepath, 'Delimiter', ';', 'HeaderLines', 4);

x_original = str2double(string(data.('X_M_'))) / 1.e9;
y_original = str2double(string(data.('Y_M_'))) / 1.e9;
velocity = str2double(string(data.('Velocity_MS__1_'))) / 1.e9;

% Rotate the coordinates 90 degrees counterclockwise
x = -y_original;      % New x = old y  
y = x_original;       % New y = -old x 

if any(isnan(x)) || any(isnan(y)) || any(isnan(velocity))
    warning('Some values could not be converted to numbers!');
end

x_square = x;
y_square = y;
v_square = velocity / 1.e1;

%% Hexagon Grid Setup 
hex_radius = 0.09 + 0.0255;             % 3x8
hex_height = sqrt(3) * hex_radius;      % 3x8 
vertical_spacing =  hex_height;         % 3x8
horizontal_spacing = 1.51 * hex_radius; % 3x8

% hex_radius = 0.09 + 0.0255;             % 3x4
% hex_height = sqrt(3) * hex_radius;      % 3x4 
% vertical_spacing =  hex_height;         % 3x4
% horizontal_spacing = 1.51 * hex_radius; % 3x4 

num_rows = 3; 
num_cols = 8;
% num_cols = 4;

x_start = 0;       
y_start = 0.5;       


x_centers_all = [];
y_centers_all = [];

for row = 0:num_rows-1
    for col = 0:num_cols-1 
        x_offset = x_start + col * horizontal_spacing;
        if mod(col, 2) == 1
            y_offset = y_start - row * vertical_spacing - hex_height/2;
        else
            y_offset = y_start - row * vertical_spacing;
        end
        x_centers_all(end+1) = x_offset;
        y_centers_all(end+1) = y_offset;
    end
end

%% Thermal Parameters
rho = 1.225;
mu = 1.7894e-5; 
C_air = 1005; 
alpha = -0.8; 
beta = 0; 
C_a = 0.01;  
k = 0.026; 
deltat = 0.1; 
dTheta = 20; 
dTheta_rad = deg2rad(dTheta); 
r = 0.009; 
li = hex_height;  
lip1 = hex_height;  
T0 = 308; % Ambient temp 

%% Precompute hex shape
angles = linspace(0, 2*pi, 7); 
hex_x = hex_radius * cos(angles);
hex_y = hex_radius * sin(angles);

%% Plot Setup
figure;
axis equal;
hold on;
colormap jet;
title('3x4 Hexagon Grid: Left & Right Temperatures');
xlabel('X Position (m)');
ylabel('Y Position (m)');

%% Analyze and Plot First 3 Rows × All Columns
T_left_all = zeros(num_rows, num_cols);  
T_right_all = zeros(num_rows, num_cols);  

for col = 1:num_cols
    for row = 1:num_rows  
        idx = (col - 1) * num_rows + row;
        xc = x_centers_all(idx);
        yc = y_centers_all(idx);

        r_hex = hex_radius;

        % Points inside the hexagon
        in_hex = x_square >= (xc - r_hex) & x_square <= (xc + r_hex) & ...
                 y_square >= (yc - hex_height/2) & y_square <= (yc + hex_height/2);

        x_local = x_square(in_hex);
        y_local = y_square(in_hex);
        v_local_points = v_square(in_hex);

        % Split into left and right
        is_left = x_local <= xc;
        is_right = x_local > xc;

        v_left = mean(v_local_points(is_left), 'omitnan');
        v_right = mean(v_local_points(is_right), 'omitnan');

        if isempty(v_left) || isnan(v_left), v_left = 1e-5; end
        if isempty(v_right) || isnan(v_right), v_right = 1e-5; end

        % Compute left temp  
        Re_left = (rho * v_left * 2 * hex_radius) / mu;  
        W_theta_left = C_a * v_left^alpha * Re_left^beta;
        denom_left = (rho * (li * lip1 + lip1) * v_left * deltat - r * dTheta_rad);
        numer_left = (rho * (li * lip1 + lip1) * v_left * deltat * C_air * T0 + k - (r * dTheta_rad) / W_theta_left);
        T_left = (W_theta_left / denom_left) * numer_left;

        % Compute right temp
        Re_right = (rho * v_right * 2 * hex_radius) / mu;
        W_theta_right = C_a * v_right^alpha * Re_right^beta;
        denom_right = (rho * (li * lip1 + lip1) * v_right * deltat - r * dTheta_rad);
        numer_right = ((rho * (li * lip1 + lip1) * v_right * deltat) * C_air * T_left + k - ((r * dTheta_rad) / W_theta_right));
        T_right = (W_theta_right / denom_right) * numer_right;


        % Store for matrix output
        T_left_all(row, col) = T_left;
        T_right_all(row, col) = T_right;

        % Draw hexagon (avg temp for color)
        T_avg = mean([T_left, T_right]);
        fill(hex_x + xc, hex_y + yc, T_avg, 'EdgeColor', 'w');

        % Draw center line
        plot([xc xc], [yc - hex_height/2, yc + hex_height/2], 'w--', 'LineWidth', 1.2);

        % Label left and right temps
        text(xc - 0.03, yc, sprintf('%.1fK', T_left), 'HorizontalAlignment', 'right', 'FontSize', 8);
        text(xc + 0.03, yc, sprintf('%.1fK', T_right), 'HorizontalAlignment', 'left', 'FontSize', 8);
    end
end

colorbar;
caxis([min([T_left_all(:); T_right_all(:)]), max([T_left_all(:); T_right_all(:)])]);

%% Console Output
fprintf('--- %dx%d Hexagon Grid Temperature Report ---\n', num_rows, num_cols);
for col = 1:num_cols
    for row = 1:num_rows  
        fprintf('Hex (Row %d, Col %d) | Left: %.2f K | Right: %.2f K\n', ...
            row, col, T_left_all(row, col), T_right_all(row, col));
    end
end

