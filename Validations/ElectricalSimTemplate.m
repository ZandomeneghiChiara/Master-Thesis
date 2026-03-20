clear
clc
close all

load('InterpData.mat')% load x4V0,y4V0,x4R0,y4R0

fs = 10; %Hz, used the same sampling frequency as the temperature measurement for simplicity
Nseries = 144; %battery pack config
Nparallel = 3; %battery pack config
CellCapacity = 4.5; %Ah

Deltat = 1/fs;

t = 0:Deltat:1500; % endurance last about 1500s

Pmean = 14000; %W -> computed from FSG 2025 efficency scoreboard

%initialization (first timestep)
SOC(1) = 1;
V0(1) = interp1(x4V0,y4V0,SOC(1));
Vpack = V0(1)*Nseries;
R0(1) = interp1(x4R0,y4R0,SOC(1));
Req = R0(1)*Nseries/Nparallel;
Iout(1) = (-Vpack + sqrt(max(0,Vpack^2 - 4*Req*Pmean)))/(-2*Req); 
DeltaSOC = -Iout(1)*Deltat/(CellCapacity*Nparallel*3600);


for i = 2:length(t)
    SOC(i) = SOC(i-1) + DeltaSOC; %update the soc
    V0(i) = interp1(x4V0,y4V0,SOC(i)); %update the voltage with the new soc
    Vpack = V0(i)*Nseries;
    R0(i) = interp1(x4R0,y4R0,SOC(i)); %update the resistance with the new soc -> will be used later in thermal model
    Req = R0(i)*Nseries/Nparallel; % equivalent resistance of battery pack, needed to compute battery pack voltage drop
    Iout(i) = (-Vpack + sqrt(max(0,Vpack^2 - 4*Req*Pmean)))/(-2*Req); %current output to satisfy power request (P = I*V + voltage drop on Req)
    DeltaSOC = -Iout(i)*Deltat/(CellCapacity*Nparallel*3600); %compute the soc variation (how much charge goes out)
end

figure
plot(t,SOC)

figure
plot(t,Iout)

