function [ fPath ] = downloadProfileData( lims,hres )
%lims includes limits for profile

if ~exist('lims','var') || isempty(lims)
    %Limits are in order: lat, lon, pressure, time
    lims = [-180,180;-90,90;0,1000;0,now];
end

if ~exist('hres','var')||isempty(hres)
    %Grid spacing in degrees [lon lat]
    hres = [0.75,0.75];
    
end

javaaddpath('../ext/java/JSON.jar');
javaaddpath('../ext/java/ECMWF-API.jar');
javaaddpath('../ext/java/netcdfAll-4.3.jar');


import org.ecmwf.*;
import org.json.*;
import ucar.grib.*;


levLst = generateLevList();


server = DataServer();
request = JSONObject();
target = [pwd,filesep,generateFileName(lims,hres),'.grib'];
convertedTarget = [pwd,filesep,generateFileName(lims,hres),'.nc'];


request.put('dataset'   , 'interim');

levListString = generateLevString(lims);
request.put('levelist',levListString);
disp(['Requested level list = ',levListString]);


request.put('levtype','pl');

%Include temperature, RH and ozone
request.put('param','130.128/157.128/203.128');
request.put('step','0');


gridString = generateGridString(hres);
request.put('grid',gridString);
disp(['Requested grid = ',gridString]);


request.put('time','00/06/12/18');

areaString = generateAreaString(lims);
request.put('area',areaString);
disp(['Requested area = ',areaString]);


dateString = generateDateString(lims);
request.put('date',dateString);
disp(['Requested date = ',dateString]);



request.put('class','ei');
request.put('target',target);
disp(['Target file = ',target]);


if ~exist(convertedTarget,'file')
    server.retrieve(request);
    
end

clear server request;
args = javaArray ('java.lang.String', 2);
args(1) =java.lang.String(target);
args(2) =java.lang.String(convertedTarget);
ucar.grib.Grib2Netcdf.main(args);


fPath = convertedTarget;


    function fPref = generateFileName(lims,hres)
        fPref =['downloads',filesep];
        dta = [lims;hres];
        for i = 1:size(dta,1)
            
            for j = 1:2
                
                fPref = [fPref,num2str(dta(i,j))];
                
                if i<size(dta,1)
                    if j==1
                        fPref = [fPref,'-'];
                    else
                        
                        fPref = [fPref,'_'];
                    end
                    
                end
                
            end
            
        end
        
        
    end


    function dateString = generateDateString(lims)
        
        formatOut = 'yyyy-mm-dd';
        dateString = [datestr(lims(4,1),formatOut),'/to/',datestr(lims(4,2),formatOut)];
        
        
    end


    function gridString = generateGridString(hres)
        
        gridString = [num2str(hres(1)),'/',num2str(hres(2))];
        
    end


    function areaString = generateAreaString(lims)
        lats = lims(2,:);
        lons = lims(1,:);
        
        %Area specified in [North,West,South,East] format
        
        areaString=[num2str(lats(2)),'/',num2str(lons(1)),'/',num2str(lats(1)),'/',num2str(lons(2))];
    end


    function levString = generateLevString(lims)
        
        levString = '';
        levLims = lims(3,:);
        
        for i =1:length(levLst)
            
            levVal = levLst(i);
            
            if(levVal>=min(levLims) && levVal<=max(levLims))
                
                startChar = '/';
                
                if strcmp(levString,'')
                    
                    startChar = '';
                end
                
                
                levString = [levString,startChar,num2str(levVal)];
                
            end
        end
        
    end


    function levLst = generateLevList()
        
        levLst = zeros(1,37);
        
        ix = 1;
        
        for i = 1000:-25:750
            levLst(ix)=i;
            ix = ix+1;
            
        end
        
        for i = 700:-50:250
            levLst(ix)=i;
            ix= ix+1;
        end
        
        for i = 225:-25:100
            levLst(ix)=i;
            ix = ix+1;
        end
        
        levLst(ix:end)=[70 50 30 20 10 7 5 3 2 1];
        
        
    end


end

