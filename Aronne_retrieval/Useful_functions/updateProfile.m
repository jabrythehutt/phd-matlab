function [ profOut] = updateProfile(vec,profIn,aJParams,stateMask,convFunMap )

if ~exist('stateMask','var')
   
    stateMask = false(length(aJParams)*length(profIn.tdry),1);
    stateMask(1:length(vec))=true;
    
    
end


if ~exist('convFunMap','var')
   
    convFunMap = containers.Map('KeyType','uint32','ValueType','any');
    convFunMap(1)=@(x)exp(x);
    
    
end

allMols = lower(molecules());
profOut = profIn;

ix = 1;
delta = length(profIn.tdry);
ix2 = 1;

for i = 1:length(aJParams)
    
    mIx = aJParams(i);
    tf = stateMask(ix:ix+delta-1);
    
    delta2 = nnz(tf);
    if delta2>0
        
        convFun = @(x)x;
        if isKey(convFunMap,mIx)
            convFun = convFunMap(mIx);
        end
        
        
        datavec = vec(ix2:ix2+delta2-1);
    
        if mIx==0
        
            param = 'tdry';
        else
            param = allMols{mIx};
        
        end
    
        profOut.(param)(tf)=convFun(datavec);
    
    end

    
    ix = ix+delta;
    ix2 = ix2+delta2;
    
end





end

