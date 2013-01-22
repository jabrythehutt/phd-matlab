function [ result ] = generateContaminationSpectrum(allAbsorbers, profile,errorProfile,desiredParam,wnSpec,noise,extraArgs )
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

result = [];
result.allProfiles = cell(1,8);
result.allSpectra = cell(1,8);
result.initial_profile = profile;
result.initial_error_profile = errorProfile;



startWn = min(wnSpec);
endWn = max(wnSpec);

if length(noise)==1
    noise = zeros(size(wnSpec))+noise;
    
end

if length(wnSpec)~=length(noise)
    
    wnSpec = linspace(startWn,endWn,length(noise));
    
end


% worstCont = getfield(worstContamination,desiredParam);
% worstCont = interp1(worstContamination.wn,worstCont,wnSpec);


result.wn = wnSpec;
result.noise = noise;

result.desired_param  = desiredParam;
cleanupFlag = true;

allMols = lower(molecules());
sigMols = {};
sigMolsIx = 0;


%Step 1 find significant mols
for i = 1:length(allMols)
    
    mol = allMols{i};
    
    if isfield(allAbsorbers,mol)%&&(~strcmpi(mol,desiredParam))
        
        testVec = getfield(allAbsorbers,mol);
        testVec = interp1(allAbsorbers.wn,testVec,wnSpec);
        
        if any(testVec>=noise)
            
            sigMolsIx = sigMolsIx+1;
            sigMols{sigMolsIx}=mol;
            
        end
    end
end

result.A = sigMols;
molsFound = {};
molsFoundIx = 0;

molsNotFound = {};
molsNotFoundIx = 0;

%Step 2 find significant molecules present in input profle
for i = 1:length(sigMols)
    
    mol = sigMols{i};
    
    %Put into set C
    if isfield(profile,mol)
        molsFoundIx = molsFoundIx+1;
        molsFound{molsFoundIx}=mol;
        
        %Put into set D
    else
        molsNotFoundIx = molsNotFoundIx+1;
        molsNotFound{molsNotFoundIx}=mol;
        
    end
    
end




%Step 3 add profiles corresponding to the min and max values of the missing
%molecules
wnRemoveIx = false(size(wnSpec));

standardAtms = [1 2 5];
standardProfs = cell(size(standardAtms));

for i = 1:length(standardAtms)
    
    atm = standardAtms(i);
    standardProfs{i} = calculateProfile(atm,profile.alt,true(1,29));
    
end


for i = 1:length(molsNotFound)
    mol = molsNotFound{i};
    molProfs = zeros(length(profile.alt),length(standardProfs));
    
    for j = 1:length(standardProfs)
        
        standardProf = standardProfs{j};
        molProf = getfield(standardProf,mol);
        molProfs(:,j)=molProf(:);
        
    end
    
    minProf = min(molProfs,[],2);
    maxProf  = max(molProfs,[],2);
    meanProf = mean(molProfs,2);
    errProf = (maxProf-minProf)/2;
    
    profile = setfield(profile,mol,meanProf);
    errorProfile = setfield(errorProfile,mol,errProf);
    
    molsFound{end+1} = mol;
    
end

molsNotFound = {};
result.profile = profile;
result.error_profile = errorProfile;
result.C = molsFound;
result.D = molsNotFound;

%result.step3_remove_index = wnRemoveIx;


%Step 4 simulate set of spectra with all absorbers present
tProfile = profile.tdry;
tErrProf = errorProfile.tdry;

dProfile = getfield(profile,desiredParam);
dErrProf = getfield(errorProfile,desiredParam);

profIx = 0;
molSpec = false(size(allMols));
for i = 1:length(molsFound)
    
    mol = molsFound{i};
    molSpec = molSpec|(strcmp(allMols,mol));
    
end

defaultArgs = {};
defaultArgs{1} = 'FTSparams';
defaultArgs{2} = [wnSpec(2)-wnSpec(1),startWn,endWn];
defaultArgs{3} = 'MOLECULES';
defaultArgs{4} = molSpec;
lblArgs = processDefaultArgs(defaultArgs,extraArgs);

vbound = [startWn-25.0,endWn+25.0];


