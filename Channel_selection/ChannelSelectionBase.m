classdef ChannelSelectionBase <handle
    
    
    %Base class for channel selection methods
    
    
    
    
    properties(SetAccess = private)
        
        %Full Jacobian
        k;
        
        %FOM for all channels;
        fullFOM;
        
        %The initial information spectrum
        initialFOMs;
        
        %Array of selected channels
        selectionOrder;
        
        %Measurement error covariance
        se;
        %And its inverse
        seInv;
        
        %A priori covariance
        sa
        
        %and its inverse
        saInv;
        
        %Determinant of sa
        saDet;
        
        %Cache for storing pre-calculated FOM values
        fOMCache;
        
        
        %Boolean array of selected channels;
        selectedChannels;
        
        %Map containing the selection order index and the FOM improvement gained
        fOMDiff;
        
        %Most recently accepted channel
        lastChannel;
        
        
        %minimum acceptable fraction of information content
        iCFraction;
        
        %field to store current FOM;
        currentFOM;
        
    end
    
    methods
        
        function  cSB = ChannelSelectionBase(k,se,sa,iCFrac)
            
            
            cSB.k=k;
            cSB.sa = sa;
            cSB.saDet = det(sa);
            cSB.saInv=inv(sa);
            cSB.se=se;
            cSB.iCFraction= iCFrac;
            cSB.seInv = inv(se);
            cSB.selectedChannels = false(1,size(se,1));
            cSB.selectionOrder=containers.Map('KeyType','uint32','ValueType','uint32');
            cSB.fOMDiff = containers.Map('KeyType','uint32','ValueType','double');
            cSB.fOMCache = FOMCache(cSB,10);
            cSB.currentFOM = 0;
            
            
        end
        
        function selectChannel(cSB,chanIx)
            
            %Call this method to register a selected channel
            
            if ~cSB.selectedChannels(chanIx)
                
                fomVal1 = cSB.currentFOM;
                
                cSB.lastChannel = chanIx;
                cSB.selectedChannels(chanIx)=true;
                
                fomVal2 = cacheCalculateFOM(cSB,cSB.selectedChannels,true);
                
                selectionIndex = nnz(cSB.selectedChannels);
                cSB.selectionOrder(selectionIndex)=chanIx;
                
                cSB.currentFOM = fomVal2;
                cSB.fOMDiff(selectionIndex)=fomVal2-fomVal1;
                
                disp(['Selected channel: ',num2str(chanIx)]);
                disp(['   Improvement = ',num2str(fomVal2-fomVal1)]);
                disp(['   Current FOM = ',num2str(cSB.currentFOM)]);
                
            end
            
        end
        
        function imp = calculateImprovement(cSB,chans1,chans2)
            
            
            if all(chans1==chans2)
                
                imp=0;
                
            else
                
                
                %Calculate the first value using the cache since this is likely
                %to be repeated many times
                fomVal1 = cacheCalculateFOM(cSB,chans1,true);
                
                %Calculate the second using the second without the cache since
                %it is likely to be rejected as a configuration
                fomVal2 = cacheCalculateFOM(cSB,chans2,false);
                
                
                imp = fomVal2-fomVal1;
                
                
            end
            
        end
        
        
        
        function fomVal = cacheCalculateFOM(cSB,chans,storeVal)
            
            fomVal = getFOM(cSB.fOMCache,chans,storeVal);
            
        end
        
        
        function tf = isFinished(cSB)
            
            %Test 1: Check if all channels have been selected
            tf1 = all(cSB.selectedChannels);
            
            
            %Then test abstract criterea
            tf2 = testFinished(cSB);
            
            
            %Return true if either is true
            tf = tf1||tf2;
            
            
        end
        
        
        function channels =selectChannels(cSB)
            
            if all(~cSB.selectedChannels)
                tic;
                
                cSB.initialFOMs = zeros(size(cSB.selectedChannels));
                
                for i = 1:length(cSB.selectedChannels)
                    
                    selChans = cSB.selectedChannels;
                    selChans(i)=true;
                    fom = calculateFOM(cSB,selChans);
                    cSB.initialFOMs(i) = fom;
                    
                end
                
                
                cSB.fullFOM = cacheCalculateFOM(cSB,true(size(cSB.selectedChannels)),true);
                
                disp(['Full FOM = ',num2str(cSB.fullFOM)]);
                
                doSelectChannels(cSB);
                toc;
                
            end
            
            channels = cSB.selectedChannels;
            
        end
        
        
        function chanMap = cacheCalculateRemainingFOMs(cSB,tf)
            
            disp('Calculating remaining channel scores');
            
            chanMap = containers.Map('KeyType','uint32','ValueType','double');
            
            remainingChans = find(~cSB.selectedChannels);
            
            
            if (length(remainingChans)==length(cSB.selectedChannels))&&~isempty(cSB.initialFOMs)
                
                for i =1:length(cSB.initialFOMs)
                    
                    chanMap(i)=cSB.initialFOMs(i);
                    
                end
  
            else
                
                for i = 1:length(remainingChans)
                    
                    testChan = remainingChans(i);
                    testChans = cSB.selectedChannels;
                    testChans(testChan)=true; 
                    fOM = cacheCalculateFOM(cSB,testChans,tf);
                    chanMap(testChan) = fOM;
                    
                end
                
            end
            
            
        end
        
        
        function chanMap = calculateRemainingFOMs(cSB)
            
            chanMap = cacheCalculateRemainingFOMs(cSB,false);
            
        end
        
        
        function [bestChan,improvement] = findBestRemainingChannel(sCS)
            
            chanMap = calculateRemainingFOMs(sCS);
            
            highestFOM = 0;
            bestChan = 0;
            
            
            remainingChans = keys(chanMap);
            
            for i = 1:length(remainingChans)
                
                chan = remainingChans{i};
                fom = chanMap(chan);
                
                
                if fom>highestFOM
                    highestFOM = fom;
                    bestChan = chan;
                    
                end
                
            end
            
            
            newFOM = highestFOM;
            
            improvement = newFOM-cSB.currentFOM;
            
            
        end
        
        
        function tf = testFinished(cSB)
            
            
            tf =cSB.currentFOM>=(cSB.fullFOM*cSB.iCFraction);

        end
        
    end
    
    methods(Abstract)
        
        fOM = calculateFOM(cSB,ch);

        doSelectChannels(cSB);
        
    end
    
end

