function [ profile ] = interpolateProfile( profileIn,var,grid )

%Interpolates a profile to a grid according to a variable

allVars = {'alt','pres','tdry'};
allVars = [allVars,lower(molecules)];

profile = [];
profile.(var)=grid;
xvec = profileIn.(var);


for i = 1:length(allVars)
    
    v = allVars{i};
    
    if (~strcmp(v,var)) && isfield(profileIn,v)
        
        vec = profileIn.(v);
        ivec = interp1(xvec(:),vec(:),grid(:),'linear','extrap')';
        
        ivec(ivec<0.0)=0.0;
        profile.(v)=ivec';
       
        
    end
    
    
end


end

