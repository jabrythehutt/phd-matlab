function [ h ] = plot_k( k,wn,pressure,isT,c)

if exist('isT','var')==0
   isT = false; 
end

if exist('c','var')==0
    
    c = [min(min(k)),max(max(k))];
    
end
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

    function kout = processK(kIn)
       %Interpolate values to represent layers
        kout = zeros(size(kIn'));
        
        for i =1:size(kIn,2)
           
            j=i+1;
            
            if i ==size(kIn,2),
                j = i;
            end
            
            lev1 = kIn(:,i);
            lev2 = kIn(:,j);
            
            kout(i,:)=(lev1+lev2)/2;
            
            
        end
        
    end

h=pcolor(wn,pressure,processK(k));
shading interp;
caxis(c);
grid off;
xlabel('Wavenumber (cm^-^1)','fontsize',12);
ylabel('Pressure (mb)','fontsize',12);

ttl = 'Water vapour Jacobian (W/[cm^2 sr cm^-^1 ln(VMR)])';
if isT,
    ttl = 'Temperature Jacobian (W/[cm^2 sr cm^-^1 K])';
end
title(ttl,'fontsize',13);
set(gca,'yDir','reverse');
colorbar;



end

