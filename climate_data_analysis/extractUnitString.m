function [ unitString ] = extractUnitString( dataPath,v )
%Find the unit string for the variable v 

%Go through selected data path
lst = dir(dataPath);
lstLim = length(lst);
i=1;
unitString = '';

while strcmp(unitString,'')&&i<=lstLim;
    
    fle = lst(i);
    
    %If it is netcdf file
    if(strendswith(fle.name,'.nc'))
        
        flePath  = [dataPath,filesep,fle.name];
        fInfo = ncinfo(flePath);
        
        %If there are 3 dimensions specified
        if(length(fInfo.Dimensions)==3)
            vInfo = ncinfo(flePath,v);
            unitString = vInfo.Attributes(1).Value;
            
        end
        
    end
    i=i+1;
    
end


end

