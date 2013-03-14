function [ prof,cov_prof,unit_map ] = downloadMeanProfile( lims,hres )

if ~exist('hres','var')
    
    hres = [0.75,0.75];
end 

%Variable map
vMap =  containers.Map();
vMap('Specific_humidity') = 'h2o';
vMap('Temperature')='tdry';
vMap('Ozone_mass_mixing_ratio') = 'o3';
vMap('isobaric') = 'pres';

unit_map = containers.Map();
unit_map('h2o') = 'C';
unit_map('tdry') = 'A';
unit_map('o3') = 'C';
unit_map('pres') = 'A';

convMap = containers.Map();
%No conversion required for these variables
convMap('Specific_humidity')=1000.0;
convMap('Temperature')=1.0;
convMap('isobaric') = 1.0;

%Convert from kg/kg to g/kg
convMap('Ozone_mass_mixing_ratio')=1000.0;


prof = [];
cov_prof= [];



%First download data
f =  downloadProfileData(lims,hres);


varsToRead = keys(vMap);

for i =1:length(varsToRead)
    
    v = varsToRead{i};

    %arr should be a 4d array with dimensions [lon lat press time]
    arr = double(ncread(f,v));
    
    if ~strcmpi(v,'isobaric')
        
        %Reshape to a 2d array with dimensions [obs pres] where obs is number
        %of observations of the variable profile
        dims = size(arr);
        obsDims = dims;
        obsDims(3)=[];
        numRows = prod(obsDims);
        numCols = dims(3);
        
        
        %First permute array so that last dimension is the one of interest
        arr= permute(arr,[1,2,4,3]);
        
        arr = reshape(arr,[numRows,numCols]);
        %Convert array to lblrtm units
        arr = arr*convMap(v);

        covProf = cov(arr);
        cov_prof = setfield(cov_prof,vMap(v),covProf);
        meanProf = reshape(mean(arr),[size(arr,2),1]);
        prof = setfield(prof,vMap(v),meanProf);
        
        
    else
        
        %Don't process pressure profile, just attach directly to cov_prof
        %and prof
        
        arr = reshape(arr,[numel(arr),1]);
        prof = setfield(prof,vMap(v),arr);
        cov_prof = setfield(cov_prof,vMap(v),arr);
        
        
    end

    
end



end

