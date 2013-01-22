classdef SimpleChannelSelector < ChannelSelectionBase
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
       
    end
    

    
    methods
        
        
        
        function sCS = SimpleChannelSelector(k,se,sa,icfrac)
        
            sCS = sCS@ChannelSelectionBase(k,se,sa,icfrac);
        
        end
        
        function doSelectChannels(sCS)
 
            while ~isFinished(sCS)
                
               [bestChan,imp]=findBestRemainingChannel(sCS);
               selectChannel(sCS,bestChan);
                
            end
            
        end
        
        
        
    end
    
end

