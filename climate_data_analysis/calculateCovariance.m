function [ covar,meanArr,mn,mx ] = calculateCovariance( dataPath,v, dimx,lims,pressScale)
%Calculate the covariance of the group of netcdf files in the dataPath for
%the variable v over the dimensions dims and within the limts lims.


%dataPath = path to folder containing netcdf files
%v = variable of interest
%dimx = index of the dimension of interest, 1 = lon, 2= lat, 3 = pressure
%The covariance output is resolved over the dimensions set to true.
%lims = data time limits to consider
%pressScale = The common pressure scale to interpolate all values to

if ~exist('dataPath','var')
    %Data path defaults to current directory
    dataPath = pwd;
    
end

if ~exist('v','var')
    %Selected variable defaults to h2o
    v = 'Water';
end


if ~exist('dimx','var')
    %Default dimension is pressure
    
    dimx = 3;
    
end

if ~exist('lims','var')
    %Limits are in order: lat, lon, pressure, time
    lims = [-180,180;-90,90;0,1000;0,now];
end

if ~exist('pressScale', 'var')
    pressScale = generateLevList();
end





mn = [];
mx=  [];
meanArr=[];
covar = [];
currn = 0;

%Array of dimensions over which calculations are not performed
notDims = 1:3;
notDims(dimx)=[];



%Go through selected data path
lst = dir(dataPath);

for i = 1:length(lst)
    
    fle = lst(i);
    
    %If it is netcdf file
    if(strendswith(fle.name,'.nc'))
        
        flePath  = [dataPath,filesep,fle.name];
        fInfo = ncinfo(flePath);
        
        %If there are 3 dimensions specified
        if(length(fInfo.Dimensions)==3)
            
            [startDate,endDate] = readDates(fInfo);
            
            if(startDate >=lims(4,1))&&(endDate<=lims(4,2))
                
                lons = ncread(flePath,'lon');
                lonix = lons>=lims(1,1)&lons<=lims(1,2);
                
                lats = ncread(flePath,'lat');
                latix = lats>=lims(2,1)&lats<=lims(2,2);
                
                levs  = ncread(flePath,'level');
                levix = levs>=lims(3,1)&levs<=lims(3,2);
                
                startix = [find(lonix,1,'first'),find(latix,1,'first'),find(levix,1,'first')];
                endix = [find(lonix,1,'last'),find(latix,1,'last'),find(levix,1,'last')];
                
                stride = ones(size(startix));
                
                
                %This array should be 3D (lon-lat-lev)
                disp(['Processing data for ',flePath,'...']);
                arr = double(ncread(flePath,v,startix,(endix-startix)+stride,stride));
                
                pressGrid = createPressureGrid(generatePressureFileName(flePath),lims);
                updatecovar(arr,pressGrid);
                
                
            end
            
            
            
        end
        
    end
    
end


    function flName = generatePressureFileName(fName)
        
        flName = strrep(fName,'taijl','aij');
        flName = strrep(flName,'_selected','_prsurf');
        
    end


    function updateMinMaxVec(arr)
        
        
        minArrVec = min(arr);
        maxArrVec = max(arr);
        
        if isempty(mn)
            
            mn = minArrVec;
            mx = maxArrVec;
            
        else
            
            mn = min(minArrVec,mn);
            mx = max(maxArrVec,mx);
            
        end
        
    end

    function updatecovar(arr,pressGrid)
        
        
        
        %Reshape array to have every observation vector as a row in a 2d
        %array
        
        %First permute dimensions of array so that required dim is last
        arr = permute(arr,[notDims,dimx]);
        pressGrid = permute(pressGrid,[notDims,dimx]);

        numRows = size(arr,notDims(1))*size(arr,notDims(2));
        arr = reshape(arr,numRows,size(arr,dimx));
        pressGrid = reshape(pressGrid,numRows,size(pressGrid,dimx));
        
        
        %Interpolate to common pressure grid
        newArr = zeros(size(arr,1),length(pressScale));
        
        for oix = 1:size(arr,1)

            newArr(oix,:) = interp1(pressGrid(oix,:),arr(oix,:),pressScale','linear','extrap');
        
        end
        
        arr = newArr;
        
        updateMinMaxVec(arr);
        
        currn = currn+1;
        weight1 = (currn-1)/currn;
        weight2 = 1/currn;
        
        %arr is a 3d array with dimensions lon-lat-lev
        %Initialise mean and covar if none set
        if isempty(meanArr)
            
            meanArr = zeros(1,size(arr,dimx));
            covar = zeros(size(arr,dimx),size(arr,dimx));
            
        end
        
        meanArr = meanArr*weight1 + mean(arr)*weight2;
        
        %Assume that every arr has same number of rows
        newCov = cov(arr);
        covar = covar*weight1 + newCov*weight2;
        
        
    end


    function dateNum = readDate(dString)
        
        dString = strtok(dString,',');
        dateNum = datenum(dString);
        
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


    function [startDate,endDate]= readDates(fInfo)
        
        dAtt = fInfo.Attributes(1,2);
        
        locs = strfind(dAtt.Value,'From:');
        lim1 = locs(1)+5;
        locs = strfind(dAtt.Value, 'To:');
        lim2 = locs(1);
        
        dString = dAtt.Value(lim1:lim2);
        
        startDate = readDate(dString);
        
        lim3 = lim2+3;
        lim4 = strfind(dAtt.Value,'Model-Time:');
        
        endDate = readDate(dAtt.Value(lim3:lim4));
        
        
    end


end

