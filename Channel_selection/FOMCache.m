classdef FOMCache<handle
    %Cache used to store FOM values during calculation
    
    properties
        
       %Parent channels selection base 
       parent
       
       %Maximum cache size
       maxSize;
       
       %index of next empty cell
       ix;
       
       %cell array containing logical indices
       indexCell;
       
       %Array containing FOMs
       fOMArr;
       
        
    end
    
    methods
        
        function fMC = FOMCache(parent, maxSize)
            
            fMC.parent = parent;
            fMC.maxSize = maxSize;
            
            fMC.indexCell = cell(1,maxSize);
            fMC.fOMArr = zeros(size(parent.selectedChannels));
            
            fMC.ix = 1;
            
            storeFOM(fMC,false(size(fMC.fOMArr)),0);
            
            
        end
        
        
        function fomVal = getFOM(fMC,channels,storeVal)
            
            i=1;
            cmplt = false;
            
            while (i<fMC.ix) && ~cmplt;
                
                index = fMC.indexCell{i};
                
                if all(index==channels)
                    cmplt = true;
                    
                    fomVal = fMC.fOMArr(i);
                    
                end
                
                i=i+1;
 
            end
            
            
            if ~cmplt
                
                fomVal = calculateFOM(fMC.parent,channels);
                
                if(storeVal)
                    
                    storeFOM(fMC,channels,fomVal);
                    
                end
                
            end
            
            
        end
        
        function storeFOM(fMC,channels,fOMVal)
            
            fMC.indexCell{fMC.ix}=channels;
            fMC.fOMArr(fMC.ix)=fOMVal;
            
            %Replace oldest value if cache is full
            if fMC.ix==fMC.maxSize;
                
                fMC.ix =1;
                
            else
                fMC.ix = fMC.ix+1;
            end
            
        end
        

    end
    
end

