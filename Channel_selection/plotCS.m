function [figH,axH,fomLims,obsAlts,wn]= plotCS( fileNames ,ttle)

if ~exist('ttle','var')
    
    ttle='';
end




%Collect information about which files have the required data

relIx  = false(size(fileNames));
obsAlts = zeros(size(fileNames));
%dirns = false(size(fileNames));
wn = [];

for i =1:length(fileNames)
    
    fileName = fileNames{i};
    
    result = load(fileName);
    if isfield(result,'result')
        
        result = result.result;
        
        if isfield(result,'lowNoise')&&isfield(result,'highNoise')
            
            relIx(i)=true;
            
            if isfield(result,'args')
                
                args = result.args;
                hbound = args{end};
                obsAlts(i) = hbound(1);
                %dirns(i) = hbound(3)==180;
                
            end
            
            if isempty(wn)
                
                if isfield(result,'wn')
                    wn = result.wn;
                    
                end
            end
            
        end
        
        
    end
    
end


fileNames  = fileNames(relIx);
obsAlts = obsAlts(relIx);
%dirns = dirns(relIx);
fomLims = zeros(1,2);
plotArrs = cell(1,2);

for i = 1:length(fileNames)
    
    result = load(fileNames{i});
    result =result.result;

    
    for j = 1:2
        
        
        fldN = 'lowNoise';
        
        if j ==2
            fldN = 'highNoise';
        end

        csData = getfield(result,fldN);
        fom = csData.channelSelector.currentFOM;
        selectedChannels = csData.selectedChannels;

        arr = plotArrs{j};
        if isempty(arr)
            
            
            arr = plotArrs{j};
            
        end
        
        arr(i,:)=selectedChannels*fom;
        
        for sO = 1:length(csData.channelSelector.selectionOrder)
            
            chan = csData.channelSelector.selectionOrder(sO);
            fomAdded = csData.channelSelector.fOMDiff(sO);
            
            arr(i,chan)=fomAdded;
            fomLims(1)=min([fomLims(1),fomAdded]);
            fomLims(2)=max([fomLims(2),fomAdded]);

            
        end
        
        
        plotArrs{j} = arr;
        


    end
    
end


figH = zeros(1,2);
axH = zeros(1,2);
%cBarH = zeros(1,2);

for j = 1:2
    
    titleString = [ttle,' (Low noise)'];
    if j==2
        
        titleString = [ttle, ' (High noise)'];
    end
    
    arr = plotArrs{j};
    figH(j)=figure;
    pcolor(wn,obsAlts,arr);
    axH(j)=gca;
    %set(a,'edgecolor','none');
    shading 'flat';

    xlabel('Wavenumber (cm^-^1)','fontsize',12);
    ylabel('Observer altitude (km)','fontsize',12);
    %cBarH(j) = colorbar;
    colorbar;
    title(titleString,'fontsize',14);
    
end




end

