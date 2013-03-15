function [ lblrtmMolUnits,punit,tunit ] = convertUnitsMap( uMap )
%Convert a map of molecule names and their associated LBLRTM unit strings
%to a string compatible with LBLRTM
allMols = lower(molecules());
lblrtmMolUnits = char('A'*ones(size(allMols)));

tunit = 'A';
punit = 'A';

selMols = keys(uMap);
for i =1:length(selMos)
    m = selMols{i};
    
    
    if strcmp(m,'tdry')
        tunit = uMap(m);
    elseif strcmp(m,'pres')
        punit = uMap(m);
    else
        
        ix = STRCMPI(m,allMols);
        lblrtmMolUnits(ix)=uMap(m);
        
    end 
    
end

end

