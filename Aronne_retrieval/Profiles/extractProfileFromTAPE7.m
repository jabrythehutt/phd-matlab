function [ profile] = extractProfileFromTAPE7( fileName )
%EXTRACTPROFILEFROMTAPE7 Summary of this function goes here
%   Detailed explanation goes here

profile = [];
layerData = read_tape7(fileName);

profile.tdry = [layerData.tlevel(:,1);layerData.tlevel(end,end)];
profile.pres  = [layerData.plevel(:,1);layerData.plevel(end,end)];
profile.alt = [layerData.zlevel(:,1);layerData.zlevel(end,end)];

layerMeanAlts = zeros(length(profile.alt)-1,1);

for i =1:length(layerMeanAlts)
    
    alt1 = profile.alt(i);
    alt2 = profile.alt(i+1);
    
    layerMeanAlts(i) = mean([alt1,alt2]);
end



allMols = lower(molecules());

for i = 1:layerData.nmol
    
    mol = allMols{i};
    molProf = interp1(layerMeanAlts,layerData.mol_vmr(:,i)*1e6,profile.alt,'linear','extrap');
    
    %Set any negative values to zero
    molProf(molProf<0.0)=0.0;
    profile = setfield(profile,mol,molProf);
    
end



end

