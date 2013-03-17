function [se ] = generateConstSE( wn,bT,varT )
%Generate instrument covariance based on a blackbody 


bT = ones(size(wn))*bT;

obs = tToR(bT,1.0e2*wn)/1.0e2;


se = generateSE(obs,wn,varT);




end