for tempIx = 1:2
    
    tProf = tProfile-tErrProf;
    
    if tempIx==2
        
        tProf = tProfile+tErrProf;
        
    end
    
    for dIx = 1:2
        
        
        dProf = dProfile-dErrProf;
        
        if dIx == 2
            
            dProf = dProfile+dErrProf;
        end
        
        
        for absIx = 1:2
            
            prof = [];
            prof.alt = profile.alt;
            prof.pres = profile.pres;
            prof.tdry = tProf;
            prof = setfield(prof,desiredParam,dProf);
            
            
            for i=1:length(molsFound)
                mol = molsFound{i};
                
                if ~strcmpi(mol,desiredParam)
                    
                    
                    baseProf = getfield(profile,mol);
                    errProf = getfield(errorProfile,mol);
                    
                    molProf = baseProf-errProf;
                    if absIx ==2
                        molProf = baseProf+errProf;
                        
                        prof = setfield(prof,mol,molProf);
                    end
                    
                    
                end
                
            end
            
            
            profIx = profIx+1;
            
            [w,r,t]=simple_matlab_lblrun(cleanupFlag,2,prof,vbound,lblArgs{:});
            
            
            result.allProfiles{profIx} = prof;
            result.allSpectra{profIx}=r;
            
            
            
        end
        
    end
    
    
end


% for tempIx = 1:2
%     
%     tProf = tProfile-tErrProf;
%     
%     if tempIx==2
%         
%         tProf = tProfile+tErrProf;
%         
%     end
%     
%     for absIx = 1:2
%         profIx = profIx+1;
%         
%         prof = [];
%         prof.alt = profile.alt;
%         prof.pres = profile.pres;
%         prof.tdry = tProf;
%         
%         
%         for i = 1:length(molsFound)
%             mol = molsFound{i};
%             baseProf = getfield(profile,mol);
%             molErrProf = getfield(errorProfile,mol);
%             
%             molProf = baseProf+molErrProf;
%             
%             if absIx==2
%                 
%                 molProf = baseProf-molErrProf;
%                 
%             end
%             prof = setfield(prof,mol,molProf);
%         end
%         
%         
%         [w,r,t]=simple_matlab_lblrun(cleanupFlag,2,prof,vbound,lblArgs{:});
%         
%         
%         result.allProfiles{profIx} = prof;
%         result.allSpectra{profIx}=r;
%         
%     end
% end
% 
% molSpec = strcmp(allMols,desiredParam);
% defaultArgs{4} = molSpec;
% lblArgs = processDefaultArgs(defaultArgs,extraArgs);
% 
% %Step 5 simulate spectra with only desired absorber
% for i = 1:4
%     
%     testProf = result.allProfiles{i};
%     
%     for j = 1:length(molsFound)
%         mol = molsFound{j};
%         
%         if ~strcmpi(mol,desiredParam)
%             
%             testProf = setfield(testProf,mol,zeros(size(testProf.tdry)));
%             
%         end
%     end
%     
%     profIx = profIx+1;
%     [w,r,t]=simple_matlab_lblrun(cleanupFlag,2,testProf,vbound,lblArgs{:});
%     result.allProfiles{profIx} = testProf;
%     result.allSpectra{profIx}=r;
%     
% end

result.allBTSpectra = cell(size(result.allSpectra));

%Conversion to BT
for i = 1:length(result.allSpectra)
    
    r = result.allSpectra{i};
    if length(r)==length(wnSpec)-1
        
        r= [r;r(end)];
        
    end
    bt = rToBT(r*100,wnSpec*100);
    result.allBTSpectra{i}=bt;
    
    
end


%Step 6 find differeces between spectra
result.difference_BT_spectra = cell(1,4);
absDiffs = zeros(length(wnSpec),4);

ix = 0;

for i = 1:2:7
    ix = ix+1;
    spec1 = result.allBTSpectra{i};
    spec2 = result.allBTSpectra{i+1};
    result.difference_BT_spectra{ix}=spec1-spec2;
    absDiffs(:,ix)=abs(spec1-spec2);
    
end


%Step 7 find worst case contamination
result.contaminationBT = max(absDiffs,[],2);

%Step 8 find frequencies to remove
wnRemoveIx(:) = wnRemoveIx(:)|(result.contaminationBT(:)>=noise(:));

result.final_remove_index = wnRemoveIx;



end

