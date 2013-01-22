classdef ICMicroWindowSelector <MicroWindowSelector
    
    
    properties
        %Number of trial windows for each trial
        n;
    end
    
    methods
        
        function mWS = ICMicroWindowSelector(k,se,sa,icfrac,n)
            
            mWS = mWS@MicroWindowSelector(k,se,sa,icfrac);
            mWS.n=n;

        end
        
        
        function nOut = numberOfTrialWindows(mWS)
            
            nOut=mWS.n;
            
        end
        
        
        function fom = calculateFOM(mWS,channels)
            
            fom = FOMCalculator.calculateDOF(mWS,channels);
            
        end
        
        
        
        
    end
    
end

