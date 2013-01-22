function [ jacs,wn] = calculateJacForAltitudes( profile,altRanges,vBound,dv,opd)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

cleanup_flag = true;
atmflag = 1;
wn_range = [vBound(1)-25.0,vBound(2)+25.0];
jacs =cell(1,size(altRanges,1));


for i = 1:size(altRanges,1),
    
    obsAlt = altRanges(i,1);
    endAlt = altRanges(i,2);
    
    prof = trimProfile(profile,obsAlt,endAlt);
    
    angle = 180.0;
    if obsAlt<endAlt
        angle = 0.0;
    end
    
    
    
    args = cell(1);
    args{1} = 'HBOUND';
    args{2} = [obsAlt,endAlt,angle];
    args{3} = 'FTSparams';
    args{4} = [opd, vBound(1), vBound(2),dv];
    args{5} = 'CalcJacobian';
    args{6} = 1;
    
    [wn, jac] = ...
        simple_matlab_AJ_lblrun(cleanup_flag, atmflag, prof, wn_range, ...
        args{:});
    
    
    jacs{i}=jac;
    

    
    
end


    function [prfle] = trimProfile(p,obsAlt,endAlt)
        
        prof_params = {'alt','tdry','pres','h2o','co2','o3','n2o','co','ch4'};
        
        validIndices = [];
        
        minLim = min(obsAlt,endAlt);
        maxLim = max(obsAlt,endAlt);
        
        
        for j=1:1:length(p.alt),
            
            currAlt = p.alt(j);
            
            if currAlt>=minLim&&currAlt<=maxLim,
                
                validIndices = [validIndices, j];
                
            end
            
        end
        
        prfle = [];
        
        for j = 1:1:length(prof_params)
            
            param = prof_params{j};
            
            if isfield(p,param)
                
                exString = ['prfle.',param,'(:,1) = p.',param,'(validIndices(:))'];
                disp(exString);
                
                eval(exString);
            end
            
            
        end
        
        
        
        
    end


end

