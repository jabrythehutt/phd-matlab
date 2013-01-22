function [ h,xdata,ydata,legStr,molData ] = plotTestGases(gases,alltests,controls,wns,profiles,plotType,btopt,logopt,tempCurvesOpt, noiseTemps,sigOnly,absflag)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
j=0;


if isempty(gases)
    
    gases = cell(1);
    allMols = molecules();
    
    for i = 1:length(allMols)
        molName = lower(allMols{i});
        
        if isfield(tests,molName)
            j=j+1;
            gases{j}=molName;
            
        end
        
    end
    
    
    
end

if exist('absflag','var')==0
    absflag=false;
end

if exist('sigOnly','var')==0
    sigOnly = false;
    
end

if exist('btopt','var')==0
    btopt = false;
    
end

if exist('logopt','var')==0
    logopt=false;
    
end

if exist('plotType','var')==0
    
    plotType =0;
    
end

if exist('tempCurvesOpt','var')==0
    
    tempCurvesOpt = false;
    
end

if exist('noiseTemps','var')==0
    
    noiseTemps =[];
    
end

if ~iscell(alltests)
    
    alltests = {alltests};
    
end

if ~iscell(wns)
    
    wns = {wns};
end


if ~iscell(controls)
    
    controls = {controls};
    
end


if ~iscell(profiles)
    profiles = {profiles};
end

allDiffs = cell(size(profiles));
fullwn = wns{1};
maxLim = 200;

for k = 1:length(profiles)
    
    profile = profiles{k};
    control = controls{k};
    wn = wns{k};
    
    if length(wn)>length(fullwn)
        fullwn = wn;
    end
    tests= alltests{k};
    maxT = max(profile.tdry);
    minT = min(profile.tdry);
    minTCurve = tToR(minT,wn*100)*1e-2;
    maxTCurve = tToR(maxT,wn*100)*1e-2;
    noiseCurves = zeros(length(control),length(noiseTemps));
    
    if btopt
        
        control =  rToBT(control*100.0,wn*100.0);
        minTCurve = zeros(size(control))+minT;
        maxTCurve = zeros(size(control))+maxT;
        
    end
    
    diffs = zeros(length(wn),length(gases)+3+length(noiseTemps));
    
    legStr = cell(1,length(gases)+3);
    vec = control;
    vec2 = minTCurve;
    vec3=maxTCurve;
    if plotType==1
        
        vec = zeros(size(control));
        vec2 = minTCurve-control;
        vec3 = maxTCurve-control;
        
        
    end
    
    
    diffs(:,1)=vec;
    legStr{1}='Control';
    
    diffs(:,2)=vec2;
    legStr{2}=['+/-',num2str(minT),'K'];
    
    diffs(:,3)=vec3;
    legStr{3}=['+/-',num2str(maxT),'K'];
    
    if ~isempty(noiseTemps)
        
        for nc = 1:length(noiseTemps)
            
            nT = noiseTemps(nc);
            legStr{nc+3}=['+/-',num2str(nT),'K'];
            if(btopt)
                
                diffs(:,nc+3)=control+nT;
                
            else
                
                diffs(:,nc+3)=tToR(rToBT(control*100.0,wn*100.0)+nT,wn*100.0);
                
            end
            
            if plotType==1
                
                diffs(:,nc+3)=diffs(:,nc+3)-control;
                
            end
            
            noiseCurves(:,nc)=diffs(:,nc+3);
            
        end
        
    end
    
    
    for i = 1:length(gases)
        
        mol = lower(gases{i});
        testRad = getfield(tests,mol);
        
        errLength = length(control)-length(testRad);
        
        if(errLength~=0)
            disp(['Spectrum vector for ',mol,' is different length to control, padding ', num2str(errLength),' elements']);
            for l = 1:abs(errLength)
                
                if errLength<0
                    %Expand wavenumber grid, diffs and control to meet
                    %length
                    control = [control;control(end)];
                    diffs = [diffs;diffs(end,:)];
                    dv = wn(2)-wn(1);
                    wn = [wn;wn(end)+dv];
                    noiseCurves=[noiseCurves;noiseCurves(end,:)];
                    
                    
                else
                    endVal = testRad(end);
                    testRad=[testRad;endVal];
                end
                
                
            end
            
        end
        
        if(btopt)
            
            testRad = rToBT(testRad*100,wn*100);
            
        end
        
        vec  = testRad;
        
        if plotType ==1
            
            vec = testRad-control;
            
            
        end
        
        diffs(:,i+3+length(noiseTemps))=vec;
        legStr{i+3+length(noiseTemps)}=upper(mol);
        
    end
    
    
    if ~tempCurvesOpt
        
        diffs(:,2:3)=[];
        legStr(2:3)=[];
        
    end
    
    minNoise = min(min(noiseCurves));
    removeList  = false(1,size(diffs,2));
    
    
    
    if(absflag)
        
        diffs = abs(diffs);
        
    end
    if logopt&&plotType==1
        
        removeList(1)=true;
        
    end
    
    if sigOnly&&~isempty(noiseTemps)
        
        for i = 2:size(diffs,2)
            if max(diffs(:,i))<minNoise
                removeList(i)=true;
            end
        end
        
        
    end
    
    diffs(:,removeList)=[];
    legStr(removeList)=[];
    
    testLim = max(max(diffs));
    
    maxLim = max([maxLim testLim]);
    
    allDiffs{k}=diffs;
    
    
