classdef Microwindow< handle
    
    
    properties
        
        %Parent Channel selector;
        parent;

        %First selected channel in range
        firstChannel;
        
        %Last selected channel in range
        lastChannel;
        
        %Map containing order of channel selection
        selectionOrder;
        
        %Map containing the order and improvements gained each time
        fOMDiffs;
 
        
        
    end
    
    methods
        
        function mW= Microwindow(par,startChan)
            
            mW.parent = par;
            mW.firstChannel = startChan;
            mW.lastChannel = startChan;
            
            mW.selectionOrder  = containers.Map('KeyType','uint32','ValueType','uint32');
            mW.selectionOrder(1)=startChan;
    
            mW.fOMDiffs = containers.Map('KeyType','uint32','ValueType','double');
            mW.fOMDiffs(1) = calculateTotalImprovement(mW);
        end
        
        
        function channels = selectedChannels(mW)
            
            channels = false(size(mW.parent.selectedChannels));
                
            channels(mW.firstChannel:mW.lastChannel)=true;
            

            
        end
        
        
        function commitToParent(mW)
            
            chans = values(mW.selectionOrder);
            for i = 1:length(chans)
                chan = chans{i};
                mW.parent.selectChannel(chan);
  
            end
            
            
        end
        
        
        function imp = calculateTotalImprovement(mW)
            
            newChans = mW.parent.selectedChannels | selectedChannels(mW);
            imp = mW.parent.calculateImprovement(mW.parent.selectedChannels,newChans);
        end
        
        function grow(mW)
            %Add channels either side of the first and last channel until
            %the microwindow meets the abstract finished condition
            
            while ~mW.isFinished()
                
                
                
                imps = zeros(1,2);
                chans = zeros(1,2);
                
                chans(1) = mW.firstChannel-1;
                chans(2) = mW.lastChannel+1;
                
                imps(1) = calculateChannelImprovement(mW,chans(1));
                imps(2) = calculateChannelImprovement(mW,chans(2));

                
                [imps,ix]=sort(imps,2,'descend'); 
                chans = chans(ix);
                
                newChan = chans(1);

                mW.firstChannel = min([newChan,mW.firstChannel]);
                mW.lastChannel = max([newChan,mW.lastChannel]);
                
                newIx = 1+mW.lastChannel-mW.firstChannel;
                
                mW.fOMDiffs(newIx)=imps(1);
                mW.selectionOrder(newIx)=newChan;
                
            end
            
        end
        
        
        function imp = calculateChannelImprovement(mW,channel)
            
            imp = 0;
            
            if(channel>0&&channel<=length(mW.parent.selectedChannels))
                
                chans1 = mW.parent.selectedChannels | selectedChannels(mW);
                chans2 = chans1;
                chans2(channel)=true;
                imp = mW.parent.calculateImprovement(chans1,chans2);
                
            end

        end
        
        
        function tf = isFinished(mW)
            
            %Test 1: abstract criteria is met
            tf1 = testFinished(mW);
            
            %Test 2: check if no further improvement may be gained
            testChan = mW.firstChannel-1;
            
            tf2 = calculateChannelImprovement(mW,testChan)==0;

            
            testChan = mW.lastChannel+1;
            
            tf2 = tf2&&(calculateChannelImprovement(mW,testChan)==0);
            
            
            tf = tf1||tf2;
            
            
        end
        
    end
    
    
    methods(Abstract)
        
        tf = testFinished(mW);
       
        
    end
    
end

