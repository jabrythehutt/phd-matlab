function [ h,xdata,plotData,legendString,molData ] = plotAndSaveRanges(fileNames,args,saveTo,molsToPlot)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

if exist('saveTo','var')==0
    
    saveTo = datestr(now(),'YY-mm-DD_HH-MM-SS');
    
end

if ~exist('molsToPlot','var')
    
    molsToPlot = true(1,29);
    
end

allTests = cell(size(fileNames));
allProfiles = cell(size(fileNames));
allControls = cell(size(fileNames));
gases = [];
wns=cell(size(fileNames));

for i = 1:length(fileNames)
    
    fileName = fileNames{i};
    load(fileName);
    allTests{i}=tests;
    allProfiles{i}=tests.profile;
    allControls{i}=tests.controlrad;
    wns{i} = tests.wn;
    
    if isempty(gases)
        
        if islogical(molsToPlot)
            molsToPlot = find(molsToPlot);
        end
        
        gasesToFind = lower(molecules(molsToPlot));
        
        gases = false(1,29);

        for j = 1:length(gasesToFind)
            
            if isfield(tests,gasesToFind{j})
               
                gases(molsToPlot(j))=true;
            end
            
        end
    end
end

[h,xdata,plotData,legendString,molData]=plotTestGases(lower(molecules(gases)),allTests,allControls,wns,allProfiles,args{:});
saveas(h,saveTo,'fig');
save([saveTo,'plotData.mat'],'plotData');
save([saveTo,'_molData.mat'],'molData');



end

