function [ logArr ] = str2logical( string )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
nRem = str2double(string(end));

logArr = false(1,(length(string)-nRem-1)*8+nRem);
for i =1:length(string)-nRem-1
    startIx = ((i-1)*8)+1;

    logstring = dec2bin(string(i),8);
    
    for j = 1:length(logstring)
        ix = startIx+j-1;
        logArr(ix)=strcmp(logstring(j),'1');
    end
    
    
end

for i=1:nRem
    
    logArr(i)=strcmp(string(end-nRem+i-1),'1');
    
end

end

