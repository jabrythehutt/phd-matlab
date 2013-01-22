function [ sAOut] = convertSA( sA,vec,inputType,outputType )


%vec is either BT or radiance depending on inputType;

%iOTypes:

%0=MR
%1=ln(MR)


A = @(mr,a)log(mr);
B = @(lmr,b)exp(lmr);
sAOut = sA;


if inputType==0&&outputType==1
    
     sAOut = convertCovariance(sA,vec,A);
    
end


if inputType==1&&outputType==0
    
    sAOut = convertCovariance(sA,vec,B);
    
    
end




end

