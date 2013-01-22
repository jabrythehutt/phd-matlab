classdef ICChannelSelector < SimpleChannelSelector

    
    properties
        
        
    end
    
    methods
        
        function CS = ICChannelSelector(k,se,sa)
            CS = CS@SimpleChannelSelector(k,se,sa);
        end
        
        
        function tf = testFinished(CS)

            currentFOM = cacheCalculateFOM(CS,CS.selectedChannels,true);
            fullFOM = cacheCalculateFOM(CS,true(size(CS.selectedChannels)),true);
            
            tf =currentFOM>=fullFOM*0.9;
           
        end
        
        function fOMVal = calculateFOM(CS,channels)
            
            if isempty(find(channels,1,'first'))
                
                fOMVal = 0;
            else
            
                fOMVal = FOMCalculator.calculateDOF(CS,channels);
            
            
            end
        end
        
       
        
    end
    
end

