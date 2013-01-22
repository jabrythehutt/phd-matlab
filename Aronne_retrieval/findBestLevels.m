function [ levels, scores, minTemp,maxTemp ] = findBestLevels( bt,alt,temp,criterea )

%criterea:

%0: Rank according to difference in min and max values
%1: Rank according to ability to sound upper troposphere as defined by
%points between min of temp within alt range 8-20km and a point 2km below



scores = zeros(1,length(alt));



if exist('criterea','var')==0
    
    criterea = 0;
end



if criterea ==0,
    minTemp = 1000;
    maxTemp  = 0;
  
   for i = 1:1:length(alt)
       
       mnTemp = min(bt(:,i));
       mxTemp = max(bt(:,i));
       
       
       
       scores(i)=mxTemp-mnTemp;
       
       if mxTemp>maxTemp
          
           maxTemp = mxTemp;
       end
       
       if mnTemp<minTemp
          
           minTemp = mnTemp;
       end
       
       
       
   end
    
elseif criterea==1,
    
    
    levRange = zeros(1,2);
    minTemp = 300;
    
    for i = 1:1:length(alt)
        
        currTemp = temp(i);
        
        if alt(i)<=20.0
            
            if currTemp<minTemp
                
                minTemp = currTemp;
                levRange(2)=i;
                
            end 
        end
 
    end
    
    topAlt = alt(levRange(2));
    
    for i = levRange(2):-1:1

        botAlt = alt(i);
        
        if botAlt >=topAlt-5.0
            
            levRange(1)=i;
            
        end
        
    end
    
    
    maxTemp = temp(levRange(1));
    minTemp = temp(levRange(2));
    
    
    for i = 1:1:length(alt),

        minTScore = minTemp-min(bt(:,i));
        
        maxTScore = max(bt(:,i))-maxTemp;
        %Easy to beat max temp from all the lower levels, therefore remove
        %amount by which this is beaten
        if maxTScore>0
            
            maxTScore = 0;
            
        end
        
        score = minTScore+maxTScore;
        
        if i >=levRange(2)
            score = min(scores);
        end
        
        scores(i)=score;

    end
    

end


[~,levels] = sort(scores,2,'descend');


end

