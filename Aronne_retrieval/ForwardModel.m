classdef ForwardModel
    %FORWARDMODEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        aJParams;
        lblArgs;
        defaultAtm;
        wnRange;
        profile;
        
        currentStateVec;
        currentJac;
        currentRad;
        currentWn;
        currentSuccess;
        
        %'convMap' contains the functions used to convert the state vector to
        %be compatible with the profile. 'invCovMap' does the inverse.
        convMap;
        invConvMap;
        
        stateMask;
        channelMask
        cleanWD;
    end
    
    properties(Constant)
        allMols = lower(molecules);
        
    end
    
    methods
        
        function fM = ForwardModel(profile,wnRange,lblArgs,aJParams,defaultAtm,convMap,invConvMap,channelMask,stateMask,cleanWD)
            
            fM.profile = profile;
            fM.lblArgs = lblArgs;
            fM.aJParams = aJParams;
            fM.wnRange = wnRange;
            
            if ~exist('defaultAtm','var')
                fM.defaultAtm = 1;
            else
                fM.defaultAtm = defaultAtm;
                
            end
            
            
            if ~exist('convMap','var')
                
                
                fM.convMap = containers.Map('KeyType','uint32','ValueType','any');
                fM.convMap(1)=@(x)exp(x);
                
                fM.invConvMap = containers.Map('KeyType','uint32','ValueType','any');
                fM.invConvMap(1)=@(x)log(x); 
                
            elseif isnumeric(convMap)
                
                fM.convMap = containers.Map('KeyType','uint32','ValueType','any');
                fM.convMap(1)=@(x)exp(x);
                
                fM.invConvMap = containers.Map('KeyType','uint32','ValueType','any');
                fM.invConvMap(1)=@(x)log(x); 
                
            else
                
                fM.convMap = convMap;
                fM.invConvMap = invConvMap;
                
                
            end
            
            if ~exist('channelMask','var')
                
                fM.channelMask = [];
                
            else
                fM.channelMask = channelMask;
                
            end
            
            if ~exist('stateMask','var')
                
                fM.stateMask = true(length(profile.tdry)*length(aJParams),1);
            else
                
                fM.stateMask = stateMask;
            end
            
            if exist('cleanWD','var')
                fM.cleanWD = cleanWD;
            else
                fM.cleanWD = true;
                
            end
            
            fM.currentStateVec= [];
            fM.currentJac = [];
            fM.currentRad = [];
            
            
        end
        
        
        function [jac,wn,success] = calculateJacobian(fM,stateVec)
            
            
            cached = false;
            if ~isempty(fM.currentStateVec)
                
                if all(stateVec==fM.currentStateVec)
                   
                    if ~isempty(fM.currentJac)
                        cached = true;
                    end

                end
            end
            
            if ~cached
                
                [fM.currentJac,fM.currentWn,fM.currentSuccess] = doCalculateJacobian(fM,stateVec);
                fM.currentStateVec = stateVec;
            end
            
            jac = fM.currentJac;
            wn = fM.currentWn;
            success = fM.currentSuccess;
            
        end
        
        function [rad,wn,success] = calculateRadiance(fM,stateVec)
            
            cached = false;
            if ~isempty(fM.currentStateVec)
                
                if all(stateVec==fM.currentStateVec)
                   
                    if ~isempty(fM.currentRad)
                        cached = true;
                    end

                end
            end
            
            if ~cached
                
                [fM.currentRad,fM.currentWn,fM.currentSuccess] = doCalculateRadiance(fM,stateVec);
                fM.currentStateVec = stateVec;
            end
            
            rad = fM.currentRad;
            wn = fM.currentWn;
            success = fM.currentSuccess;
           
            
            
        end
        
        function [rad,wn,success]=doCalculateRadiance(fM,stateVec)
            prof = updateProfile(stateVec,fM.profile,fM.aJParams,fM.stateMask,fM.convMap);
            [wn, rad,success] = simple_matlab_lblrun(...
                fM.cleanWD, fM.defaultAtm, prof, fM.wnRange, fM.lblArgs{:});
            
            if(isempty(fM.channelMask))
                fM.channelMask = true(size(rad));
            end
            
            rad = rad(fM.channelMask);
            
        end
        
        
        function [jac,wn,success]=doCalculateJacobian(fM,stateVec)
            
            
            prof = updateProfile(stateVec,fM.profile,fM.aJParams,fM.stateMask,fM.convMap);
            jacArgs = fM.lblArgs;
            jacArgs{end+1}= 'CalcJacobian';
            jacArgs{end+1} = fM.aJParams;
            
            [wn, jac,success] = simple_matlab_AJ_lblrun(...
                fM.cleanWD, fM.defaultAtm, prof, fM.wnRange, jacArgs{:});
            
            %Convert sections of the Jacobian according to conversion map
            
            ix = 1;
            delta = length(fM.profile.tdry);
            
            for i =1:length(fM.aJParams)
                param = fM.aJParams(i);
                subVec = stateVec(ix:ix+delta-1);
                if(param==0)
                    
                    %Temperature Jacobian units are dT/dx so only convert
                    %if a conversion factor is specified
                    
                    if isKey(fM.convMap,param)
                        
                        %Do conversion
                        
                        
                    end
                    
                    
                else
                    
                    doConv = true;
                    %Molecular Jacobian units are dT/dln(x) so only convert
                    %if the conversion factor is not exp(x);
                    
                    if isKey(fM.convMap,param)
                        
                        convFn = fM.convMap(param);
                        if all(exp(subVec)==convFn(subVec))
                            
                            doConv = false;
                        end

                        
                    end
                    
                    if doConv
                        %Do conversion here
                        
                    end
                    
                    
                end
                
                ix = ix+delta;
                
            end

            
            if(isempty(fM.channelMask))
                fM.channelMask = true(size(jac,1));
            end
            
            %Apply mask
            jac = jac(fM.channelMask,fM.stateMask);
            
        end
        
    end
    
end

