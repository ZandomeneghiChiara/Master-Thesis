clear   
close all 
clc 


%% Load CSV Data
filepath = 'prova54_3x8_HV_Cells_3mm-30deg(correct)_Velocities.csv';
data = readtable(filepath, 'Delimiter', ';', 'HeaderLines', 4);

% Extract and scale coordinates (m) and velocity (m/s)
x = str2double(string(data.('X_M_'))) / 1e9;
y = str2double(string(data.('Y_M_'))) / 1e9;
velocity = str2double(string(data.('Velocity_MS__1_'))) / 1e9;

% Check for NaNs or invalid data
if any(isnan(x)) || any(isnan(y)) || any(isnan(velocity))
    warning('Some values could not be converted to numbers. Removing invalid entries.');
end
valid = ~isnan(x) & ~isnan(y) & ~isnan(velocity) & isfinite(x) & isfinite(y) & isfinite(velocity);
x = x(valid);
y = y(valid);
velocity = velocity(valid);

% Check if data is empty after filtering
if isempty(x) || isempty(y) || isempty(velocity)
    error('No valid data points remain after filtering NaNs and non-finite values.');
end

% Rotate coordinates 90 degrees counterclockwise
x_rotated = -y;
y_rotated = x;

%% Define Zoomed-In Region
x_min = min(x_rotated);
x_max = max(x_rotated);
y_min = min(y_rotated);
y_max = max(y_rotated);
in_square = x_rotated >= x_min & x_rotated <= x_max & y_rotated >= y_min & y_rotated <= y_max;
x_square = x_rotated(in_square);
y_square = y_rotated(in_square);
v_square = velocity(in_square) / 1e1; % Additional scaling

% Check if square region is empty
if isempty(x_square) || isempty(y_square) || isempty(v_square)
    error('No data points in the zoomed-in region.');
end


%% First Plot: Velocity Distribution with Hexagonal Grid (No Interpolation)
figure('Position', [200, 200, 700, 700]);
scatter(x_square, y_square, 50, v_square, 'filled');
colormap(jet);
c = colorbar;
c.Label.String = 'Velocity [m/s]';

% Set caxis robustly
v_min = min(v_square);
v_max = max(v_square);
if v_min >= v_max || isnan(v_min) || isnan(v_max)
    v_mean = mean(v_square, 'omitnan');
    caxis([max(0, v_mean - 0.1), v_mean + 0.1]);
    warning('Invalid caxis range; using default range around mean.');
else
    caxis([v_min, v_max]);
end
hold on;

% Draw zoom box
plot([x_min, x_max, x_max, x_min, x_min], [y_min, y_min, y_max, y_max, y_min], ...
     'b-', 'LineWidth', 2);

% Add grid lines
x_grid = min(x_square)-0.05:0.01:max(x_square)+0.05;
y_grid = min(y_square)-0.05:0.01:max(y_square)+0.05;

% Axis labels and formatting
xlabel('X [m]');
ylabel('Y [m]');
title('Velocity Distribution with Hexagonal Grid (No Interpolation)');
axis equal;
xticks(linspace(x_min, x_max, 10));
yticks(linspace(y_min, y_max, 10));
xticklabels(arrayfun(@(v) sprintf('%.2f', v), xticks, 'UniformOutput', false));
yticklabels(arrayfun(@(v) sprintf('%.2f', v), yticks, 'UniformOutput', false));

% Hexagonal Grid (without interpolation)
hex_radius = 0.09 + 0.0255;
hex_height = sqrt(3) * hex_radius;
horizontal_spacing = 1.51 * hex_radius;
vertical_spacing = hex_height;
num_rows = 3; 
num_cols = 8; 
x_start = 0; 
y_start = 0.5; 
angles_rad = deg2rad(0:60:300);

