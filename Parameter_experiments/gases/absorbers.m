molsToTest = true(1,29);
allMols = true(1,29);

prof = load('profile.mat');
prof=prof.profile;
zlevels = [linspace(0.8,15.0,10),linspace(17.0,60.0,10)]';
pL = prof.alt;
profile.alt = zlevels;
profile.tdry = interp1(pL,prof.tdry,zlevels);
profile.pres = interp1(pL,prof.pres,zlevels);
profile.h2o = interp1(pL,prof.h2o,zlevels);
profile.co2 = interp1(pL,prof.co2,zlevels);


atmToTest = [2,5];
anglesToTest = [180.0,0.0,0.0];
obsAlts = [profile.alt(end),8.0,16.0];


endAlts = [profile.alt(1),profile.alt(end),profile.alt(end)];

for at = 1:length(atmToTest)
    atm = atmToTest(at);
    for j = 1:length(obsAlts)
 
        angle = anglesToTest(j);
        obsAlt =obsAlts(j);
        endAlt = endAlts(j);
        
        fileName = ['atm-',num2str(atm),'_angle-',num2str(angle),'_alt-',num2str(obsAlt),'.mat'];
        args = cell(1);
        args{1} = 'HBOUND';
        args{2} = [obsAlt,endAlt,angle];
        args{3} = 'TUNIT';
        args{4} = num2str(atm);

        disp(['Testing ',fileName]);
        testAbsorbers(atm,molsToTest,allMols,args,profile,fileName);
        
    end
    
end


%testAbsorbers(2,molsToTest,allMols);