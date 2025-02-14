function [ bts,wn] = calculateBTForAltitudes( profile,altRanges,vBound,dv,opd)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

cleanup_flag = true;
atmflag = 1;
wn_range = [vBound(1)-25.0,vBound(2)+25.0];
bts = [];
wn = vBound(1):dv:vBound(2);

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
    
    
    [wnum, rad, trans] = ...
        simple_matlab_lblrun(cleanup_flag, atmflag, prof, wn_range, ...
        args{:});
    
    
    
    if isempty(bts),
        
        bts = zeros(length(wn),size(altRanges,1));
        
    end
    
    bti = rToBT(rad(:)*100.0,wnum(:)*100.0);
    
    if length(bti)+1==length(wn)
        bti = [bti;bti(end)];
        
    end
    
    bts(:,i)= bti;
    
    
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

