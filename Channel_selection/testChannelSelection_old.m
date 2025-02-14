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
        
        
        fNameIx = fNameIx+1;
        allFileNames{fNameIx} = fileName;
        
        if dirns(obsIx)
            
            upwellingFileNames = [upwellingFileNames,{fileName}];
            upwellingMap(obsAlt)=fileName;
        else
            downwellingFileNames = [downwellingFileNames,{fileName}];
            downwellingMap(obsAlt)=fileName;
            
        end
        
        tropAlt = atmTrop(atm);
        
        if ((obsAlt > tropAlt) && dirns(obsIx))||((obsAlt<tropAlt)&&~dirns(obsIx))
            fileNameMap(obsAlt)=fileName;
            
        end
        
        if ~exist(fileName,'file');
            
            [w,k] = simple_matlab_AJ_lblrun(cleanup_flag,atm,prof,vbound,lblArgs{:});
            
            result =[];
            result.profile = prof;
            result.wn = w;
            result.k = k;
            result.args = lblArgs;
            save(fileName,'result');
            
        end
        
        
        
        if ~exist(radFileName,'file')
            
            disp(['Calculating radiance for',radFileName]);
            
            %Remove Jacobian related args
            lblArgs(5:6)=[];
            
            
            %Simulate radiance
            [wn,rad] = simple_matlab_lblrun(cleanup_flag,atm,prof,vbound,lblArgs{:});
            cd(currentDir);
            
            %Calculate a profile where the altitude grid is consistent with
            %the output
            
            altGrid = prof.alt;
            
            if(angle ==180)
                newAltGrid = altGrid((altGrid>=endAlt)&(altGrid<=obsAlt));
            else
                newAltGrid = altGrid((altGrid>=obsAlt)&(altGrid<=endAlt));
            end
            
            prof = interpolateProfile(prof,'alt',newAltGrid);
            
            
            result = load(fileName);
            result = result.result;
            
            
            
            
            
            k = result.k;
            
            %Set regions affected by rounding error to 0
            k(k>1|k<-1)=0;
            corr_length = 2.0;
            wvvar = 0.5;
            
            wvap_var_val =(log(1.0+wvvar)).^2;
            
            wvap_var = linspace(wvap_var_val,wvap_var_val,length(prof.alt));
            wvap_Sa = synthetic_Sa(prof.alt, corr_length, wvap_var);
            
            
            
            
            
            result =[];
            result.profile = prof;
            result.wn = wn;
            result.rad = rad;
            result.args = lblArgs;
            result.k=k;
            result.se=syntheticSE(wn,'ln');
            result.sa = wvap_Sa;
            
            save(radFileName,'result');
            
        end
        
        
        result = load(radFileName);
        result = result.result;
        
        %if ~isfield(result,'lowNoise')
        
        if true

            %Correct possible errors in wavenumber gird
            diff = length(result.k)-length(result.wn);
            if diff>0
                
                dv  = result.wn(end)-result.wn(end-1);
                for i = 1:diff 
                    result.wn = [result.wn;result.wn(end)+dv];
                end

            end
            
            if diff<0
                
                result.wn(end-diff+1:end)=[];
            end
 
            wn = result.wn;
            
            
            
            %Find atmosphere from fileName;
            strLst = regexp(fileName,'-','split');
            atmStr = regexp(strLst{2},'_','split');
            atm = str2num(atmStr{1});
            atmName = atmNames{atm};
            %lineStyles{i} = ':';
            
            
            %Find location of tropopause
            %tropAlt = findTropopause(prof);
            zlevels = result.profile.alt;
            
            tropAlt = atmTrop(atm);
            utlimit = tropAlt-utdepth;
            utIx = (zlevels>=utlimit)&(zlevels<=tropAlt);
            
            
            
            
            
            
            %If the upper troposphere is not observed
            if ((obsAlt < tropAlt) && dirns(obsIx))||...,
                    ((obsAlt>tropAlt)&&~dirns(obsIx))
                
                
                
                
            else
                 %Find UT Jacobian and associated covariance matrices
                    utIx = (zlevels>=utlimit)&(zlevels<=tropAlt);
                    k = result.k(:,utIx);
                    sa = result.sa(utIx,utIx);
                
                
                for nix = 1:2
                    
                    nType = 'ln';
                    if nix ==2
                        
                        nType = 'hn';
                    end
                    
                    csel = [];
                    csel.se = syntheticSE(wn,nType);
                    se = csel.se;
                
                
                    CS = ICMicroWindowSelector(k,se,sa,0.9,3);
                
                    csel.selectedChannels = CS.selectChannels();
                    csel.channelSelector = CS;
                    
                    if nix ==1
                        
                        result.lowNoise = csel;
                        
                    else
                        
                        result.highNoise = csel;
                        
                    end
                end
                
                if isfield(result,'selectedChannels')
                    
                    result = rmfield(result,'selectedChannels');
                    
                end
                
                if isfield(result,'channelSelector')
                    result = rmfield(result,'channelSelector');
                    
                end
                
                if isfield(result,'se')
                    result = rmfield(result,'se');
                    
                end
                
                
                save(radFileName,'result');
                
                
            end
            
            
            
            
        end
        
        
    end
    
    fileNamesByAtm{1,atmIx} = upwellingMap;
    fileNamesByAtm{2,atmIx}=downwellingMap;
    combinedFileNamesByAtm{atmIx} = fileNameMap;
    
