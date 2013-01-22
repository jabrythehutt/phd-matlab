function [ sEOut] = convertSE( sE,wn,vec,inputType,outputType )


%vec is either BT or radiance depending on inputType;

%iOTypes:

%0=Radiance
%1=BT


B = @(r,wni)convertToBT(r,wn(wni));
R = @(b,wnj)convertToRad(b,wn(wnj));
sEOut = sE;


if inputType==0&&outputType==1
    
     sEOut = convertCovariance(sE,vec,B);
    
end


if inputType==1&&outputType==0
    
    sEOut = convertCovariance(sE,vec,R);
    
    
end




end

