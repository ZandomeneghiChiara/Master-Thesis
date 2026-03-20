function [Tcell,Tair] = MyFuncLastCol(G,Kprev1,Kprev2,Kprev3,K,K2,Tprev1,Tprev2,Tprev3,T0,AirMass,t)

    Deltat = t(2) - t(1);
    m = 0.07; %kg
    Cp = 885; %J/kgK

    T(1) = Tprev2(1);
    Tcell(1) = Tprev2(1);
    Tair(1) = Tprev2(1);

    for i = 2:length(t)
        Eout_air = Kprev1*Deltat*(Tprev1(i) - T0) + Kprev2*Deltat*(Tprev2(i) - T0) + Kprev3*Deltat*(Tprev3(i) - T0);
        Tair(i) = Tair(i-1) + Eout_air/AirMass;
        Ein = G(i)*Deltat;
        Eout = K*Deltat*(T(i-1) - Tair(i)) + K2*Deltat*(T(i-1) - Tprev3(i-1));
        DeltaT = (Ein - Eout)/(m*Cp);
        T(i) = T(i-1) + DeltaT;
        Tcell(i) = T(i);
    end
end

