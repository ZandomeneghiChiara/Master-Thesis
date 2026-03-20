clear 
close all 
clc 

function [t, SOC, Iout, V0, R0] = BatterySOC(x4V0, y4V0, x4R0, y4R0)
    % BatterySOC - Simulates battery state of charge and current output
    % Inputs:
    %   x4V0, y4V0 - Voltage lookup table data
    %   x4R0, y4R0 - Resistance lookup table data
    % Outputs:
    %   t - Time vector (s)
    %   SOC - State of Charge array
    %   Iout - Current output array (A)
    %   V0 - Open-circuit voltage array (V)
    %   R0 - Internal resistance array (Ohms)

    % Parameters
    fs = 10; % Hz, sampling frequency
    Nseries = 144; % Battery pack series configuration
    Nparallel = 3; % Battery pack parallel configuration
    CellCapacity = 4.5; % Ah, cell capacity
    Pmean = 14000; % W, mean power demand
    Deltat = 1/fs; % Time step (s)
    t = 0:Deltat:1500; % Time vector (s)

    % Initialize arrays
    SOC = zeros(1, length(t));
    V0 = zeros(1, length(t));
    R0 = zeros(1, length(t));
    Iout = zeros(1, length(t));

    % Initial conditions (first timestep)
    SOC(1) = 1;
    V0(1) = interp1(x4V0, y4V0, SOC(1));
    Vpack = V0(1) * Nseries;
    R0(1) = interp1(x4R0, y4R0, SOC(1));
    Req = R0(1) * Nseries / Nparallel;
    Iout(1) = (-Vpack + sqrt(max(0, Vpack^2 - 4*Req*Pmean))) / (-2*Req);
    DeltaSOC = -Iout(1) * Deltat / (CellCapacity * Nparallel * 3600);

    % Main loop
    for i = 2:length(t)
        SOC(i) = SOC(i-1) + DeltaSOC; % Update SOC
        V0(i) = interp1(x4V0, y4V0, SOC(i)); % Update voltage
        Vpack = V0(i) * Nseries;
        R0(i) = interp1(x4R0, y4R0, SOC(i)); % Update resistance
        Req = R0(i) * Nseries / Nparallel; % Equivalent resistance
        Iout(i) = (-Vpack + sqrt(max(0, Vpack^2 - 4*Req*Pmean))) / (-2*Req); % Current output
        DeltaSOC = -Iout(i) * Deltat / (CellCapacity * Nparallel * 3600); % SOC variation
    end

    % Plot results
    figure;
    plot(t, SOC);
    xlabel('Time (s)');
    ylabel('State of Charge');
    title('Battery SOC vs Time');

    figure;
    plot(t, Iout);
    xlabel('Time (s)');
    ylabel('Current (A)');
    title('Current Output vs Time');
end

% Battery Thermal Model
% Molicel Battery Data 
Q_nom = 4.5;     % Ah | Nominal Capacity (4.5Ah 18650 cell)
m_cell = 0.07;   % kg | Cell Mass (typical 18650 weight)
C_b = 885;       % J/kg*K | Thermal Capacity of Battery (Lithium-ion battery average)
R = 0.011;       % Ohm | Internal Resistance (typical for 4.5Ah cell)
s = 0.002;       % m | Height of Battery Cell Slice (2mm slice of 65mm cell)
dTheta = 20;     % ° | Angle increment for slice (18 slices for full circle)

% Slice Thermal Properties
lambda = 17;                    % W/m·K | Thermal conductivity of Steel casing
k = 0.026;                      % W/m·K | Thermal conductivity of Air at 300K
m = m_cell * (dTheta / (2*pi)); % kg | Mass of the slice (~0.002kg)

% Boundary Layer Width Calculation 
rho = 1.225;                    % kg/m³ | Air density at sea level, 20°C
v_av0 = 0;                      % m/s | Initial Air velocity
v_max = 54.5;                   % m/s | Max Air velocity to 54.5 m/s 
v_av = (v_max - v_av0) / 2;     % m/s | Average Air velocity
mu = 1.7894e-5;                 % Pa·s | Dynamic viscosity of air at 20°C
L = 2*0.09;                     % m | Characteristic length (twice cell diameter)
Re = (rho * v_av * L) / mu;     % Reynolds number (dimensionless) 
% Turbulent Coefficients
alpha = 0;                      % Empirical coefficient for boundary layer 
beta = -0.4;                    % Empirical coefficient for boundary layer  
C_a = 0.37;                     % Empirical coefficient for turbulent flow
WTheta = C_a * v_av^alpha * Re^beta; % m | Boundary Layer Width 

