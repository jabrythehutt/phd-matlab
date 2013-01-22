function [ val ] = extractValFromArgs( args,paramName )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

foundVal = false;

for i=1:length(args)
    
   
    currentArg = args{i};
    
    
    
    if  strcmpi(currentArg,paramName)&&length(args)>i 
        
        val = args{i+1};
        foundVal =true;
        
    end
    
    
end

if(~foundVal)
    error(['No value found for parameter:' paramName]);
end


end

