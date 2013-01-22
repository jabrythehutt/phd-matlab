function [ R ] = tToR( T,v )

h = 6.626068e-34; %Planck's constant (J-s)
c = 2.99792458e8;  %speed of light (m/s)
k = 8.314/6.022e23; %Boltzmann's constant (J/K)

alpha1 = 2*h*c^2;
alpha2 = h*c/k;

R=alpha1*v.^3./(exp(alpha2*v./T)-1);
%R=R*1e-4

end

