function [ lineString, lstl,mrkr,clr ] = generateLineSpec( index,excludeList )
%GENERATELINEPARAMETER Summary of this function goes here
%   Detailed explanation goes here

if exist('excludeList','var')==0
    excludeList = {};
end

lstls = {'-','--','-.',':'};
mrkrs = {'','+','o','*','.','x','s','d','^','v','>','<','p','h'};
clrs = {'r','b','k','g','c','m'};

if ~isempty(excludeList)
    
    for j = 1:length(excludeList)
        exclStr = excludeList{j};
        
        lstls = removeFromList(lstls,exclStr);
        mrkrs = removeFromList(mrkrs,exclStr);
        clrs = removeFromList(clrs,exclStr);
        
        
    end
    
end





i = uint32(index);
nclrs = uint32(length(clrs));
nmrkrs = uint32(length(mrkrs));
nlstls = uint32(length(lstls));

clrIx = remIx(i,nclrs);
clr = clrs{clrIx};

lstlIx = remIx(idivide(i,nclrs)+1,nlstls);
lstl = lstls{lstlIx};

mrkrIx = remIx(idivide(i,(nclrs*nlstls))+1,nmrkrs);
mrkr = mrkrs{mrkrIx};


lineString = [lstl,mrkr,clr];


    function ix = remIx(val1,val2)
        ix = rem(val1,val2);
        
        if ix==0
            ix = val2;
        end
    end

    function lst = removeFromList(lst,item)
        
        remI = false(length(lst),1);
        for k = 1:length(lst)
            
            lstIt = lst{k};
            
            if strcmp(lstIt,item)
                
                remI(k)=true;
                
            end
            
        end
        
        lst(remI)=[];
        
    end




end

