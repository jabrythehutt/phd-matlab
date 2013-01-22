function [polygons ] = addContaminationShading( removeIx,xdata,ylims,clr )

if ~exist('clr','var')
   clr = 'y'; 
end

i=0;
%val =false;

polygons = [];

while i<length(removeIx)
    
    i=i+1;
    val = removeIx(i);
    startIx  =i;
    while val&&i<length(removeIx)

        i=i+1;
        val = removeIx(i);
        
        if ~val||i==length(removeIx)
            
            endIx = i-1;
            
            if startIx ==endIx
                endIx = endIx+1; 
            end
            
            yshape = [ylims(1),ylims(1),ylims(2),ylims(2)];
            
           p = patch([xdata(startIx),xdata(endIx),xdata(endIx),xdata(startIx)],...
               yshape,clr);
           set(p,'FaceAlpha',0.1);
           set(p,'LineStyle','none');
           polygons = [polygons;p];
            
        end
    end
    

    
end


end

