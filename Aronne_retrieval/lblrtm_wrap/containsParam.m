function [ tf ] = containsParam( args, paramName )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

tf = false;

for i=1:length(args)
    
   
    currentArg = args{i};
    
    if strcmpi(currentArg,paramName)&&(length(args)>i)
        
        
        tf =true;
        
    end
    
    
end

end

