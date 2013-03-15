function [ outArgs,info ] = cache( functionName, varargin )
%Use this function to cache results from functions that require a long time
%to run. The results are stored in files with the same name as the function

info = [];

if cacheContains(functionName,varargin)
    
    
else
    
    try
        
        
        
        
        
    catch err
        
        
        outputArgs = err;
        %Catch exceptions and cache these too
        
    end
    
end


%Then save these to the appropriate file and return the results



end

