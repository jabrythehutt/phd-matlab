%Test channel selection
setenv('LBL_HOME','/home/dj104/lblrtm/LBL_HOME');
currentDir = pwd;

allMols = true(1,29);
atmToTest = [1,2,5];
angles = [0.0,180.0,0.0,180.0,0.0,180.0,0.0,180.0,0.0...
    ,180.0,0.0,180.0,0.0,180.0,0.0,180.0,0.0,...
    180.0,0.0,180.0,0.0,180.0,0.0,180.0,0.0,180.0,0.0,180.0,0.0,180.0,...
    0.0,180.0,0.0,180.0,0.0,180.0,0.0,180.0];
zlevels = [linspace(0,16,17),linspace(17,60,19)]';
obsAlts = [zlevels(1),3.0,3.0,4.0,4.0,5.0,5.0,6.0,6.0,...
    7.0,7.0,8.0,8.0,9.0,9.0,10.0,10.0,...
    11.0,11.0,12.0,12.0,13.0,13.0,14.0,14.0,15.0,15.0,...
    16.0,16.0,17.0,17.0,18.0,18.0,19.0,19.0,20.0,20.0,zlevels(end)];
dirns = angles==180.0;
cleanup_flag = true;

atmTrop = zeros(1,5);
atmNames = cell(1,5);
atmNames{1} = 'Trop';
atmTrop(1) = 15.7;

atmNames{2} = 'MLS';
atmTrop(2) = 12.93;

atmNames{5} = 'SAW';
atmTrop(5) = 8.95;

startWn = 100;
endWn =1900;
dv = 0.1;
vbound = [startWn,endWn];



allFileNames =  cell(1,length(atmToTest)*length(obsAlts));
downwellingFileNames = {};
upwellingFileNames = {};
%This defines the upper-tropospheric depth to test
utdepth = 3;
fNameIx = 0;

fileNamesByAtm = cell(2,3);
combinedFileNamesByAtm = cell(1,3);

%Calculate Jacobians for all configurations (if the calculations have not
%already been performed)


for atmIx = 1:length(atmToTest)
    
    
    
    %2 maps: 1 for up and the other for downwelling
    upwellingMap = containers.Map('KeyType','double','ValueType','char');
    downwellingMap = containers.Map('KeyType','double','ValueType','char');
    
    fileNameMap = containers.Map('KeyType','double','ValueType','char');
    
    atm = atmToTest(atmIx);
    profIn = calculateProfile(atm,zlevels,allMols);
    
    for obsIx =  1:length(obsAlts)
        
        prof= profIn;
        
        
        
        lblArgs = {};
        lblArgs{1} = 'MOLECULES';
        lblArgs{2} = allMols;
        lblArgs{3} = 'FTSPARAMS';
        lblArgs{4} = [dv,startWn,endWn];
        lblArgs{5} = 'CalcJacobian';
        lblArgs{6} = 1;
        lblArgs{7} = 'HBOUND';
        obsAlt = obsAlts(obsIx);
        endAlt = prof.alt(1);
        
        if ~dirns(obsIx);
            endAlt = prof.alt(end);
            
        end
        angle = angles(obsIx);
        lblArgs{8} = [obsAlt,endAlt,angle];
        
        fileName = ['atm-',num2str(atm),'_angle-',num2str(angle),'_alt-',num2str(obsAlt),'.mat'];
        
        radFileName =  ['atm-',num2str(atm),'_angle-',num2str(angle),'_alt-',num2str(obsAlt),'_cs.mat'];
        
        
        result1 = load(fileName);
        result2 = load(radFileName);
        
        result2.result.k = result1.result.k;
        result2.result.wn = result1.result.wn;
        
        save(radFileName,'result2.result');
        
        
    end 
end
