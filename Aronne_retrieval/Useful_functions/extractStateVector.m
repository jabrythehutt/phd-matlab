function [stateVec ] = extractStateVector(profile,aJParams,stateMask,convMap)


if ~exist('stateMask','var')
    
   stateMask = true(length(aJParams)*length(profile.tdry)); 
end

if ~exist('convMap','var')
    
    convMap =  containers.Map('KeyType','uint32','ValueType','any');
    convMap(1) = @(x)log(x);
end



allMols = lower(molecules());
stateVec = zeros(length(profile.tdry)*length(aJParams),1);
ix = 1;
delta = length(profile.tdry);
for i =1:length(aJParams)
    convFun = @(x)x;
    mIx = aJParams(i);
    param = 'tdry';
    
    if isKey(convMap,mIx)
       convFun = convMap(mIx); 
    end
    
    
    if mIx>0
       param = allMols{mIx}; 
        
    end
    
    stateVec(ix:ix+delta-1)=convFun(profile.(param));
    
    ix = ix+delta;
end


stateVec = stateVec(stateMask);

end