end

%Find best UT response




%Generate combined Jacobian plots for upwelling and downwelling
maxVal = 0;
for atmIx = 1:length(atmToTest)
    
    m = combinedFileNamesByAtm{atmIx};
    
    keySet = keys(m);
    lWn = 0;
    
    meanResp = cell(size(keySet));
    wn = cell(size(keySet));
    
    alts = zeros(size(keySet));
    for i = 1:length(keySet)
        
        k = keySet{i};
        fileName = m(k);
        
        result = load(fileName);
        result = result.result;
        
        prof = result.profile;
        %Need radiance at observer in order to convert Jacobian to
        %BT so for now leaving units as dR/dln(MR)
        
        k = result.k;
        
        %Find altitude levels since input profile may does not specify
        %levels used
        hbound = result.args{8};
        obsAlt = hbound(1);
        endAlt = hbound(2);
        levIx = prof.alt<=max(obsAlt,endAlt)&prof.alt>=min(obsAlt,endAlt);
        zlevels = prof.alt(levIx);
        alts(i)=obsAlt;
        
        %Generate legend string detailing observer altitude relative to
        %ground and tropopause.
        
        %Find atmosphere from fileName;
        strLst = regexp(fileName,'-','split');
        atmStr = regexp(strLst{2},'_','split');
        atm = str2num(atmStr{1});
        atmName = atmNames{atm};
        %lineStyles{i} = ':';
        
        
        %Find location of tropopause
        %tropAlt = findTropopause(prof);
        
        tropAlt = atmTrop(atm);
        
        utlimit = tropAlt-utdepth;
        
        %legStr{i} = [atmName,' ',num2str(obsAlt),'km (',num2str(obsAlt-tropAlt),'km)'];
        wn{i} = result.wn;
        lWn = max(length(wn{i}),lWn);
        
        if lWn>length(wn{i})||~exist('wnAx','var')
            
            wnAx = wn{i};
            
        end
        
        
        
        %Find mean response in the upper-troposphere (perhaps interpolate
        %to common grid first?)
        utIx = zlevels>=utlimit&zlevels<=tropAlt;
        ktest = k(:,utIx)*1e4;
        meanResp{i} = mean(abs(ktest),2);
        maxVal = max(meanResp{i});
        relIx(i)=true;
        
        
    end
    
    
    arr = zeros(length(meanResp),lWn);
    
    for i =1:length(meanResp)
        subArr = meanResp{i};
        arr(i,1:length(subArr))=subArr(:);
        
    end
    
    
    
    prArgs = cell(1,2);
    prArgs{1}='plot_params';
    prArgs{2}={'tdry','h2o'};
    
    plotProfile(prof,prArgs);
    
    
    
    figure;
    pcolor(wnAx,alts,arr);
    xlabel('Wavenumber (cm^-^1)','fontsize',12);
    ylabel('Observer altitude (km)','fontsize',12);
    line([min(wnAx) max(wnAx)], [tropAlt tropAlt],'Color','g','LineStyle','--','LineWidth',1);
    line([min(wnAx) max(wnAx)], [tropAlt-utdepth tropAlt-utdepth],'Color','g','LineStyle','--','LineWidth',1);
    ylim([0 20]);
    %caxis([0 maxVal]);
    colorbar;
    
    title([atmName,' Mean UT Jacobian (W/[m^2 cm^-^1 sr ln(MR)])'],'fontsize',13);
    shading interp;
    
    
end


