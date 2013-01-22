function [ cb ] = convertCovariance( c,vec,fn )

%Arguments: c is a n x n covariance matrix relating to the vector vec of length n

%fn is the conversion function

%1: Find mean vector from diagonal elements

mu = vec-sqrt(diag(c));
cb = zeros(size(c));


for i = 1:length(vec)
    
    for j = 1:length(vec)
        
        if c(i,j)~=0
            
             e=c(i,j)/((vec(i)-mu(i))*(vec(j)-mu(j)));
             cb(i,j)=e*(fn(vec(i),i)-fn(mu(i),i))*(fn(vec(j),j)-fn(mu(j),j));
            
        end 
    end
    
end


end

