function [ tropAlt ] = findTropopause( prof)

tfun = @(x)interp1(prof.alt,prof.tdry,x);

[tropAlt,fval]=fminbnd(tfun,5.0,15.3);



end

