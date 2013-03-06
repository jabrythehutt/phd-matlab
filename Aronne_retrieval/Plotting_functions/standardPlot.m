function [ h, plHandles ] = standardPlot( xdata,ydata,legStrings, plotCommand ,xaxLabel,yaxLabel,xlims,ylims,lineStyles, colorSpecs)
%Creates scatter plots of 
h=figure;


if ~exist('lineStyles','var')
    
    lineStyles = {'-'};
end

if ~exist('colorSpecs','var')
    colorSpecs = {};
end

if ~exist('plotCommand','var')
    plotCommand = 'plot';
end

if ~exist('xaxLabel','var')
    
    xaxLabel = 'Wavenumber (cm^-^1)';
    
end

if ~exist('yaxLabel','var')
    yaxLabel = 'Brightness temperature (K)';
end

if ~iscell(xdata)
    xdata = {xdata};
    
end


%hold on;

plHandles = zeros(size(ydata));

for j = 1:length(ydata)
    
    yd = ydata{j};
    xd = xdata{1};
    
    if j<=length(xdata)
        
        xd = xdata{j};
        
    end
    
    if(j==2)
        hold on;
    end
    
    plH = executePlot(xd,yd,j);
    plHandles(j)=plH;
    
end

hold off;

xlabel(xaxLabel,'fontsize',12);
ylabel(yaxLabel,'fontsize',12);

%Alter legend so that dotted lines are more pronounced 
if exist('legStrings','var')
    
   niceLegend(legStrings);
    
    
end


if exist('ylims','var')
    
    if isempty(ylims)
        
        
        mn = [];
        mx =[];
        for i = 1:length(ydata)
             yd = ydata{i};
            
            if isempty(mn)
                mn = min(yd);
            end
            if isempty(mx)
                mx = max(yd);
                
            end

            mn=min(mn,min(yd));
            mx = max(mx,max(yd));
            

        end
        ylims = [mn,mx];
        
    end
    
    ylim(ylims);
    
    
end


if exist('xlims','var')
    xlim(xlims);
    
end


    function plH = executePlot(xd,yd,ix)
        
        
        lspec = '-';
        cspec = generateColorSpec(ix,length(ydata));
        
        if ~isempty(lineStyles)
            
            lspec = lineStyles{end};
            if length(lineStyles)>=ix
                lspec = lineStyles{ix};
                
            end

        end
        
       if ~isempty(colorSpecs)
            cspec = colorSpecs{end};
            if length(colorSpecs)>=ix
               cspec = colorSpecs{ix};
                
            end

        end
 
        pltArgs = {lspec,'Color',cspec};
        
        if exist('plotArgs','var')
            pltArgs = plotArgs;
        end
        
        pltEx = [plotCommand,'(xd,yd,pltArgs{:})'];
        disp(pltEx);
        plH = eval(pltEx);
        
    end



end

