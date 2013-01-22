%Test impact of presence/absence of gases

prof = load('profile.mat');
prof=prof.profile;
setenv('LBL_HOME','/home/dj104/lblrtm/LBL_HOME');
%zlevels = [linspace(0.8,12.0,15),linspace(12.5,25.0,10),linspace(26.0,60.0,5)]';
%zlevels = linspace(0.8,60.0,15)';
zlevels = [linspace(0.8,15.0,10),linspace(17.0,60.0,10)]';



molsToTest = true(1,29);
molecules = {'H2O','CO2','O3','N2O','CO','CH4','O2','NO','SO2','NO2','NH3',...
    'HNO3','OH','HF','HCL','HBR','HI','CLO','OCS','H2CO','HOCL','N2','HCN',...
    'CH3CL','H2O2','C2H2','C2H6','PH3','COF2','SF6','H2S','HCOOH','HO2',...
    'O','CLONO2','NOPLUS','HOBR','C2H4','CH3OH'};

nlevels = length(zlevels);


pL = prof.alt;
profile.alt = zlevels;

dv = 0.1;
v1 = 100.0;
v2 = 1900.0;
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
cleanup_flag = true;
args = cell(1);
args{1} = 'HBOUND';
args{2} = [hObs, endH,angle];
args{3} = 'FTSparams';
args{4} = [dv, v1, v2];
args{5} = 'MOLECULES';
args{6}=  molsToTest;

controlProf = profile;

[wnum, controlrad, controltrans] = ...
    simple_matlab_lblrun(cleanup_flag, atmflag, controlProf, wn_range, ...
    args{:});

tests = [];

%1 Test upwelling case
molIndices = find(molsToTest);

for i = 1:length(molIndices)
    molTestConfig = molsToTest;
    
    molIndex = molIndices(i);
    
    molName = lower(molecules{molIndex});
    testProfile = profile;
    
    %Remove from profile;
    molTestConfig(molIndex)=false;
    args{6}=molTestConfig;
    %testProfile = setfield(testProfile,molName,zeros(size(profile.alt)));

    disp(['Testing ',molName]);
    [wnum, r, t] = ...
    simple_matlab_lblrun(cleanup_flag, atmflag, testProfile, wn_range, ...
    args{:});

    tests =setfield(tests,molName,r);

end

save('results2.mat');

plotTestGases(lower(molecules(molsToTest)),tests,controlrad,wnum,profile,1,true);