x_centers = [];
for row = 0:num_rows-1
    for col = -1:num_cols
        % Compute hexagon center
        x_offset = x_start + col * horizontal_spacing;
        if mod(col, 2) == 1
            y_offset = y_start - row * vertical_spacing;
        else
            y_offset = y_start - row * vertical_spacing - hex_height/2;
        end

        xc = x_offset; 
        yc = y_offset; 
        
        if row == 0 
            x_centers(end+1) = xc; 
        end

        % Hexagon corners
        hex_x = xc + hex_radius * cos(angles_rad);
        hex_y = yc + hex_radius * sin(angles_rad);
        
        % Plot hexagons (ghost columns in gray, others in red)
        if col == -1 || col == num_cols
            plot([hex_x, hex_x(1)], [hex_y, hex_y(1)], 'Color', [0.6 0.6 0.6], 'LineWidth', 1);
        else
            plot([hex_x, hex_x(1)], [hex_y, hex_y(1)], 'r', 'LineWidth', 1.5);
        end
    end
end

% Draw vertical lines through hexagon centers
y_min_line = y_start - (num_rows + 0.5) * vertical_spacing;
y_max_line = y_start + vertical_spacing;

% for x_val = x_centers
%     plot([x_val, x_val], [y_min_line, y_max_line], '--', 'Color', [0.6 0.6 0.6]);
% end

% Display stats
stats_text = sprintf('Square Region Stats:\nX: [%.2f, %.2f] m\nY: [%.2f, %.2f] m\nMean Velocity: %.2f m/s\nMax Velocity: %.2f m/s', ...
                     x_min, x_max, y_min, y_max, mean(v_square, 'omitnan'), max(v_square));
annotation('textbox', [0.5, 0.15, 0.1, 0.1], 'String', stats_text, ...
           'BackgroundColor', 'white', 'FontSize', 9);

%% Second Plot: Interpolation of Velocity Components Along Hexagon Sides Only

% Velocity Components (for second plot)
try
    vx = str2double(string(data.('Velocities_x_MS__1_'))) / 1e9;
    vy = str2double(string(data.('Velocities_y_MS__1_'))) / 1e9;
    % Filter with the same valid mask
    vx = vx(valid);
    vy = vy(valid);
    % Check for valid velocity components
    if any(isnan(vx)) || any(isnan(vy)) || any(~isfinite(vx)) || any(~isfinite(vy))
        warning('NaN or non-finite values found in velocity components. Using fallback.');
        vx = zeros(size(velocity));
        vy = zeros(size(velocity));
        vx(in_square) = v_square;
        vy(in_square) = 0;
    end
catch
    warning('Velocity components (Velocities_x_MS__1_, Velocities_y_MS__1_) not found. Using placeholder: vx = v_square, vy = 0.');
    vx = zeros(size(velocity));
    vy = zeros(size(velocity));
    vx(in_square) = v_square;
    vy(in_square) = 0;
end


% Filter valid data for interpolation (second plot)
valid_interp = ~isnan(x_rotated) & ~isnan(y_rotated) & ~isnan(vx) & ~isnan(vy) & ...
               isfinite(x_rotated) & isfinite(y_rotated) & isfinite(vx) & isfinite(vy);
x_interp = x_rotated(valid_interp);
y_interp = y_rotated(valid_interp);
vx_interp = vx(valid_interp);
vy_interp = vy(valid_interp);

% Check if enough data for interpolation
if length(x_interp) < 3
    warning('Insufficient valid data points (%d) for interpolation. Skipping second plot.', length(x_interp));
    can_interpolate = false;
else
    can_interpolate = true;
    % Create scattered interpolants
    F_vx = scatteredInterpolant(x_interp, y_interp, vx_interp, 'linear', 'linear');
    F_vy = scatteredInterpolant(x_interp, y_interp, vy_interp, 'linear', 'linear');
end

