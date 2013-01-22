function [data ] = testAbsorbers(atmflag,molsToTest,allMols,lblArgs,prof,fileName )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

%Test impact of presence/absence of gases

%Default to tropical atmosphere;
if exist('atmflag','var')==0
    atmflag = 1;
    
end 

if exist('fileName','var')==0
    fileName = ['Results_',datestr(now,'dd-mm-yy_HH-MM-SS'),'.mat'];
end

if exist('allMols','var')==0
    allMols = true(size(molecules()));
end

if exist('molsToTest','var')==0
    
    molsToTest = allMols;
    
end


if exist('prof','var')==0
    prof = load('profile.mat');
    prof=prof.profile;
    zlevels = [linspace(0.8,15.0,10),linspace(17.0,60.0,10)]';
    pL = prof.alt;
    profile.alt = zlevels;
    profile.tdry = interp1(pL,prof.tdry,zlevels);
    profile.pres = interp1(pL,prof.pres,zlevels);
    profile.h2o = interp1(pL,prof.h2o,zlevels);
    profile.co2 = interp1(pL,prof.co2,zlevels);
    
else
    
    profile = prof;
    
end

data = [];


v1 = 100.0;
v2 = 1900.0;
dv=0.1;
angle = 180.0;
wn_range = [v1-25.0, v2+25.0];
hObs = profile.alt(end);
endH = profile.alt(1);


defaultArgs = cell(1);
defaultArgs{1} = 'HBOUND';
defaultArgs{2} = [hObs, endH,angle];
defaultArgs{3} = 'FTSparams';
defaultArgs{4} = [dv, v1, v2];
defaultArgs{5} = 'MOLECULES';
defaultArgs{6}=  allMols;

if exist('lblArgs','var')==0
    
    lblArgs = cell(1);
    
end

args = defaultArgs;


for i = 1:2:length(lblArgs)-1
    
    
    if length(lblArgs)>i
        currArg = lblArgs{i};
        foundIx = strcmpi(currArg,args(1:2:length(args)-1));
        curArgVal = lblArgs{i+1};
        
        if isempty(find(foundIx,1))
            
            %Add to argument list
            args{length(args)+1}=currArg;
            args{length(args)+1}=curArgVal;

            
        else
            %Replace existing argument value
            ix = find(foundIx,1);
            args{ix+1}=curArgVal;
            
            
        end
    end
    
end

setenv('LBL_HOME','/home/dj104/lblrtm/LBL_HOME');

cleanup_flag = true;
controlProf = profile;

[wnum, controlrad, controltrans] = ...
    simple_matlab_lblrun(cleanup_flag, atmflag, controlProf, wn_range, ...
    args{:});

tests = [];
tests.profile = controlProf;
tests.controlrad = controlrad;
tests.wn = wnum;
tests.atmflag = atmflag;
tests.args = args;


%1 Test upwelling case
molIndices = find(molsToTest);

for i = 1:length(molIndices)
    molTestConfig = molsToTest;
    molIndex = molIndices(i);
    
    molName = lower(molecules(molIndex));
    molName = molName{1};
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

save(fileName,'tests');
%plotTestGases(lower(molecules(molsToTest)),tests,controlrad,wnum,profile,1,true);







end

