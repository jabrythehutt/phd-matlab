function [priorCovs,finalCovs, h ] = plotCovs( priorProf,sa,finalProf,hatS,aJParams )

if ~exist('aJParams','var')
    
    aJParams = [0 1];
end



%For now only plot wv;


h=[];
convFn  = @(x,y)exp(x);

allMols = lower(molecules());
priorCovs = cell(size(aJParams));
finalCovs =  cell(size(aJParams));

%Convert covariance into

ix = 1;
delta = length(priorProf.tdry);

for i =1:length(aJParams)
    
    m = aJParams(i);
    param = 'tdry';
    
    if m==0
        
        %Temperature
        
        
        priorVec = priorProf.(param);
        finalVec = finalProf.(param);

    elseif m>0
        
        %Molecule
        
        
        
        param = allMols{m};
        
        priorVec = log(priorProf.(param));
        finalVec = log(finalProf.(param));
    end
    
    
    
    priorCov = sa(ix:ix+delta-1,ix:ix+delta-1);
    finalCov = hatS(ix:ix+delta-1,ix:ix+delta-1);
    
    
    
    priorCovs{i} = convertCovariance(priorCov,priorVec,convFn);
    finalCovs{i} = convertCovariance(finalCov,finalVec,convFn);
    ix = ix+delta;
    
end




end

