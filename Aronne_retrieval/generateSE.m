function [ se ] = generateSE( obs,wn,varT )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

t1 = rToBT(1.0e2*obs,1.0e2*wn)+varT;
r1 = tToR(t1,1.0e2*wn)/1.0e2;

diff = r1-obs;

se = sparse(diag(diff.*diff));

end

