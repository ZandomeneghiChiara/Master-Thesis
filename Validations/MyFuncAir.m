function [Tcell] = MyFuncAir(G,Tnext,Kprev1,Kprev2,K,K2,Tprev1,Tprev2,T0,FitParamsAir,t)

    AirMass = FitParamsAir;

    Deltat = t(2) - t(1);
    m = 0.07; %kg
    Cp = 885; %J/kgK

    T(1) = Tprev2(1);
    Tcell(1) = Tprev2(1);
    Tair(1) = Tprev2(1);

    for i = 2:length(t)
        Eout_air = Kprev1*Deltat*(Tprev1(i) - T0) + Kprev2*Deltat*(Tprev2(i) - T0);
        Tair(i) = Tair(i-1) + Eout_air/AirMass;

        Ein = G(i)*Deltat + K2*Deltat*(Tnext(i-1) - T(i-1));
        Eout = K*Deltat*(T(i-1) - Tair(i)) + K2*Deltat*(T(i-1) - Tprev2(i-1));
        DeltaT = (Ein - Eout)/(m*Cp);
        T(i) = T(i-1) + DeltaT;
        Tcell(i) = T(i);
    end
end

