classdef FOMCalculator
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods(Static)
        
        %Calculate degrees of freedom for a channel selection setup
        function dof = calculateDOF(CS,channels)
            ki = CS.k(channels,:);
            seiInv = CS.seInv(channels,channels);
            a = ki'*(seiInv*ki);
            a=(a+CS.saInv)\a;
            dof = trace(a);
            
        end
        
        %Calculate Shannon information for a channel selection setup
        function shan= calculateShannon(CS,channels)
            
            ki = CS.k(channels,:);
            seiInv = CS.seInv(channels,channels);
            s=CS.saInv*((ki'*seiInv)*ki);
            s=det(s);
            shan = s*CS.saDet;
            
        end
        
    end
    
end

