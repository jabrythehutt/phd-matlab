%Test impact of presence/absence of water vapour

prof = load('profile.mat');
prof=prof.profile;
setenv('LBL_HOME','/home/dj104/lblrtm/LBL_HOME');
zlevels = [linspace(0.8,12.0,15),linspace(12.5,25.0,10),linspace(26.0,60.0,5)]';

molsToTest = {'h2o','co2','o3','n2o','co','ch4'};

nlevels = length(zlevels);


pL = prof.alt;
profile.alt = zlevels;

dv = 0.1;
v1 = 100;
v2 = 1900;
angle = 180.0;
hObs = profile.alt(end);
endH = profile.alt(1);

profile.tdry = interp1(pL,prof.tdry,zlevels);
profile.pres = interp1(pL,prof.pres,zlevels);
profile.h2o = interp1(pL,prof.h2o,zlevels);
profile.co2 = interp1(pL,prof.co2,zlevels);



wn_range = [v1-25.0, v2+25.0];

%Default to MLS
atmflag = 2;
cleanup_flag = false;
args = cell(1);
args{1} = 'HBOUND';
args{2} = [hObs, endH,angle];
args{3} = 'FTSparams';
args{4} = [10.0, v1, v2, dv];

controlProf = profile;


[wnum, controlrad, controltrans] = ...
    simple_matlab_lblrun(cleanup_flag, atmflag, controlProf, wn_range, ...
    args{:});

tests = [];

%1 Test upwelling case



mol = 'h2o';
testProfile = profile;

for j = 1:length(molsToTest)
    
    mol2 = molsToTest{j};
    
    if ~strcmp(mol,mol2)
        
        testProfile =setfield(testProfile,mol2,zeros(size(profile.h2o)));
        
    end
    
end
disp(['Testing ',mol]);
[wnum, r, t] = ...
    simple_matlab_lblrun(cleanup_flag, atmflag, testProfile, wn_range, ...
    args{:});

tests =setfield(tests,mol,r);


save('results.mat');

plotTestGases({'h2o'},tests,controlrad,wnum,profile,1,true);



