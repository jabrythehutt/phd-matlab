function [ h ] = plotState( xhat,retrievalParams,vec,varargin)

paramStrings = {'Temperature','Water vapour','CO2'};
parameterNames = [{'vecstring'},{'hats'},{'sa'},{'plottype'},{'plotparams'},{'truth'},{'mrunits'},{'fontsize'},{'ydirn'}];

vecstring='Pressure (mb)';
hats=[];
sa=[];
plottype=2;
plotparams=retrievalParams;
truth=[];
mrunits='(g/kg)';
fontsize=12;
ydirn='reverse';

% check that all input param names are expected ones and assign any specified values.
for q = 1:2:length(varargin);
    if ~ischar(varargin{q})
        error(['Parameter in position ' num2str(q) ' was not a string']);
    else
        rst = strcmpi(varargin{q}, parameterNames);
        found_param_name = any(rst);
        if found_param_name == 0
            error(['Parameter name ' varargin{q} ' is unknown']);
            
        else
            paramName=parameterNames{find(rst,1,'first')};
            eval([paramName,' = varargin{q+1}']);
        end
    end
end

if isempty(truth)
    
    plottype =0;
    
end

numCurves = length(xhat);

if(~isempty(truth))
    
    numCurves = numCurves +1;
    
end

if(~isempty(hats))
    
    numCurves = numCurves+2;
end

if(~isempty(sa))
    
    numCurves = numCurves+2;
    
end
plotData = cell(length(plotparams),numCurves);

for j = 1:length(plotparams)
    param = plotparams(j);
    for i = 1:length(xhat)
        
        plotData{j,i}=convertData(param,extractData(param,xhat{i}));
        
    end
    
    relIx = 0;
    
    if(~isempty(truth))
        relIx=relIx+1;
        
        plotData{j,length(xhat)+1}=convertData(param,extractData(param,truth));
        
    end
    
    vrs = {sa,hats};

    for i = 1:length(vrs)
        
        
        vr = vrs{i};
        
        if(~isempty(vr))
            relIx=relIx+1;
            dg = extractData(param,diag(vr));
            dg = convertVariance(param,plotData{j,1},dg);
            
            initVec = plotData{j,length(xhat)};
            
            if(all(eq(vr,sa)))
                
                initVec = plotData{j,1};
                
            end
            
            minLimVec = initVec-dg;
            maxLimVec = initVec+dg;
            
            plotData{j,relIx+length(xhat)}=minLimVec;
            
            relIx = relIx+1;
            plotData{j,relIx+length(xhat)}=maxLimVec;
            
        end
        
    end
    
    for k = 1:numCurves
        
        plotData{j,k}=processData(param,plotData{j,k});
        
    end
    
    
    
end






for i = 1:size(plotData,1)
    
    figure;
    legStr = cell(1,size(plotData,2));
    legHandles = zeros(1,length(legStr));
    hold on;
    
    for j = 1:size(plotData,2)
  
        lstle = generateLineS(j);
        plotVec = plotData{i,j};
        legHandles(j)=plot(plotVec,vec,lstle);
        legStr{j} = generateLegString(j);
        
    end

    hold off;
    
    for v=1:length(vrs)
        
        vr = vrs{v};
        
        if(~isempty(vr))
            
            legStr(end-1)=[];
            legHandles(end-1)=[];
            
        end
        
    end
    
    ylabel(vecstring,'fontsize',fontsize);
    param = plotparams(i);
    xlabel(generateXString(param),'fontsize',fontsize);
    set(gca,'YDir',ydirn);
    ylim([min(vec),max(vec)]);
    legend(legHandles,legStr,'Location','best');
    
    
end

    function vec = convertVariance(param,fg,diag)
        
        vec = sqrt(diag);
        
        if param>0;
            
            vec = exp(vec);
            vec = vec.*fg;
            vec = vec-fg;
            
        end
        
    end


    function lsp = generateLineS(ix)
        endStr = {'-c','-b','-b','-m','-m'};
        validIx = [false false false];
        
        if(~isempty(truth))
            
            validIx(1)=true;
            
        end
        
        if(~isempty(sa))
            
            validIx(2)=true;
            validIx(3)=true;
            
        end
        
        if(~isempty(hats))
            
            validIx(4)=true;
            validIx(5)=true;
            
        end

        endStr = endStr(validIx);
        
        
        
        if(ix==1)
            
            lsp = '-r';
            
        elseif(ix==length(xhat))
            
            lsp = '-g';
            
        elseif(ix>length(xhat))
            
            lsp=endStr{ix-length(xhat)};
            
            
            
            
        else
            
            exclStr = {'-','k','b','g'};
            
            lsp = generateLineSpec(ix,exclStr);
            
        end
        
    end



    function str = generateLegString(ix)
        
        endStr = {'Truth','Initial variance','Initial variance','Final variance','Final variance'};
        validIx = [false false false];
    
        if(~isempty(truth))
            
            validIx(1)=true;
            
        end
        
        if(~isempty(sa))
            
            validIx(2)=true;
            validIx(3)=true;
            
        end
        
        if(~isempty(hats))
            
            validIx(4)=true;
            validIx(5)=true;
            
        end

        endStr = endStr(validIx);
        
        if(ix==1)
            
            str= 'Apriori';
            
        elseif(ix<length(xhat))
            
            str = ['Iteration ',num2str(ix-1)];
            
            
            
        elseif(ix==length(xhat))
            
            str = 'Final';
            
        else
            
            str = endStr{ix-length(xhat)};
            
        end
            

        
    end

    function str = generateXString(param)
        
        pref = paramStrings{param+1};
        mid = ' ';
        unit = '(K)';
        
        if(param>0)
            
            mid = ' mixing ratio ';
            unit = mrunits;
            
        end
        
        
        if(plottype>0)
            
            mid = [mid,'error '];
            
        end
        
        if(plottype==2)
            unit = '(%)';
            
        end
        
        str = [pref,mid,unit];
        
    end

    function data = convertData(param,dIn)
        
        data= dIn;
        
        if(param ~=0)
            data = exp(data);
        end
        
        
    end


    function data = processData(param,dIn)
       
        data = dIn;
        
        
        if(plottype>0)
            
            truthData = extractData(param,truth);
            
            truthData = convertData(param,truthData);
            
            data = data-truthData;
            
            if(plottype ==2)
                
                data = 100.0*data./truthData;
                
            end
        end
        
        
    end

    function data = extractData(param,fullX)
        vecIx = retrievalParams==param;
        vecIx = find(vecIx,1,'first');
        startIx = ((vecIx-1)*length(vec))+1;
        endIx = length(vec)*vecIx;
        data = fullX(startIx:endIx);
        
    end

end

