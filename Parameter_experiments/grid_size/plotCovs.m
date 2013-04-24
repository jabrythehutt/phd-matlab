function [priorCovs,finalCovs, h ] = plotCovs( priorProf,sa,finalProf,hatS,aJParams,stateMask,convMap )

%Assumes that state mask is not applied to sa but is to hatS.

if ~exist('aJParams','var')
    
    aJParams = [0 1];
end

if ~exist('stateMask','var')
    
    stateMask = false(length(aJParams)*length(priorProf.tdry),1);
    stateMask(1:size(hatS,1))=true;
end

if ~exist('convMap','var')
    convMap = containers.Map('KeyType','uint32','ValueType','any');
    convMap(1) = @(x,y)exp(x);
    
    
end



%For now only plot wv;


h=[];


allMols = lower(molecules());
priorCovs = cell(size(aJParams));
finalCovs =  cell(size(aJParams));

%Convert covariance into

ix = 1;
ix2=1;
delta = length(priorProf.tdry);

for i =1:length(aJParams)
    
    
    m = aJParams(i);
    param = 'tdry';
    paramProp = 'Temperature';
    tf = stateMask(ix:ix+delta-1);
    delta2 = nnz(tf);
    
    
    if delta2>0

        convFun  = @(x,y)x;
        if isKey(convMap,m)
            
           convFun = @(x,y)exp(x); 
        end
        
        
        if m==0
            
            %Temperature
            
            
            %priorVec = priorProf.(param);
            finalVec = finalProf.(param);
            finalVec = finalVec(tf);
            
        elseif m>0
            
            %Molecule
            
            
            
            param = allMols{m};
            paramProp = upper(param);
            %priorVec = log(priorProf.(param));
            finalVec = log(finalProf.(param));
            finalVec = finalVec(tf);
        end
        
        
        
        priorCov = sa(ix:ix+delta-1,ix:ix+delta-1);
        priorCov = priorCov(tf,tf);

        finalCov = hatS(ix2:ix2+delta2-1,ix2:ix2+delta2-1);
        
        
        
        priorCovs{i} = priorCov ;%convertCovariance(priorCov,priorVec,convFn);
        finalCovs{i} = convertCovariance(finalCov,finalVec,convFun);
        clms = [min(min(min(priorCov)),min(min(finalCovs{i}))),max(max(max(priorCov)),max(max(finalCovs{i})))];
        
        
        h = [h,plotCov(priorProf.alt(tf),priorCov,'Altitude (km)',['Prior ',paramProp,' covariance'])];
        caxis(clms);

        h = [h,plotCov(priorProf.alt(tf),finalCovs{i},'Altitude (km)',['Final ',paramProp,' covariance'])];
        caxis(clms);
        
    end
    
    ix = ix+delta;
    ix2 = ix2+delta2;
    
    
    
end


    function h = plotCov(x,cv,xlbl,ttle)
        h=figure;
        
        pcolor(x,x,cv);
        shading flat;
        g = colorbar;
        set(g,'fontsize',12);
        title(ttle,'fontsize',13);
        xlabel(xlbl,'fontsize',12);
        ylabel(xlbl,'fontsize',12);
        
    end


end

