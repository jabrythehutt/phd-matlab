function [ string ] = logical2Str( logArr)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

i=1;
j=1;
a= zeros(1,uint16(length(logArr))/uint16(8));


while i+7<=length(logArr)
    s = binArr2num(logArr(i:i+7));
    a(j)=s;
    j=j+1;
    i=i+8;
end

string = char(a);


%Remaining bits are printed as a string and the last character is the
%number of binary characters printed
nRem = rem(length(logArr),8);

if nRem>0
    string = [string,sprintf('%i',logArr(end-nRem+1:end))];
end

string = [string,num2str(nRem)];


    function n = binArr2num(binArr)
        n =sum(binArr.*2.^[7:-1:0]);
        
    end

    

end

