clear 
close all 
clc 

%% Define Velocity Profile Based on Image Data
theta__breaks = [0 20 75 105 170 190 255 285 340 360];
theta_breaks = [180 190 255 285 340 360 20 75 105 170 180];
dTheta_diff = diff(theta_breaks);
theta = [];
for i = 1:length(theta_breaks)-1
    % Use finer resolution in high-velocity regions
    if (theta_breaks(i) >= 75 && theta_breaks(i) <= 105) || ...
       (theta_breaks(i) >= 255 && theta_breaks(i) <= 285)
        n_segments = max(3, ceil(dTheta_diff(i)/10)); % 10° resolution in high-vel
    else
        n_segments = max(2, ceil(dTheta_diff(i)/20)); % 20° resolution elsewhere
    end
    theta = [theta, linspace(theta_breaks(i), theta_breaks(i+1), n_segments+1)];
end
theta = unique(theta(1:end-1)); % Remove duplicates and 360° endpoint

% Calculate actual angle increments between slices
dTheta_actual = diff([theta, theta(1)+360]); % Wrap around for last segment 
% Define velocity profile using the new theta values
vel_profile = zeros(size(theta));

% High velocity regions (75-105° and 255-285°)
high_vel_angles = (theta >= 75 & theta <= 105) | (theta >= 255 & theta <= 285);
med_vel_angles = (theta > 20 & theta < 75) | (theta > 105 & theta < 170) | ...
                 (theta > 190 & theta < 255) | (theta > 285 & theta < 340);
low_vel_angles = (theta >= 0 & theta <= 20) | (theta >= 170 & theta <= 190) | ...
                (theta >= 340 & theta <= 360);

n_high_vel = sum(high_vel_angles);
n_med_vel = sum(med_vel_angles);
n_low_vel = sum(low_vel_angles);

vel_profile(high_vel_angles) = 0.8 + 0.2*rand(1, n_high_vel);
vel_profile(med_vel_angles) = 0.4 + 0.2*rand(1, n_med_vel);
vel_profile(low_vel_angles) = 0.1 + 0.2*rand(1, n_low_vel);

% Smooth the profile
vel_profile = smoothdata(vel_profile, 'gaussian', 3);

% Scale to actual velocities
v_max = 54.5;  % m/s
v0 = 0;     % m/s
v_el_prof = v0 + vel_profile * (v_max - v0);

%% Battery Thermal Simulation
Q_nom = 4.5;     % Ah
m_cell = 0.07;   % kg
C_b = 885;       % J/kg*K
R = 0.011;       % Ohm
s = 0.002;       % m
lambda = 17;     % W/m·K
k = 0.026;       % W/m·K

% Calculate mass for each slice using actual angle increments
n_slices = length(theta);
m = m_cell * (dTheta_actual / (2*pi)); % Vector of masses for each slice

% Current Input 
I = Q_nom * 8;
G_pure = (I^2 * R) / (2 * pi);  % W/rad

% Boundary Layer Parameters
rho = 1.225;    % kg/m³
mu = 1.7894e-5; % Pa·s
L = 2*0.09;     % m
alpha = 0;
beta = -0.2;
C_a = 0.37;

% Time Parameters
deltat = 0.1;     % s
tot_time = 60;    % s
time_steps = tot_time / deltat;

% Initialize temperatures
T = 308 * ones(1, n_slices);

% Ambient temperature
To = zeros(time_steps, n_slices);
To_init = 308; 
for t = 1:time_steps
    To_g = To_init + 0.1*(t * deltat);
    cool_eff = 5*(1 - v_el_prof / max(v_el_prof));
    To(t, :) = To_g - cool_eff;  
end

r = 0.009; % Cell radius

% Initialize temperature history
T_history = zeros(time_steps, n_slices);
T_history(1, :) = T;

for t = 1:time_steps
    Tnp = T;
    
    for n = 1:n_slices
        % Get adjacent indices with proper circular wrapping
        left_idx = mod(n-2, n_slices) + 1;  % Ensures 1 ≤ left_idx ≤ n_slices
        right_idx = mod(n, n_slices) + 1;   % Ensures 1 ≤ right_idx ≤ n_slices
        current_idx = n;                     % Current slice index
        
        % Thermal exchange with adjacent slices
        % Use current slice's dTheta for stability
        common_dTheta = dTheta_actual(current_idx);
        ets_left = 2*lambda*s*(Tnp(left_idx) - Tnp(current_idx)) / common_dTheta;
        ets_right = 2*lambda*s*(Tnp(right_idx) - Tnp(current_idx)) / common_dTheta;
        ets = ets_left + ets_right;
        
        % Thermal exchange with ambient
        current_v_el = v_el_prof(current_idx);
        current_Re = (rho * current_v_el * L)/ mu;
        current_WTheta = C_a * current_v_el^alpha * current_Re^beta;
        eto = k * r * (Tnp(current_idx) - To(t, current_idx)) / current_WTheta;
        
        % Update temperature
        T(current_idx) = Tnp(current_idx) + (deltat / (C_b * m(current_idx))) * ...
                         (G_pure*dTheta_actual(current_idx) - ets - eto);
    end
    
    T_history(t, :) = T;
    
    if mod(t, 10) == 0
        fprintf('Time: %.1f s | Avg Temp: %.2f K\n', t*deltat, mean(T));
    end
end

time_vector = 0:deltat:tot_time-deltat;

%% Plot Results
figure(1)
subplot(1,2,1)
polarplot(deg2rad(theta), v_el_prof, 'LineWidth', 2)
title('Angular Velocity Profile (m/s)')
thetalim([0 360])

subplot(1,2,2)
polarplot(deg2rad(theta), T_history(end,:), 'LineWidth', 2)
title('Final Temperature Distribution (K)')
thetalim([0 360])

figure(2)
[Time, Theta] = meshgrid(time_vector, theta); 
surf(Time, Theta, T_history')
xlabel('Time (s)')
ylabel('Angle (degrees)')
zlabel('Temperature (K)')
title('3D Temperature Evolution')
colorbar
shading interp
view(30, 45)