end

%Create elements relating to ranges of values

lDiffs = size(allDiffs{1},2);

%Find the min and max ranges

diffs = cell(0);


if length(allDiffs)==1
    diffs = cell(1,lDiffs);
    arr = allDiffs{1};
    for j=1:lDiffs
        
        diffs{j}=arr(:,j);
    end
    
else
    
    allLeg = {};
    
    valsToCompare = zeros(length(fullwn),length(allDiffs));
    for j = 1:lDiffs
        
        %The array of values to compare is initialized with nfreq vs
        %nprofiles
        
        
        for i = 1:length(allDiffs)
            
            arr = allDiffs{i};
            valsToCompare(:,i)=0;
            try
                if j<=size(arr,2)
                    valsToCompare(1:size(arr,1),i)=arr(:,j);
                end
            catch error
                disp(error);
                
            end
            
        end
        
        if j<=length(legStr)
            maxVals = max(valsToCompare,[],2);
            minVals = min(valsToCompare,[],2);
            
            diffs{end+1}=maxVals;
            legEntry = legStr{j};
            
            allLeg{end+1}=legEntry;
            notNoise = isempty(strfind(legEntry,'+/-'));
            if (~all(maxVals==minVals))&&notNoise
                
                %diffs{end+1}=maxVals;
                %allLeg{end}=['min ',legEntry];
                %allLeg{end}=['max ',legEntry];
                
            end
        end
        
    end
    legStr =allLeg;
end


%If the ranges are not equal then create two curves, otherwise use the
%first set

h=figure;

topList = zeros(1,length(noiseTemps)+1);
ti=1;

 noiseIx = 1;
 curveIx = 1;
 clr = [1 0 0];
 lsp = '-';

for i = 1:length(diffs)
    
    d=diffs{i};
    legEntry = legStr{i};


    if ~isempty(strfind(lower(legEntry),'control'))
     
       lsp = '-';
        
    elseif ~isempty(strfind(legEntry,'+/-'))
        
        lsp = '-';
        clr = generateColorSpec(noiseIx,length(noiseTemps),'lines');
        noiseIx = noiseIx+1;
    else 
        
        lsp = ':';
        clr = generateColorSpec(curveIx,length(diffs)-length(noiseTemps));
        curveIx = curveIx+1;
    end
    
    
    a= plotCurves(fullwn,d,lsp,'Color',clr);
    
    if ~isempty(noiseTemps)
        
        if i<=(length(noiseTemps)+1)
            topList(ti)=a;
            ti = ti+1;
        end
    end
    
    if i==1
        hold on;
    end
    
end

hold off;



niceLegend(legStr);
xlabel('Wavenumber (cm^-^1)','fontsize',12);

yunits = '(W/[cm^2 sr cm^-^1])';
ypref = 'Radiance';
ymid = ' ';

if btopt
    yunits = '(K)';
    ypref = 'Brightness temperature';
end

if plotType ==1
    
    ymid=' difference ';
    
end

xlim([min(wn),max(wn)]);
ylim([1e-2,maxLim]);
ylabel([ypref,ymid,yunits],'fontsize',12);

ydata = diffs;
xdata = fullwn;
    function a =  plotCurves(varargin)
        if(logopt)
            a=semilogy(varargin{:});
        else
            
            a=plot(varargin{:});
        end
    end


for ti = 1:length(topList)
    %set(topList(ti),'erasemode','xor');
    %set(topList(ti),'erasemode','background');
    uistack(topList(ti),'top');
    
end


allMols = lower(molecules);
molData = [];
molData.wn=fullwn;

for j = 1:length(allMols)
    
    mol = allMols{j};
    
    for k = 1:length(legStr)
        
        legEntry  = legStr{k};
        
        if strcmpi(legEntry,mol)

            molData = setfield(molData,mol,diffs{k});
            
        end
        
    end
end

end

