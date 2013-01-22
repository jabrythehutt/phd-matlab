classdef MicroWindowSelector < ChannelSelectionBase
    %Class to select microwindows based on Dudhia et al. 2002
    
    properties
        
        %map containing completed microwindows
        microWindows;
    end
    
    methods(Abstract)
        
        nTriaWindows = numberOfTrialWindows(mWS);
        
        
    end
    
    methods
        
        function n = nTW(mWS)
            
            
            n = numberOfTrialWindows(mWS);
            
            n = min([n,length(find(~mWS.selectedChannels))]);
            
            
        end
        
        
        function mWS = MicroWindowSelector(k,se,sa,icfrac)
            
            mWS = mWS@ChannelSelectionBase(k,se,sa,icfrac);
            mWS.microWindows = containers.Map('KeyType','uint32','ValueType','any');
            
        end
        
        function addMicroWindow(mWS,mW)
            
            mW.commitToParent();
            nextIx = size(mWS.microWindows,1)+1;
            mWS.microWindows(nextIx)=mW;
            
        end
        
        function doSelectChannels(mWS)
            
            while ~isFinished(mWS)
                
                
                
                %Find best remaining channels
                chanMap =  calculateRemainingFOMs(mWS);
                
                fOMs = cell2mat(values(chanMap));
                
                [fOMs,ix]=sort(fOMs,2,'descend');
                
                chans = cell2mat(keys(chanMap));
                
                chans = chans(ix);
                
                n = nTW(mWS);
                
                %Generate trial microwindows for the next top spots
                
                bestWindow = [];
                
                
                
                for i = 1:n
                    
                    disp(['Growing test window ',num2str(i), ', starting channel = ',num2str(chans(i))]);
                    
                    dMW = DiffMicrowindow(mWS,chans(i),0.1);
                    dMW.grow();
                    disp(['   FOM added = ',num2str(calculateTotalImprovement(dMW))]);
                    
                    if isempty(bestWindow)
                        
                        bestWindow = dMW;
                        
                    elseif calculateTotalImprovement(dMW)>calculateTotalImprovement(bestWindow)
                        
                        bestWindow = dMW;
                    end
                    
                end
                
                addMicroWindow(mWS,bestWindow);
                
            end
            
            
        end
        
        
        
    end
    
    
    
    
    
    
    
    
end

