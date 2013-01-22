molsToTest = false(1,29);
molsToTest(1)=true;
allMols = true(1,29);

%prof = load('profile.mat');
%prof=prof.profile;
%zlevels = [linspace(0.8,15.0,10),linspace(17.0,60.0,10)]';
%pL = prof.alt;
profile.alt = zlevels;
profile.tdry = interp1(pL,prof.tdry,zlevels);
profile.pres = interp1(pL,prof.pres,zlevels);
profile.h2o = interp1(pL,prof.h2o,zlevels);
profile.co2 = interp1(pL,prof.co2,zlevels);



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

atmToTest = [1,2,5];
anglesToTest = [0.0,180.0,0.0,180.0,0.0,180.0,0.0,180.0,0.0,180.0,0.0,180.0];
obsAlts = [0.0,6.0,6.0,7.0,7.0,8.0,8.0,10.0,10.0,16.0,16.0,profile.alt(end)];

sAlt = profile.alt(1);
eAlt = profile.alt(end);

allFileNames = cell(1,length(atmToTest)*length(obsAlts));

fileNamesByAlt = cell(length(anglesToTest),length(atmToTest));
upwellingFileNames = {};
downwellingFileNames = {};
ix=0;
for at = 1:length(atmToTest)
    atm = atmToTest(at);
    
    for j = 1:length(obsAlts)
        ix = ix+1;
        angle = anglesToTest(j);
        obsAlt =obsAlts(j);
        
        endAlt = eAlt;
        
        if angle==180.0
            endAlt = sAlt;
        end
        
        fileName = ['Contamination_atm-',num2str(atm),'_angle-',num2str(angle),'_alt-',num2str(obsAlt),'.mat'];
        allFileNames{ix}=fileName;
        fileNamesByAlt{j,at}=fileName;
        
        if angle ==0;
            downwellingFileNames = [downwellingFileNames,{fileName}];
            
        else
            
            upwellingFileNames = [upwellingFileNames,{fileName}];
        end
        
        
        
        if exist(fileName,'file')==0
            args = cell(1);
            args{1} = 'HBOUND';
            args{2} = [obsAlt,endAlt,angle];
            args{3} = 'TUNIT';
            args{4} = num2str(atm);
            
            disp(['Testing ',fileName]);
            testContamination(atm,molsToTest,allMols,args,profile,fileName);
            
        end
        
    end

    
end

noiseLevels = [0.5,0.4,0.3,0.2,0.1,0.05];
plotAndSaveRanges(allFileNames,{1,true,true,false,noiseLevels,true,true},'allContaminant');
plotAndSaveRanges(upwellingFileNames,{1,true,true,false,noiseLevels,true,true},'all_upwelling_contamination');
plotAndSaveRanges(downwellingFileNames,{1,true,true,false,noiseLevels,true,true},'all_downwelling_contamination');

maxLegStrings = cell(1,size(fileNamesByAlt,1));
upDataIx = false(size(maxLegStrings));
for ix = 1:size(fileNamesByAlt,1)
    altStr = [num2str(obsAlts(ix)),'km'];
    dirn = 'downwelling';
    
    
    if anglesToTest(ix)==180.0
        dirn = 'upwelling';
        upDataIx(ix)=true;
    end
    
    saveName = ['alt_',altStr,'_',dirn];
    [plh,xdata,data,legStrings]=plotAndSaveRanges(fileNamesByAlt(ix,:),{1,true,true,false,noiseLevels,true,true},saveName);
    
    if ~exist('maxData','var')
        
        maxData = cell(size(fileNamesByAlt,1));
    end
    
    dataIx = 0;
    
    for lIx = 1:length(legStrings)
        
        if isempty(strfind(legStrings{lIx},'+/-'))
            
            dataIx = lIx;
            
            
        end
        
    end

    maxData{ix} = data{dataIx};
    maxLegStrings{ix} = altStr;
    
    
end

xlims = [min(xdata),max(xdata)];
ylims = [1e-2,200];
xl = 'Wavenumber (cm^-^1)';
yl = 'Brightness temperature difference (K)';

noiseLines = cell(size(noiseLevels));
noiseLeg = cell(size(noiseLevels));
for nL = 1:length(noiseLevels)
    noiseLines{nL} = zeros(size(xdata))+noiseLevels(nL);
    noiseLeg{nL} = ['+/-',num2str(noiseLevels(nL)),'K'];
end



upDataMax = maxData(upDataIx);
downDataMax =maxData(~upDataIx);

upLeg = maxLegStrings(upDataIx);
downLeg = maxLegStrings(~upDataIx);

upDataMax = [noiseLines,upDataMax];
downDataMax = [noiseLines,downDataMax];

upLeg = [noiseLeg,upLeg];
downLeg = [noiseLeg,downLeg];

upClrSpec = cell(1, length(upLeg));
downClrSpec = cell(1,length(downLeg));

lineSpec = cell(size(upClrSpec));

noiseIx = 0;
lineIx = 0;

for o = 1:length(upClrSpec)
    
    if o <=length(noiseLeg)
        noiseIx = noiseIx+1;
        upClrSpec{o}=generateColorSpec(noiseIx,length(noiseLeg),'lines');
        downClrSpec{o}=upClrSpec{o};
        lineSpec{o} = '-';
        
    else
        
        lineIx = lineIx+1;
        upClrSpec{o}  = generateColorSpec(lineIx+1,1+length(upClrSpec)-length(noiseLeg));
        downClrSpec{o}  = generateColorSpec(lineIx,1+length(upClrSpec)-length(noiseLeg));
        lineSpec{o}=':';
        
    end
    
    
end



topList = zeros(1,length(noiseLevels)*2);
[hdn,plhsdn]=standardPlot(xdata,upDataMax,upLeg,'semilogy',xl,yl,xlims,ylims,lineSpec,upClrSpec);
[hup,plhsup]=standardPlot(xdata,downDataMax,downLeg,'semilogy',xl,yl,xlims,ylims,lineSpec,downClrSpec);

topList(1:length(noiseLevels))=plhsdn(1:length(noiseLevels));
topList(length(noiseLevels)+1:end) = plhsup(1:length(noiseLevels));

for i = 1:length(topList)
    uistack(topList(i),'top');
end



%testAbsorbers(2,molsToTest,allMols);