if can_interpolate
    figure('Position', [200, 200, 700, 700]);
    hold on;

    % Arrays to store all scatter points for datacursor
    all_side_x = [];
    all_side_y = [];
    all_side_vx = [];
    all_side_vy = [];
    all_side_vmag = [];

    % Plot hexagon outlines and side points for real columns only
    for row = 0:num_rows-1
        for col = 0:num_cols-1
            x_offset = x_start + col * horizontal_spacing;
            y_offset = y_start - row * vertical_spacing - (mod(col, 2) == 1) * hex_height/2;
            xc = x_offset;
            yc = y_offset;

            % Hexagon corners
            hex_x = xc + hex_radius * cos(angles_rad);
            hex_y = yc + hex_radius * sin(angles_rad);
            plot([hex_x, hex_x(1)], [hex_y, hex_y(1)], 'r', 'LineWidth', 1.5);

            % Interpolate velocities at 10 points per hexagon side
            for k = 1:6
                p1 = [hex_x(k), hex_y(k)];
                p2 = [hex_x(mod(k,6)+1), hex_y(mod(k,6)+1)];

                % Generate 10 points along the side
                t = linspace(0, 1, 10);
                side_x = (1 - t) * p1(1) + t * p2(1);
                side_y = (1 - t) * p1(2) + t * p2(2);

                % Interpolate velocities at side points
                side_vx = F_vx(side_x, side_y);
                side_vy = F_vy(side_x, side_y);

                % Check for valid interpolation results
                side_vmag = sqrt(side_vx.^2 + side_vy.^2);
                if length(side_vmag) == length(side_x) && all(~isnan(side_vmag))
                    % Plot side points (colored by velocity magnitude)
                    scatter(side_x, side_y, 20, side_vmag, 'filled');
                    % Store points for datacursor
                    all_side_x = [all_side_x; side_x(:)];
                    all_side_y = [all_side_y; side_y(:)];
                    all_side_vx = [all_side_vx; side_vx(:)];
                    all_side_vy = [all_side_vy; side_vy(:)];
                    all_side_vmag = [all_side_vmag; side_vmag(:)];
                else
                    warning('Invalid velocity magnitude for row %d, col %d, side %d. Skipping scatter plot.', row, col, k);
                    continue;
                end
            end
        end
    end

    % Add colormap and colorbar
    colormap(jet);
    c = colorbar;
    c.Label.String = 'Velocity Magnitude [m/s]';
    if v_min >= v_max || isnan(v_min) || isnan(v_max)
        caxis([max(0, v_mean - 0.1), v_mean + 0.1]);
    else
        caxis([v_min, v_max]);
    end

    % Axis labels and formatting
    xlabel('X [m]');
    ylabel('Y [m]');
    title('Interpolated Velocity Components Along Hexagon Sides');
    axis equal;
    xticks(linspace(min(x_square)-0.05, max(x_square)+0.05, 10));
    yticks(linspace(min(y_square)-0.05, max(y_square)+0.05, 10));
    xticklabels(arrayfun(@(v) sprintf('%.2f', v), xticks, 'UniformOutput', false));
    yticklabels(arrayfun(@(v) sprintf('%.2f', v), yticks, 'UniformOutput', false));

    % Enable datacursor mode and set custom callback
    dcm_obj = datacursormode(gcf);
    set(dcm_obj, 'Enable', 'on', 'SnapToDataVertex', 'on');
    set(dcm_obj, 'UpdateFcn', @(obj, event) customDatatip(obj, event, all_side_x, all_side_y, all_side_vx, all_side_vy, all_side_vmag));

    hold off;
end

% Custom datatip callback function
function txt = customDatatip(~, event, x_coords, y_coords, vx_coords, vy_coords, vmag_coords)
    pos = event.Position;
    x = pos(1);
    y = pos(2);

    % Find the closest point
    distances = sqrt((x_coords - x).^2 + (y_coords - y).^2);
    [~, idx] = min(distances);

    % Get corresponding coordinates and velocities
    x_selected = x_coords(idx);
    y_selected = y_coords(idx);
    vx_selected = vx_coords(idx);
    vy_selected = vy_coords(idx);
    vmag_selected = vmag_coords(idx);

    % Create the datatip text
    txt = {sprintf('X: %.4f m', x_selected), sprintf('Y: %.4f m', y_selected), ...
           sprintf('Vx: %.4f m/s', vx_selected),  sprintf('Vy: %.4f m/s', vy_selected), ...
           sprintf('Vmag: %.4f m/s', vmag_selected)};
end



%%
%% Φ_{i,j} = ρ * Σ (v_x cosβ + v_y sinβ) ds   over hexagon (i,j)
rho = 1.22;                     % Air density [kg/m³]
pts_per_side = 10;

Phi = zeros(num_rows, num_cols);

