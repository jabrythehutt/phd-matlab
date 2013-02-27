function [ mn,mx,stdev ] = calculateStats( dataPath,v, dims,lims)
%Function to calculate the stats of the collection of netcdf files in the
%specified data path

%dataPath = path to folder containing netcdf files
%v = variable of interest
%dims = dimensions of interest specified in [lon lat pressure];
%The standard deviation output is resolved over the dimensions set to true.
%For dimensions set to false, the standard deviation is taken over all data
%points
%tLims = data time limits to consider

if ~exist('dataPath','var')
    %Data path defaults to current directory
    dataPath = pwd;
    
end

if ~exist('v','var')
    %Selected variable defaults to h2o
    v = 'Water';
end


if ~exist('dims','var')
    %Default dimension is pressure
    
    dims = [false,false,true];
    
end

if ~exist('lims','var')
    %Limits are in order: lat, lon, pressure, time
    lims = [-180,180;-90,90;0,1000;0,now];
end



mn = 0;
mx=  0;
m2=[];
currmean=[];
currn = [];

sze = zeros(1,3);




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
                arr = ncread(flePath,v,startix,(endix-startix)+stride,stride);
                updatestdev(arr);
                
                
            end
            
            
            
        end
        
    end
    
end




%Finally calculate the stdev from the m2 value
stdev = squeeze(sqrt(m2./(currn-ones(size(currn)))));
mn = squeeze(mn);
mx = squeeze(mx);

    function updatestdev(arr)
        
        %arr is a 3d array with dimensions lon-lat-lev
        
        %Initialise mean, m2 and n if none set
        
        if isempty(currmean)
            
            sze = ones(1,length(dims));
            
            for ix =1:length(dims)
                
                sze(ix) = 1;
                
                if(dims(ix))
                    sze(ix)=size(arr,ix);
                end
            end
            
            
            currmean = zeros(sze);
            m2= zeros(sze);
            currn = zeros(sze);
            mn = min(min(arr));
            mx = max(max(arr));
            
            
        end
        
        mn = min(min(min(arr)),mn);
        mx = max(max(max(arr)),mx);
        
        step = size(currn);
        current = ones(1,3);
        start= current;
        finish = sze;
        nsteps = prod(finish./step);
        
        
        
        
        for s = 1:nsteps
            
            next =  step*s;
            %Generate sub-arrays of data corresponding to desired dimensions
            x = arr(current(1):next(1),current(2):next(2),current(3):next(3));
            
            %Method based on 'online_variance' algorithm described in http://en.wikipedia.org/wiki/Algorithms_for_calculating_variance
            currn = currn+ones(size(currn));
            
            delta = x-currmean;
            currmean = currmean+(delta./currn);
            m2= m2+delta.*(x-currmean);
            
            current = next+start;
            
            
        end
        
        
        
        
    end


    function dateNum = readDate(dString)
        
        dString = strtok(dString,',');
        dateNum = datenum(dString);
        
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

