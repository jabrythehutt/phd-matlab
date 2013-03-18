
%Create a truth profile based on tropical 
setenv('LBL_HOME','/home/dj104/lblrtm/LBL_HOME');
mols = true(size(lower(molecules(1:20))));
alt = (0:60)';
standardAtm = 1;

truthProf = calculateProfile( standardAtm, alt, mols);

%Convert to h2o from ppmv to g/kg

truthProf.h2o = truthProf.h2o*(18.0153/28.966)*1.0e-3;

truthProf.co2 = ones(size(truthProf.tdry))*390.0;

truthProf = interpolateProfile(truthProf,'pres',generateERALevs([0,1100]));

%Just try one iteration as a test
n=1;

startLims = [-1.5,0.0;-1.5,0.0;0,1000;datenum(2012,12,1),datenum(2012,12,2)];
limsStep = zeros(size(startLims));

dv = 0.1;
startWn = 800;
endWn = 1500;

wnRange = [startWn,endWn];

obsAlt = 60.0;
endAlt = 0.0;
angle = 180.0;

molUnits = char('A'*ones(1,length(mols)));
molUnits(1)= 'C';

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

se = generateConstSE(wn_grid,250,1.0);


fileName = 'test.mat';

compareGrids(truthProf,startLims,limsStep,n,se, wnRange,lblArgs,fileName );