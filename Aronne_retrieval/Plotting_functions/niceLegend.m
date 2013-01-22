function [ h ] = niceLegend( legStrings )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

[h,object_h] = legend(legStrings);

%Alter legend so that dotted lines are more pronounced 

    for lh = 1:length(object_h)
        
        h = object_h(lh);
        
        props = get(h);
        
        if isfield(props,'LineStyle')
            
            lS = get(h,'LineStyle');
            if ~isempty(strfind(lS,':'))
                
                lW = get(h,'LineWidth');
                
                set(h,'LineWidth',lW*10);
                
                
            end
            
            
        end
        
    end


end

