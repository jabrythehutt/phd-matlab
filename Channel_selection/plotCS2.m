function [figH,axH,fomLims,obsAlts,wn]= plotCS2( fileNames ,ttle)

if ~exist('ttle','var')
    
    ttle='';
end




%Collect information about which files have the required data

relIx  = false(size(fileNames));
obsAlts = zeros(size(fileNames));
legStrings = cell(size(fileNames));
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
                dirnStr = ' (u)';
                
                if hbound(3)==0.0
                    dirnStr = ' (d)';
                end
                
                legStrings{i}= [num2str(hbound(1)),'km',dirnStr];
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

obsAlts = obsAlts(relIx);

[obsAlts,ix]=sort(obsAlts);

fileNames  = fileNames(relIx);
fileNames = fileNames(ix);

legStrings = legStrings(relIx);
legStrings = legStrings(ix);

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
    
    
    for i = 1:length(obsAlts)
        
        plH = plot(wn,arr(i,:),'*');
        
        set(plH,'Color',generateColorSpec(i,length(obsAlts)));
       
        if(i==1)
            
            hold on;
        end
        
    end
    
    hold off;

    
    axH(j)=gca;
    set(gca,'YScale','log');
    %set(a,'edgecolor','none');
    %shading 'flat';
    xlim([min(wn),max(wn)]);

    xlabel('Wavenumber (cm^-^1)','fontsize',12);
    ylabel('Information added (DOF)','fontsize',12);
    
    %cBarH(j) = colorbar;
    %colorbar;
    title(titleString,'fontsize',14);
    
    set(figH(j),'Position',get(0,'Screensize'));
    legend(legStrings,'Location','best');
    
    exStr = '_hn';
    
    if j==1
        exStr = '_ln';
        
    end
    
    saveas(figH(j),[ttle,exStr,'.fig'],'fig');
    saveas(figH(j),[ttle,exStr,'.eps'],'psc2');
    
end




end

