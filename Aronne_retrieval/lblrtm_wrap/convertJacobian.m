function [ kOut ] = convertJacobian(k,wn,R,varProf,inputType,outputType )

%varProf in required mr units
%wn units are cm^-1
%conversion types: 
%(R units are W/(cm^2 sr cm^-1) to be consistent with LBLRTM)
%0 = dR/dln(mr)
%1 = dR/dmr
%2 = dB/dln(mr)
%3 = dB/dmr

kOut = k;
f = calculateRConversionFactor();

    function factor  = calculateRConversionFactor()
        h = 6.626068e-34; %Planck's constant (J-s)
        c = 2.99792458e8;  %speed of light (m/s)
        kB = 8.314/6.022e23; %Boltzmann's constant (J/K)

        alpha1 = 2*h*c^2;
        alpha2 = h*c/kB;
        
        v = wn*100.0;
        r= R*100.0;
        
        %This is dB/dR
        factor = 100.0*(alpha1*alpha2*v.^4)./((r.^2+(alpha1*r.*v.^3)).*(log((1+((alpha1*v.^3)./r)))).^2);
        
    end

    function kO = convertToBT(kIn)

        kO=kIn;
        
        for j=1:length(varProf)
            
            kO(:,j)=kIn(:,j).*f;
            
        end

    end


    function kO = convertToR(kIn)
        
        kO= kIn;
        
         for j=1:length(varProf)
            
            kO(:,j)=kIn(:,j)./f;
            
            
        end
        
    end


    function kO = convertToDMR(kIn)
        
        kO = kIn;
        for j = 1:length(varProf)
            
            kO(:,j)=kIn(:,j)/varProf(j);
            
        end
    end

    function kO = convertToDLnMR(kIn)
        
        kO = kIn;
        for j = 1:length(varProf)
            
            kO(:,j)=kIn(:,j)*varProf(j);
            
        end
        
        
    end

%Check if dR/d... <> dB/d... conversion is required and perform conversion

if inputType==0||inputType ==1
    
    if outputType==2||outputType==3
        
        kOut = convertToBT(kOut);
        
    end
    
end


if inputType ==2||inputType ==3
    
    if outputType ==0||outputType ==1
        
        kOut = convertToR(kOut);
        
    end
    
    
end


%Check if d../dln(mr) <> d../d(mr) conversion is required

if inputType ==0||inputType ==2
    
    if outputType ==1||outputType ==3
        
        kOut = convertToDMR(kOut);
    end

end


if inputType ==1||inputType ==3
    
    if outputType ==2||outputType==0
        
        kOut = convertToDLnMR(kOut);
        
        
    end
    
end

end

