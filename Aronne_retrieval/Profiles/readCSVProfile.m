function [profile ] = readCSVProfile( fileName )
%READCSVPROFILE Summary of this function goes here
%   Detailed explanation goes here


profData = csvread(fileName);


profile = [];

profile.alt=  profData(:,1);
profile.pres = profData(:,2);
profile.tdry  = profData(:,3);


allMols = lower(molecules());
molIx = 0;
for i = 4:size(profData,2)
    
    molIx = molIx+1;
    mol = allMols{molIx};
    profile = setfield(profile,mol,profData(:,i));
end
    
    
    


end

