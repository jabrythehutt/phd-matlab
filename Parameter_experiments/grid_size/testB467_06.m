
%Create a truth profile based on tropical 
setenv('LBL_HOME','/home/dj104/lblrtm/LBL_HOME');
mols = true(size(lower(molecules(1:20))));
allMols= lower(molecules());

truthProf = load('/home/dj104/Retrieval/Profiles/B467_r06_PDG_profile.mat');
truthProf = truthProf.profile;

truthProf = interpolateProfile(truthProf,'pres',generateERALevs([0,1100]));

%Just try one iteration as a test
n=1;

%startLims = [49.0,51.0;-6.0,-4.5;0,1000;datenum(2009,07,19),datenum(2009,07,19)];
startLims  = [45.0,55.0;-10.0,-1.0;0,1000;datenum(2009,05,31),datenum(2009,09,01)];
limsStep = zeros(size(startLims));

%Get remaining molecular profiles from ERA/other data
[ meanProf,cov_prof] = constructMeanProfile(startLims);
mlsProf = calculateProfile(2,(0:60)',mols);

mlsProf = interpolateProfile(mlsProf,'pres',truthProf.pres);
meanProf = interpolateProfile(meanProf,'pres',truthProf.pres);

for i =1:length(mols)
    mol = allMols{i};
   
    
    if isfield(truthProf,mol)
        
        
    else
        
        
        if isfield(meanProf,mol)
            
            truthProf.(mol)=meanProf.(mol);
            
        else
            
            truthProf.(mol)=mlsProf.(mol);
            
        end
        
        
    end
    
    
end


dv = 0.1;
startWn = 100;
endWn = 600;

wnRange = [startWn,endWn];

obsAlt = 60.0;
endAlt = 0.0;
angle = 180.0;

molUnits = char('A'*ones(1,length(mols)));
%molUnits(1)= 'C';

hbnd = [obsAlt,endAlt,angle];

lblArgs = {};
lblArgs{1} = 'MOLECULES';
lblArgs{2} = mols;
lblArgs{3} = 'FTSPARAMS';
lblArgs{4} = [dv,startWn,endWn];
lblArgs{5} = 'HBOUND';
lblArgs{6} = hbnd;
lblArgs{7} = 'MOLUNITS';
lblArgs{8} = molUnits;


wn_grid = startWn:dv:endWn-dv;

%se = generateConstSE(wn_grid,250,1.0);
se = 1.0;

fileName = 'test.mat';

compareGrids(truthProf,startLims,limsStep,n,se, wnRange,lblArgs,fileName );