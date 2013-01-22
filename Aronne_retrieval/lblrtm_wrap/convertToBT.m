function [ BT ] = convertToBT(rad,wn)
%CONVERTTOBT Summary of this function goes here
%   Detailed explanation goes here


BT = rToBT(rad*100.0,wn*100.0);


end

