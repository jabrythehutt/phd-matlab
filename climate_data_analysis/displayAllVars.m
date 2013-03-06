function [ vars ] = displayAllVars( filePath )
%DISPLAYALLVARS Summary of this function goes here
%   Detailed explanation goes here

info = ncinfo(filePath);

vars = cell(size(info.Variables));
for i=1:length(info.Variables)
    
    
    vars{i}=info.Variables(i).Name;
    disp(vars{i});
end


end

