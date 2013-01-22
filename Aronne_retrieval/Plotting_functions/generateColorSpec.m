function [ colorSpec ] = generateColorSpec( ix, maxIx,cMap)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here


if ~exist('cMap','var')
   
    cMap = 'prism';
    
    if maxIx>6
        cMap = 'hsv';
    end
    
end


cmnd = [cMap,'(maxIx)'];

m = eval(cmnd);

colorSpec = m(ix,:);

if maxIx==1&&ix==1
    
    colorSpec = [0 0 0];
    
end


end