%Generate upwelling and downwelling Jacobian plots
for j = 1:2
    
    for atmIx = 1:length(atmToTest)
        
        m = fileNamesByAtm{j,atmIx};
        
        keySet = keys(m);
        lWn = 0;
        
        meanResp = cell(size(keySet));
        wn = cell(size(keySet));
        
        alts = zeros(size(keySet));
        for i = 1:length(keySet)
            
            k = keySet{i};
            fileName = m(k);
            
            result = load(fileName);
            result = result.result;
            
            prof = result.profile;
            %Need radiance at observer in order to convert Jacobian to
            %BT so for now leaving units as dR/dln(MR)
            
            k = result.k;
            
            %Find altitude levels since input profile does not specify
            %levels used
            hbound = result.args{8};
            obsAlt = hbound(1);
            endAlt = hbound(2);
            levIx = prof.alt<=max(obsAlt,endAlt)&prof.alt>=min(obsAlt,endAlt);
            zlevels = prof.alt(levIx);
            alts(i)=obsAlt;
            
            %Generate legend string detailing observer altitude relative to
            %ground and tropopause.
            
            %Find atmosphere from fileName;
            strLst = regexp(fileName,'-','split');
            atmStr = regexp(strLst{2},'_','split');
            atm = str2num(atmStr{1});
            atmName = atmNames{atm};
            %lineStyles{i} = ':';
            
            
            %Find location of tropopause
            %tropAlt = findTropopause(prof);
            
            tropAlt = atmTrop(atm);
            
            utlimit = tropAlt-utdepth;
            
            %legStr{i} = [atmName,' ',num2str(obsAlt),'km (',num2str(obsAlt-tropAlt),'km)'];
            wn{i} = result.wn;
            lWn = max(length(wn{i}),lWn);
            
            if lWn>length(wn{i})||~exist('wnAx','var')
                
                wnAx = wn{i};
                
            end
            
            
            %If the upper troposphere is not observed
            if ((obsAlt < tropAlt) && j==1)||((obsAlt>tropAlt)&&j==2)
                
                meanResp{i} = zeros(size(result.wn));
                
                
            else
                
                %Find mean response in the upper-troposphere (perhaps interpolate
                %to common grid first?)
                utIx = zlevels>=utlimit&zlevels<=tropAlt;
                ktest = k(:,utIx);
                meanResp{i} = mean(abs(ktest),2);
                relIx(i)=true;
                
            end
            
        end
        
        
        arr = zeros(length(meanResp),lWn);
        
        for i =1:length(meanResp)
            subArr = meanResp{i};
            arr(i,1:length(subArr))=subArr(:);
            
        end
        
        %         figure;
        %         pcolor(wnAx,alts,arr);
        %         xlabel('Wavenumber (cm^-^1)','fontsize',12);
        %         ylabel('Observer altitude (km)','fontsize',12);
        %         colorbar;
        %         dirnStr = 'upwelling';
        %         if j==2
        %             dirnStr = 'downwelling';
        %         end
        %         title([atmName,' ',dirnStr,' Mean UT Jacobian'],'fontsize',13);
        %         shading interp;
        
        
    end
    
    
end


for j = 1:2
    
    fileList = downwellingFileNames;
    
    if j==1
        
        fileList = upwellingFileNames;
    end
    
    meanResp = cell(size(fileList));
    lineStyles = cell(size(fileList));
    clrs = cell(size(fileList));
    wn = cell(size(fileList));
    legStr = cell(size(fileList));
    
    %Index indicating plots where UT is visible
    relIx = false(size(fileList));
    
    for i = 1:length(fileList)
        
        fileName = fileList{i};
        result = load(fileName);
        result = result.result;
        
        prof = result.profile;
        %Need radiance at observer in order to convert Jacobian to
        %BT so for now leaving units as dR/dln(MR)
        
        k = result.k;
        
        %Find altitude levels since input profile may does not specify
        %levels used
        hbound = result.args{8};
        obsAlt = hbound(1);
        endAlt = hbound(2);
        levIx = prof.alt<=max(obsAlt,endAlt)&prof.alt>=min(obsAlt,endAlt);
        zlevels = prof.alt(levIx);
        
        %Generate legend string detailing observer altitude relative to
        %ground and tropopause.
        
        %Find atmosphere from fileName;
        strLst = regexp(fileName,'-','split');
        atmStr = regexp(strLst{2},'_','split');
        atm = str2num(atmStr{1});
        atmName = atmNames{atm};
        lineStyles{i} = ':';
        
        
        %Find location of tropopause
        %tropAlt = findTropopause(prof);
        
        tropAlt = atmTrop(atm);
        
        utlimit = tropAlt-utdepth;
        
        legStr{i} = [atmName,' ',num2str(obsAlt),'km (',num2str(obsAlt-tropAlt),'km)'];
        
        wn{i} = result.wn;
        
        
        %If the upper troposphere is not observed
        if ((obsAlt < tropAlt) && j==1)||((obsAlt>tropAlt)&&j==2)
            
            meanResp{i} = zeros(size(result.wn));
            
        else
            
            %Find mean response in the upper-troposphere (perhaps interpolate
            %to common grid first?)
            utIx = zlevels>=utlimit&zlevels<=tropAlt;
            ktest = k(:,utIx);
            meanResp{i} = mean(abs(ktest),2);
            relIx(i)=true;
            
        end
        
    end
    
    for i = 1:length(meanResp(relIx))
        clrs{i} = generateColorSpec(i,length(fileList(relIx)));
        
    end
    
    
    xaxlims = [min(result.wn),max(result.wn)];
    yaxlims = [];
    
    standardPlot(wn(relIx),meanResp(relIx),legStr(relIx),'plot',...
        'Wavenumber (cm^-^1)','dR/dln(MR)',...
        xaxlims,yaxlims,lineStyles,clrs);
    
end









