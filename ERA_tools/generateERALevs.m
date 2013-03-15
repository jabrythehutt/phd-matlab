function [ levs ] = generateERALevs( levLims )


levLst = zeros(1,37);
        
        ix = 1;
        
        for i = 1000:-25:750
            levLst(ix)=i;
            ix = ix+1;
            
        end
        
        for i = 700:-50:250
            levLst(ix)=i;
            ix= ix+1;
        end
        
        for i = 225:-25:100
            levLst(ix)=i;
            ix = ix+1;
        end
        
        levLst(ix:end)=[70 50 30 20 10 7 5 3 2 1];

        
        
        levs = levLst(levLst>=levLims(1)&levLst<=levLims(2));
        
end

