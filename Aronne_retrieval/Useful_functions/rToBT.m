function [bt] = rToBT(R,v)
%R=R*1e4;

pl = 6.626068e-34; %Planck's constant (J-s)
c = 2.99792458e8;  %speed of light (m/s)
k = 8.314/6.022e23; %Boltzmann's constant (J/K)

alpha1 = 2*pl*c^2;
alpha2 = pl*c/k;

bt = alpha2*v(:)./log(1+(alpha1*v(:).^3./R(:)));

if ~all(size(bt)==size(R))
    bt = bt';
end

end

