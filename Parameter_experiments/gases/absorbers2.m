
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

atmToTest = [1,2,5];
anglesToTest = [0.0,180.0,0.0,180.0,0.0,180.0,0.0,180.0,0.0,180.0];
obsAlts = [0.0,6.0,6.0,8.0,8.0,10.0,10.0,16.0,16.0,profile.alt(end)];

sAlt = profile.alt(1);
eAlt = profile.alt(end);

allFileNames = cell(1,length(atmToTest)*length(obsAlts));

fileNamesByAltUpwelling = cell(length(find(anglesToTest)),length(atmToTest));
fileNamesByAltDownwelling = cell(length(anglesToTest)-size(fileNamesByAltUpwelling,1),length(atmToTest));

upwellingFileNames = {};
downwellingFileNames = {};


ix=0;
for at = 1:length(atmToTest)
    atm = atmToTest(at);
    dnIx = 0;
    upIx = 0;
    
    for j = 1:length(obsAlts)
        ix = ix+1;
        angle = anglesToTest(j);
        obsAlt =obsAlts(j);
        
        endAlt = eAlt;
        
        if angle==180.0
            endAlt = sAlt;
        end
        
        fileName = ['atm-',num2str(atm),'_angle-',num2str(angle),'_alt-',num2str(obsAlt),'.mat'];
        allFileNames{ix}=fileName;
        
        if angle==0.0 
            dnIx = dnIx+1;
            fileNamesByAltDownwelling{dnIx,at}=fileName;
            downwellingFileNames = [downwellingFileNames,{fileName}];
        else
            upIx = upIx+1;
            fileNamesByAltUpwelling{dnIx,at}=fileName;
            upwellingFileNames = [upwellingFileNames,{fileName}];
            
        end
        
        
        if ~exist(fileName,'file')
            args = cell(1);
            args{1} = 'HBOUND';
            args{2} = [obsAlt,endAlt,angle];
            args{3} = 'TUNIT';
            args{4} = num2str(atm);
            
            disp(['Testing ',fileName]);
            
            testAbsorbers(atm,molsToTest,allMols,args,profile,fileName);
            
        end
        
    end

end

noiseLevels = [0.5,0.4,0.3,0.2,0.1,0.05];

a = false(1,29);
b = a;
b(1:6)=true;

c=a;
c(7:15)=true;

d = a;
d(16:29)=true;

e=a;
e(1:end)=true;

molRanges = {b,c,d};

for i = 1:length(molRanges)
    
    molRange = molRanges{i};
    fgroup = ['upwelling_absorbers_group_',num2str(i)];
    plotAndSaveRanges(upwellingFileNames,{1,true,true,false,noiseLevels,false,true},fgroup,molRange);
    fgroup = ['downwelling_absorbers_group_',num2str(i)];
    plotAndSaveRanges(downwellingFileNames,{1,true,true,false,noiseLevels,false,true},fgroup,molRange);
    

%     for j=1:max([size(fileNamesByAltUpwelling,1),size(fileNamesByAltUpwelling,1)])
%         
%         if j<=size(fileNamesByAltUpwelling,1)
%             
%             fNames = fileNamesByAltUpwelling(j,:);
%             fgroup = ['upwelling_absorbers_group_',num2str(i)];
%             plotAndSaveRanges(fNames,{1,true,true,false,noiseLevels,false,true},fgroup,molRange);
%         end
%         
%         if j<=size(fileNamesByAltDownwelling,1)
%             
%             fNames = fileNamesByAltDownwelling(j,:);
%             fgroup = ['downwelling_absorbers_group_',num2str(i)];
%             plotAndSaveRanges(fNames,{1,true,true,false,noiseLevels,false,true},fgroup,molRange);
%         end
%     end
    
    
end


plotAndSaveRanges(downwellingFileNames,{1,true,true,false,noiseLevels,false,true},'downwelling_absorbers_1-29',e);
plotAndSaveRanges(upwellingFileNames,{1,true,true,false,noiseLevels,false,true},'upwelling_absorbers_1-29',e);
plotAndSaveRanges(allFileNames,{1,true,true,false,noiseLevels,false,true},'absorbers_1-29',e);


% 
% maxLegStrings = cell(1,size(fileNamesByAlt,1));
% upDataIx = false(size(maxLegStrings));
% for ix = 1:size(fileNamesByAlt,1)
%     altStr = [num2str(obsAlts(ix)),'km'];
%     dirn = 'downwelling';
%     
%     
%     if anglesToTest(ix)==180.0
%         dirn = 'upwelling';
%         upDataIx(ix)=true;
%     end
%     
%     saveName = ['alt_',altStr,'_',dirn];
%     [plh,xdata,data,legStrings]=plotAndSaveRanges(fileNamesByAlt(ix,:),{1,true,true,false,[0.5,0.4,0.3,0.2,0.1,0.05],true,true},saveName);
%     
%     if ~exist('maxData','var')
%         
%         maxData = cell(size(fileNamesByAlt,1));
%     end
%     
%     dataIx = 0;
%     
%     for lIx = 1:length(legStrings)
%         
%         if ~isempty(strfind(lower(legStrings{lIx}),'max'))
%             
%             dataIx = lIx;
%             
%             
%         end
%         
%     end
% 
%     maxData{ix} = data{dataIx};
%     maxLegStrings{ix} = altStr;
%     
%     
% end
% 
% xlims = [min(xdata),max(xdata)];
% ylims = [1e-2,200];
% xl = 'Wavenumber (cm^-^1)';
% yl = 'Brightness temperature difference (K)';
% 
% noiseLines = cell(size(noiseLevels));
% noiseLeg = cell(size(noiseLevels));
% for nL = 1:length(noiseLevels)
%     noiseLines{nL} = zeros(size(xdata))+noiseLevels(nL);
%     noiseLeg{nL} = [num2str(noiseLevels(nL)),'K'];
% end
% 
% 
% 
% upDataMax = maxData(upDataIx);
% downDataMax =maxData(~upDataIx);
% 
% upLeg = maxLegStrings(upDataIx);
% downLeg = maxLegStrings(~upDataIx);
% 
% upDataMax = [noiseLines,upDataMax];
% downDataMax = [noiseLines,downDataMax];
% 
% upLeg = [noiseLeg,upLeg];
% downLeg = [noiseLeg,downLeg];
% 
% topList = zeros(1,length(noiseLevels)*2);
% [hdn,plhsdn]=standardPlot(xdata,upDataMax,upLeg,'semilogy',xl,yl,xlims,ylims);
% [hup,plhsup]=standardPlot(xdata,downDataMax,downLeg,'semilogy',xl,yl,xlims,ylims);
% 
% topList(1:length(noiseLevels))=plhsdn(1:length(noiseLevels));
% topList(length(noiseLevels)+1:end) = plhsup(1:length(noiseLevels));
% 
% for i = 1:length(topList)
%     uistack(topList(i),'top');
% end
% 


%testAbsorbers(2,molsToTest,allMols);