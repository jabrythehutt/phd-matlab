function [ mergedArgs,argMap] = processDefaultArgs( defaultArgs,extraArgs )
%Assumes that args are in name-value pairs
%Replaces defaultArgs and adds missing args

mergedArgs = defaultArgs;
mIx = 0;
argMap =containers.Map;


for i = 1:2:length(defaultArgs)
    
    arg = defaultArgs{i};
    argVal = defaultArgs{i+1};
    argMap(arg) = argVal;
    
end

% 1 Replace default arg values with those specified in extra args
for i = 1:2:length(extraArgs)-1
    
    extraArg =  extraArgs{i};
    argVal = extraArgs{i+1};
    valFound = false;
    argMap(lower(extraArg))=argVal;
    for j = 1:2:length(defaultArgs)-1
        
        defaultArg = defaultArgs{j};
        if strcmpi(defaultArg,extraArg)
            valFound = true;
            mergedArgs{j+1}=argVal;
           
        end
        
    end
    
    if ~valFound
        
        mergedArgs{end+1}=extraArg;
        mergedArgs{end+1}=argVal;

        
    end
    

end


end

