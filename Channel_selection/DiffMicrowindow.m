classdef DiffMicrowindow <Microwindow
    
    %Concrete microwindow where finish criteria is decided by fraction of
    %last improvement compared to first
    
    properties
        
        %min
        minFrac
        
    end
    
    methods
        
        
        function dMW = DiffMicrowindow(parent,startChan,minFrac)
            
            dMW = dMW@Microwindow(parent,startChan);
            dMW.minFrac = minFrac;
        end
        
        function tf = testFinished(mW)

            %Test if ratio of the last improvement to the last is less than
            %the minimum fraction
            tf = mW.fOMDiffs(1)*mW.minFrac >= mW.fOMDiffs(max(cell2mat(keys(mW.fOMDiffs))));
        
        end
        
        
    end
    
end