% Temperature Calculation - Time Stepping 
deltat = 0.1;                   % s | Time step (0.1 seconds)
tot_time = 60;                  % s | Total simulation time (60 seconds) 
time_steps = tot_time / deltat; % Number of time steps 

% Initialize temperatures for all slices (in Kelvin) 
n_slices = 360 / dTheta;      % Number of Slices (18 for 20° increments)
theta = linspace(0, 360, n_slices);
T = 308 * ones(1, n_slices);  % K | Initial temperature: 308 K (35°C) for all slices

peak_angle = 138;
v_el_prof = v_av * exp(-0.5*((theta - peak_angle) / 30).^2);

To = zeros(time_steps, n_slices);
To_init = 308; 

for t = 1:time_steps
    To_g = To_init + 0.5*(t * deltat);         % Temperature growth
    cool_eff = 5*(1 - v_el_prof / max(v_el_prof)); % Cooling effect
    To(t, :) = To_g - cool_eff;  
end 

r = 0.009;                    % m | Cell radius (9 mm)

T_history = zeros(time_steps, n_slices);
T_history(1, :) = T;

% Load battery data and compute current (assuming BatterySOC function is available)
[x4V0, y4V0, x4R0, y4R0] = loadBatteryData(); % Placeholder: assumes data is loaded
[t_battery, SOC, Iout, V0, R0] = BatterySOC(x4V0, y4V0, x4R0, y4R0);

% Interpolate Iout to match thermal model time steps
time_battery = t_battery;
time_thermal = 0:deltat:tot_time-deltat;
Iout_interp = interp1(time_battery, Iout, time_thermal, 'linear', 'extrap');

% Temperature in a Cell
for t = 1:time_steps
    Tnp = T;     % New Temperature based on previous
    I = Iout_interp(t); % Current at current time step
    G = (I^2 * R) * (dTheta / (2*pi)); % W | Heat generation in slice

    % For Each Slice: 
    for n = 1:n_slices
        % Thermal exchange with ambient air (using time and angle-dependent To)
        current_v_el = v_el_prof(n); % velocity at this angle
        current_WTheta = C_a * current_v_el^alpha * Re^beta; % Update BL width
        eto = k * r * (Tnp(n) - To(t, n)) / current_WTheta;

        % Calculate new temperature in slice n
        T(n) = Tnp(n) + ((deltat * 2 * pi) / (C_b * m)) * (G - eto);
    end 

    T_history(t, :) = T;

    % Print progress every 10 steps
    if mod(t, 10) == 0
        fprintf('Time: %.1f s | Avg Temp: %.2f K\n', t * deltat, mean(T));
    end
end

time_vector = 0:deltat:tot_time-deltat;

% Plot 1: Final Temperature Distribution (Polar Plot)
figure(3) 
subplot(1,2,1)
polarplot(deg2rad(theta), T_history(end,:), '-o', 'LineWidth', 2, 'MarkerSize', 8)
title('Final Temperature Distribution (K)', 'FontSize', 14)
thetalim([0 360])
rlim([300 330]) % Set appropriate limits for Kelvin scale
set(gca, 'FontSize', 12) 

% Plot 1,2,2: Temperature Evolution Over Time for All Slices
subplot(1,2,2)
plot(time_vector, T_history)
xlabel('Time (s)', 'FontSize', 12)
ylabel('Temperature (K)', 'FontSize', 12)
title('Temperature Evolution for All Slices', 'FontSize', 14)
grid on
legend(cellstr(num2str(theta', '%.0f°')), 'Location', 'eastoutside')

% Plot 2: 3D Surface Plot of Temperature vs Angle vs Time
figure(4)
[Time, Theta] = meshgrid(time_vector, theta);
surf(Time, Theta, T_history')
xlabel('Time (s)', 'FontSize', 12)
ylabel('Angle (degrees)', 'FontSize', 12)
zlabel('Temperature (K)', 'FontSize', 12)
title('3D Temperature Distribution', 'FontSize', 14)
colorbar
shading interp
view(30, 45)

% Placeholder function to load battery data
function [x4V0, y4V0, x4R0, y4R0] = loadBatteryData()
    % Replace with actual data loading (e.g., load('InterpData.mat'))
    % For now, return dummy data to allow code to run
    x4V0 = linspace(0, 1, 100); % SOC from 0 to 1
    y4V0 = linspace(3.0, 4.2, 100); % Voltage from 3.0V to 4.2V
    x4R0 = linspace(0, 1, 100); % SOC from 0 to 1
    y4R0 = linspace(0.01, 0.02, 100); % Resistance from 10mOhm to 20mOhm
end
