function [ molStrings ] = molecules(indices)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here



molecules = {'H2O','CO2','O3','N2O','CO','CH4','O2','NO','SO2','NO2','NH3',...
    'HNO3','OH','HF','HCL','HBR','HI','CLO','OCS','H2CO','HOCL','N2','HCN',...
    'CH3CL','H2O2','C2H2','C2H6','PH3','COF2','SF6','H2S','HCOOH','HO2',...
    'O','CLONO2','NOPLUS','HOBR','C2H4','CH3OH'};


ix = false(size(molecules));


if exist('indices','var')==0
    indices = true(size(molecules));
end


if islogical(indices)
    
     ix(1:length(indices))=indices(:);
end


if isnumeric(indices)
    
    for i = 1:length(indices)
        
        currIx = indices(i);
        
        if(currIx<=length(molecules))
            
            ix(currIx)=true;
            
        end 
        
        
    end
    
end



molStrings = molecules(ix);


end

