function [ prof,cov_prof,uMap ,min_prof,max_prof] = extractMeanProfile( dataDir,dimx,lims,pressScale,vMap )
%Constructs a profile structure for all the data specified in data dir

%Set default dimensions to use to levels
if ~exist('dimx','var')
    dimx = 3;
    
end

%Default pressure scale to interpolate data onto
if ~exist('pressScale','var')
    %Use ERA-Interim pressure scale
    pressScale = generateLevList();
    
end

if ~exist('lims','var')
    
    lims = [-180,180;-90,90;0,1000;0,now];
end


if ~exist('varMap','var')
    %Mapping of variable names
    vMap = containers.Map();
    vMap('HNO3')='hno3';
    vMap('H2O2')= 'h2o2';
    vMap('CO')='co';
    vMap('CH4')='ch4';
    %vMap('HCL')='HCL';
    %vMap('HOCL')='HOCL';
    %vMap('CLONO2')= 'CLONO2';
    vMap('HBr')= 'hbr';
    vMap('HOBr')='hobr';
    vMap('N2O')='n2o';
    %vMap('CFC')='CFC';
    vMap('Water') = 'h2o';
    vMap('SO2')='so2';
    vMap('SO4')='so4';
    vMap('NH3')='nh3';
    vMap('OH_vmr')='oh';
    vMap('HO2_con')='ho2';
    vMap('NO_vmr')='no';
    vMap('NO2_vmr')='no2';
    
end




%Mapping of unit strings to LBLRTM units
unitMap = containers.Map();
unitMap('V/V') = 'A';
unitMap('kg/kg')='C';
unitMap('molecules/cm3')='B';

%Mapping of unit conversions for consistency with LBLRTM

convMap = containers.Map();

%Convert to ppmv
convMap('V/V')=1e6;

%Convert to g/kg
convMap('kg/kg')=1e3;

convMap('molecules/cm3')=1;

%Extract stats for each of the mapped variables

allVars = keys(vMap);
prof = [];
%error_prof=[];
cov_prof = [];
min_prof=[];
max_prof =[];

prof.pres =pressScale;
%error_prof.pres = pressScale;
cov_prof.pres = pressScale;
min_prof.pres = pressScale ;
max_prof.pres = pressScale;


uMap = containers.Map();


outputFile = [dataDir,filesep,generateUniqueQueryName(dimx,lims,pressScale,vMap)];
%If this query has been run before than just load the results from the file
if exist(outputFile,'file')
    
    result = load(outputFile);
    prof= result.prof;
    cov_prof=result.cov_prof;
    uMap = result.uMap;
    min_prof = result.min_prof;
    max_prof=result.max_prof;
    
    
else
    
    
    for i=1:length(allVars)
        
        v = allVars{i};
        disp(['Extracting data for ',v,'...']);
        updateProfileWithVariable(v);
        uMap('pres')='A';
    end
    
    save(outputFile,'prof','cov_prof','uMap','min_prof','max_prof');
    
end



    function updateProfileWithVariable(v)
        [covar,meanval,mn,mx]=calculateCovariance(dataDir,v,dimx,lims,pressScale);
        stdev = sqrt(diag(covar));
        %Use the mean for the profile, stdev for the error_profile and
        %mn and mx for the min and max profiles resp.
        
        
        unitString = extractUnitString(dataDir,v);
        
        fldName = vMap(v);
        [profVec,lblunit]= convertUnits(meanval,unitString);
        
        prof= setfield(prof,fldName,profVec);
        min_prof = setfield(min_prof,fldName,convertUnits(mn,unitString));
        max_prof = setfield(max_prof,fldName,convertUnits(mx,unitString));
        % error_prof = setfield(error_prof,fldName,convertUnits(stdev,unitString));
        cov_prof = setfield(cov_prof,fldName,convertCov(covar,meanval,unitString));
        
        uMap(fldName)=lblunit;
        
    end

    function [conCov, lblunit] = convertCov(cov1,meanVec,unitString)
        
        [convFac, lblunit] = findConversionFactor(unitString);
        convFun = @(x,y)x*convFac;
        conCov = convertCovariance(cov1,meanVec,convFun);
        
    end

    function [convFac,lblunit] = findConversionFactor(unitString)
        
        %Search for the LBLRTM equiv. unit string
        foundUnit = '';
        replacePos = 0;
        allUnits = keys(unitMap);
        j=1;
        
        while strcmp(foundUnit,'')&&j<=length(allUnits)
            
            uStr = allUnits{j};
            res = findstr(uStr,unitString);
            if ~isempty(res)
                foundUnit = uStr;
                replacePos = res(1);
                
            end
            
            j=j+1;
            
        end
        
        convVal1Str = unitString(1:replacePos-1);
        convVal1Str = strrep(convVal1Str,'10^','1e');
        convVal1 = str2double(convVal1Str);
        convVal2 = convMap(foundUnit);
        convFac = convVal1*convVal2;
        
        lblunit = unitMap(foundUnit);
    end


    function [concVec,lblunit] = convertUnits(vec1,unitString)
        
        [convFac, lblunit] = findConversionFactor(unitString);
        vec1 = reshape(vec1,[numel(vec1),1]);
        
        concVec = vec1*convFac;
        %Make into a column vector
        
        
        
    end

    function val = generateUniqueValueForLevList(levList)
        
        val = sum(generateUniqueValueForLevel(levList));
        
        
    end

    function val = generateUniqueValueForLevel(lev)
        
        val = 1.0003*lev;
        
    end

    function levLst = generateLevList()
        
        levLst = zeros(37,1);
        
        ix = 1;
        
        for x = 1000:-25:750
            levLst(ix)=x;
            ix = ix+1;
            
        end
        
        for x = 700:-50:250
            levLst(ix)=x;
            ix= ix+1;
        end
        
        for x = 225:-25:100
            levLst(ix)=x;
            ix = ix+1;
        end
        
        levLst(ix:end)=[70 50 30 20 10 7 5 3 2 1];
        
        
    end

    function fileName = generateUniqueQueryName(dimx,lims,pressScale,vMap)
        
        fileName = [num2str(dimx),'_'];
        
        %Append the sum of the pressure levels rather than each individual
        %one. This may not always give a unique value
        fileName = [fileName,num2str(generateUniqueValueForLevList(pressScale)),'_'];
        
        for ix = 1:size(lims,1)
            for jx = 1:2
                
                fileName = [fileName,num2str(lims(ix,jx))];
                
                if jx==1
                    
                    fileName = [fileName,'-'];
                else
                    
                    if ix < size(lims,1)
                        
                        fileName = [fileName,'_'];
                        
                    end
                    
                end
                
            end
        end
        
        fileName = [fileName,'.mat'];
        
        
        
    end





end