for i = 1:num_rows
    row0 = i-1;
    for j = 1:num_cols
        col0 = j-1;
        x_offset = x_start + col0 * horizontal_spacing;
        y_offset = y_start - row0 * vertical_spacing - (mod(col0,2)==1) * hex_height/2;
        xc = x_offset; yc = y_offset;

        hex_x = xc + hex_radius * cos(angles_rad);
        hex_y = yc + hex_radius * sin(angles_rad);

        Phi_ij = 0;
        for k = 1:6
            p1 = [hex_x(k), hex_y(k)];
            p2 = [hex_x(mod(k,6)+1), hex_y(mod(k,6)+1)];
            t = linspace(0,1,pts_per_side);
            side_x = (1-t)*p1(1) + t*p2(1);
            side_y = (1-t)*p1(2) + t*p2(2);

            % Outward unit normal
            edge_vec   = p2 - p1;
            normal_vec = [-edge_vec(2); edge_vec(1)];
            n_len = norm(normal_vec);
            if n_len == 0, continue; end
            nx = normal_vec(1)/n_len; ny = normal_vec(2)/n_len;
            beta = atan2(ny, nx);

            % Interpolated velocity
            vx_side = F_vx(side_x, side_y);
            vy_side = F_vy(side_x, side_y);
            vn = vx_side .* cos(beta) + vy_side .* sin(beta);

            % Integrate: Σ (v·n) ds
            ds_interval = norm(edge_vec) * (t(2)-t(1));
            Phi_side = sum(vn) * ds_interval;
            Phi_ij = Phi_ij + Phi_side;
        end
        Phi(i,j) = rho * Phi_ij;
    end
end

%% Display Results
% FIXED: Avoid duplicate 'Row' name
[HexRow, HexCol] = ndgrid(1:num_rows, 1:num_cols);
PhiTable = table(HexRow(:), HexCol(:), Phi(:), ...
                 'VariableNames', {'HexRow', 'HexCol', 'Phi'});
fprintf('\n=== Φ_{i,j} (ρ = %.2f kg/m³) ===\n', rho);
disp(PhiTable);

% Plot flux per hexagon
figure('Position', [300, 300, 950, 600]); hold on; axis equal;
colormap(parula);

for i = 1:num_rows
    for j = 1:num_cols
        col0 = j-1; row0 = i-1;
        x_offset = x_start + col0*horizontal_spacing;
        y_offset = y_start - row0*vertical_spacing - (mod(col0,2)==1)*hex_height/2;
        xc = x_offset; yc = y_offset;
        hex_x = xc + hex_radius*cos(angles_rad);
        hex_y = yc + hex_radius*sin(angles_rad);
        fill([hex_x,hex_x(1)], [hex_y,hex_y(1)], Phi(i,j), 'EdgeColor','k','LineWidth',0.8);
    end
end

c = colorbar; c.Label.String = 'Φ_{i,j} [kg m s^{-1}]';
title('Flux Through Each Hexagon (Outward Normal)');
xlabel('X [m]'); ylabel('Y [m]');
xlim([x_min-0.05, x_max+0.05]); ylim([y_min-0.05, y_max+0.05]);

% Total flux
totalFlux = sum(Phi(:));
fprintf('\nΦ_{2,5} = %.6e kg·m/s\n', Phi(2,5));
fprintf('Total outward flux (3×8 grid) = %.6e kg·m/s\n', totalFlux);

% %% Custom Datatip Function
% function txt = customDatatip(~, event, x_coords, y_coords, vx_coords, vy_coords, vmag_coords)
%     pos = event.Position;
%     distances = sqrt((x_coords - pos(1)).^2 + (y_coords - pos(2)).^2);
%     [~, idx] = min(distances);
%     txt = {sprintf('X: %.4f m', x_coords(idx)), ...
%            sprintf('Y: %.4f m', y_coords(idx)), ...
%            sprintf('Vx: %.4f m/s', vx_coords(idx)), ...
%            sprintf('Vy: %.4f m/s', vy_coords(idx)), ...
%            sprintf('Vmag: %.4f m/s', vmag_coords(idx))};
% end

