function Tcell = MyFunc(G,Tnext,FitParams,t,Tair)

    K = FitParams(1);
    K2 = FitParams(2);

    Deltat = t(2) - t(1);
    m = 0.07; %kg
    Cp = 885; %J/kgK

    T(1) = Tair;
    Tcell(1) = Tair;

    for i = 2:length(t)
        Ein = G(i)*Deltat + K2*Deltat*(Tnext(i-1) - T(i-1));
        Eout = K*Deltat*(T(i-1) - Tair);
        DeltaT = (Ein - Eout)/(m*Cp);
        T(i) = T(i-1) + DeltaT;
        Tcell(i) = T(i);
    end
end

