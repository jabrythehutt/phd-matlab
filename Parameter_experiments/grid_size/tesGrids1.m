
%Create a truth profile based on tropical 
setenv('LBL_HOME','/home/dj104/lblrtm/LBL_HOME');
mols = lower(molecules());
alt = (0:60)';
standardAtm = 1;

truthProf = calculateProfile( standardAtm, alt, mols );

truthProf.co2 = ones(size(truthProf.tdry)*390.0);

truthProf = interpolateProfile(truthProf,'pres',generateERALevs([0,1100]));

%Just try one iteration as a test
n=1;

startLims = [-1.5,0.0;-1.5,0.0;0,1000;datenum(2012,12,1),datenum(2012,12,2)];
limsStep = zeros(size(startLims));

wnRange = [100,200,0.1];

wn_grid = wnRange(1):wnRange(3):wnRange(2);

se = generateConstSE(wn_grid,250,0.3);

fileName = 'test.mat';

compareGrids(truthProf,startLims,limsStep,n,se, wnRange,lblArgs,fileName );