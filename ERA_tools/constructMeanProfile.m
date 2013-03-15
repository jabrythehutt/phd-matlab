function [ prof,cov_prof,unit_map] = constructMeanProfile(lims)
%Use ERA-Interim and GISS data to construct a mean profile for use with
%LBLRTM. The temperature, RH and ozone profiles are taken from ERA-I while
%the others are taken from the monthly means in the GISS data


if ~exist('lims','var')
    
   lims = [-1.5,0.0;50.0,53.0;0,1000;datenum(2012,12,26),datenum(2012,12,28)];
   
    
end

lims2 = [-5.0,0.0;48.0,55.0;0,1000;0,lims(end)];

%Download ERA-I profiles for all points in space-time within lims
[prof1,cov_prof1,unit_map1]=downloadMeanProfile(lims);


%Extract profiles from GISS for all points in space-time within lims
[prof2,cov_prof2,unit_map2]=extractMeanProfile('/Users/djabry/Documents/PhD/Retrieval/Climate_data',...,
    3,lims2);


prof = prof2;
cov_prof = cov_prof2;
unit_map = unit_map2;

%Replace all fields in prof, cov_prof and unit_map with those in ERA-I prof
fNames = fieldnames(prof1);

for i =1:length(fNames)
   
    f = fNames{i};
    prof.(f)= prof1.(f);
    cov_prof.(f) = cov_prof1.(f);

end


%Need to change this to get a more accurate value of CO2;
prof.co2 = ones(size(prof.tdry))*390.0;



ukeys = keys(unit_map1);

for i =1:length(ukeys)
    
    k = ukeys{i};
    unit_map(k)= unit_map1(k);
end


end

