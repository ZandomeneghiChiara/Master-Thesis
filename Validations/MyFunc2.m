function [Tcell] = MyFunc2(G,Tnext,Tprev,Tair,K2,FitParams2,t)

    K = FitParams2;

    Deltat = t(2) - t(1);
    m = 0.07; %kg
    Cp = 885; %J/kgK

    T(1) = Tprev(1);
    Tcell(1) = Tprev(1);

    for i = 2:length(t)
        Ein = G(i)*Deltat + K2*Deltat*(Tnext(i-1) - T(i-1));
        Eout = K*Deltat*(T(i-1) - Tair) + K2*Deltat*(T(i-1) - Tprev(i-1));
        DeltaT = (Ein - Eout)/(m*Cp);
        T(i) = T(i-1) + DeltaT;
        Tcell(i) = T(i);
    end
end

