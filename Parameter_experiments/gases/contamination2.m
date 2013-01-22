%pathToProfile = '/home/dj104/Retrieval/Aronne_retrieval/Profiles/MIDLATITUDE_SUMMER.csv';
allAbsorbersPath = '/home/dj104/Retrieval/Parameter_experiments/gases/downwelling_absorbers_1-29_molData.mat';
%initialContamPath = '/home/dj104/Retrieval/Parameter_experiments/gases/alt_8km_downwelling_molData.mat';
initialContamPath = '/home/dj104/Retrieval/Parameter_experiments/gases/all_downwelling_contamination_molData.mat';
%initialContamPath = '/home/dj104/Retrieval/Parameter_experiments/gases/allContaminant_molData.mat';
setenv('LBL_HOME','/home/dj104/lblrtm/LBL_HOME');


fileName = 'contamination_case_study.mat';

initialContam  = load(initialContamPath);
initialContam = initialContam.molData;

if ~exist(fileName,'file')

    
    molData = load(allAbsorbersPath);
    molData = molData.molData;

    zlevels = [linspace(0.0,15.0,10),linspace(17.0,60.0,10)];
    profile = calculateProfile(2,zlevels,true(1,3));
    profile.co2 = zeros(size(profile.alt))+390;

    tempErr = 1;
    pcErr = 0.3;
    co2Err = 0.2;
    
    
    %profile = rmfield(profile,'h2o');
    
    errorProfile = [];
    
    %Generate error profile from pc error and temp error
    allMols = lower(molecules());
    
    errorProfile.tdry = zeros(size(profile.tdry))+tempErr;
    
    for i = 1:length(allMols)
        
        mol = allMols{i};
        
        if isfield(profile,mol)
            
            molProfile = getfield(profile,mol);
            errorProfile  = setfield(errorProfile,mol,molProfile*pcErr);
            
        end
        
        
    end
    
    errorProfile.co2 = zeros(size(profile.tdry))+co2Err;
    errorProfile.o3 = profile.o3*0.05;
    
    
    hObs = 7;
    endH = profile.alt(end);
    angle = 0.0;
    
    extraArgs = cell(1);
    extraArgs{1} = 'HBOUND';
    extraArgs{2} = [hObs, endH,angle];
    extraArgs{3} = 'MOLECULES';
    extraArgs{4} = true(1,29);
    
    
    wnSpec = 200:0.1:600;
    result = generateContaminationSpectrum(molData,profile,errorProfile,...
        'h2o',wnSpec,0.3,extraArgs);
    save(fileName,'result');
    
else
    
    result = load(fileName);
    result = result.result;
    
end

%Plot the profile used
plotProfile(result.initial_profile,'error_profile',result.initial_error_profile,'yparam','pres');

xdata = zeros(length(result.contaminationBT),1);
xdata(:) = result.wn;

%Plot significant downwelling absorbers
absMolData = load(allAbsorbersPath);
absMolData = absMolData.molData;

ydata = cell(1,length(result.A)+1);
legStr = cell(size(ydata));
lineStyles = cell(size(ydata));
colorSpecs = cell(size(ydata));
maxVal = 0;
for i = 1:length(result.A)

    mol = result.A{i};
    molSpec = getfield(absMolData,mol);
    ydata{i} = abs(interp1(absMolData.wn,molSpec,xdata));
   
    legStr{i} = upper(mol);
    lineStyles{i} = ':';
    colorSpecs{i} = generateColorSpec(i,length(result.A));
    
    maxVal  = max(maxVal,max(ydata{i}));
end

ydata{end} = zeros(size(ydata{1}))+0.3;
legStr{end} = '+/-0.3K';
lineStyles{end} = '-';
colorSpecs{end} = 'r';

xaxlabel = 'Wavenumber (cm^-^1)';
yaxlabel = 'Brightness temperature difference (K)';
xlims = [min(result.wn),max(result.wn)];
ylims = [1e-2,maxVal];
plotCommand = 'semilogy';

standardPlot(xdata,ydata,legStr,plotCommand,xaxlabel,yaxlabel,xlims,ylims,lineStyles,colorSpecs);

%Plot initial contamination spectrum
legStr = {'Contamination spectrum', 'Noise'};


lineStyles = {'--','-'};
colorSpec = {'k','r'};


contSpec = interp1(initialContam.wn,initialContam.h2o,result.wn);
ydata = {contSpec,result.noise};
ylims = [1e-2,max(contSpec)];
standardPlot(xdata,ydata,legStr,plotCommand,xaxlabel,yaxlabel,xlims,ylims,lineStyles,colorSpec);

removeIx = contSpec>=result.noise;
addContaminationShading(removeIx,xdata,ylims);

%Plot the final contamination spectrum
ydata = {result.contaminationBT,result.noise};

%Set the same limits as the first plot for a visual comparison
ylims = [1e-2,max(contSpec)];

h = standardPlot(xdata,ydata,legStr,plotCommand,xaxlabel,yaxlabel,xlims,ylims,lineStyles,colorSpec);
removeIx = result.final_remove_index;

addContaminationShading(removeIx,xdata,ylims);

%Plot contamination comparison

dw_cont_7k_path = 'alt_7km_downwelling_molData.mat';
dw = load(dw_cont_7k_path);
dw = dw.molData;

legStr = cell(1,3);
ydata  = cell(size(legStr));
lineStyles = cell(size(legStr));
colorSpec = cell(size(legStr));

ydata{1} = interp1(dw.wn,dw.h2o,xdata);
legStr{1} = 'Full range';
lineStyles{1} = ':';
colorSpec{1} = 'r';


ydata{2} = result.contaminationBT;
legStr{2} = 'Spec profile';
colorSpec{2} = 'k';
lineStyles{2} = ':';

ydata{3} = result.noise;
legStr{3} = '+/-0.3K';
lineStyles{3} = '-';
colorSpec{3} = 'r';


standardPlot(xdata,ydata,legStr,plotCommand,xaxlabel,yaxlabel,xlims,ylims,lineStyles,colorSpec);

remIx1 = ydata{2}>ydata{3}';
remIx2 = (ydata{1}>ydata{3}')&(~remIx1);

addContaminationShading(remIx2,xdata,ylims,'g');
addContaminationShading(remIx1,xdata,ylims);

disp(num2str(length(find(remIx1))));
disp(num2str(length(find(remIx2))));

disp(['Contamination increase = ',num2str(length(find(remIx2))/length(find(remIx2))),'%']);
