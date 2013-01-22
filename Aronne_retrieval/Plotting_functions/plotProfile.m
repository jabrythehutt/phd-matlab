function [ h] = plotProfile( profile,varargin)

%Extra arguments: 
%
%'plot_params': Cell of profile parameters to plot, default is all present parameters
%'units': A map of parameters with their applicable units, defaults are
%'tdry':'K'; 'alt':'km'; 'pres':'mb'; all molecules:'ppmv'
%'error_profile': Structure containing error profile for each parameter
%'yparam': Parameter to plot against, default is 'alt'
%'xscale': Either 'log' or 'linear', default is 'linear'
%'yscale': Either 'log' or 'linear', default is 'linear'




allMols = lower(molecules());
allMols{end+1} = 'molx';
allMols{end+1} = 'moln';

extraArgs = varargin{:};

units = containers.Map;
paramNames = containers.Map;

dirnMap = containers.Map;
dirnMap('pres') = 'reverse';
dirnMap('alt')='normal';


paramNames('pres')='Pressure';
paramNames('alt')= 'Altitude';
paramNames('tdry')='Temperature';
plotParams = {'tdry'};

for i = 1:length(allMols)
    mol = allMols{i};
    units(allMols{i})='ppmv';
    paramNames(mol)=upper(mol);
    plotParams{i+1}= mol;
end

units('moln') = 'ppmv';
units('molx')='ppmv';
paramNames('moln') = 'Absorber n';
paramNames('molx') = 'Retrieval param';

units('tdry') = 'K';
units('pres') = 'mb';
units('alt')  = 'km';

allParams = keys(paramNames);

defaultArgs = {};
defaultArgs{1} = 'units';
defaultArgs{2} = units;

defaultArgs{3} = 'yparam';
defaultArgs{4} = 'alt';

defaultArgs{5} = 'error_profile';
defaultArgs{6} = [];

defaultArgs{7} = 'plot_params';
defaultArgs{8} = plotParams;

defaultArgs{9} = 'xscale';
defaultArgs{10} = 'linear';

defaultArgs{11} = 'yscale';
defaultArgs{12} = 'linear';



[args,argMap] = processDefaultArgs(defaultArgs,extraArgs);



errorProfile = argMap('error_profile');
yParam = argMap('yparam');
ylab = [paramNames(yParam),' (',units(yParam),')'];
yvec = getfield(profile,yParam);
plotParams = argMap('plot_params');


presentParams = cell(size(allParams));
presentParamCount = 0;


for i =1:length(plotParams)
    
    param = plotParams{i};
    
    if isfield(profile,param)
        
        presentParamCount = presentParamCount+1;
        presentParams{presentParamCount}=param;
    end
    
end
presentParams(presentParamCount+1:end)=[];

h = figure;
plotIx  = 0;
for i =1:length(presentParams)
    
    param = presentParams{i};
    plotIx = plotIx+1;
    ax = doPlot(param,plotIx,length(presentParams));

end

    function hl = doPlot(param,ix, maxIx)
        
        legStr = {'Profile'};
        hl = subplot(1,maxIx,ix);
        
        
        vec = getfield(profile,param);
        legH = plot(vec,yvec,'-k');
        
        xsc = argMap('xscale');
        ysc = argMap('yscale');
        
        if ~iscell(xsc)
            
            xsc = {xsc};
        end
        
        if ~iscell(ysc)
            
            ysc = {ysc};
            
        end
        
        
        xscval = xsc{1};
        yscval = ysc{1};
        
        if ix<=length(xsc)
          
            xscval = xsc{ix};
        
        elseif strcmp(param,'h2o')||strcmp(param,'o3')
                
                
            if strcmp(units(param),'ppmv')
                
                xscval = 'log';
                
            end
            
        end
        
        
        if ix<=length(ysc)
            
            
            yscval = ysc{ix};
        end
        
        
        set(gca,'XScale',xscval);
        set(gca,'YScale',yscval);
        
        set(gca,'YDir',dirnMap(yParam));
        ylim([min(yvec),max(yvec)]);
        
        if isfield(errorProfile,param)
            legStr = [legStr,{'Error'}];
            hold on;
            errVec = getfield(errorProfile,param);
            minErr = vec-errVec;
            maxErr = vec+errVec;
            
            legH = [legH,plot(minErr,yvec,'-r')];
            plot(maxErr,yvec,'-r');
            
            hold off;
        
        end
        
        
        if ix ==1
            ylabel(ylab,'fontsize',12);
            legend(legH,legStr,'Location','best');
            
        else
            
            set(gca,'YTickLabel',{});
            
        end 
        xlab = [paramNames(param),' (',units(param),')'];
        xlabel(xlab,'fontsize',12);
        

    end


end

