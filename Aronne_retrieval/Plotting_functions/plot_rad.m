function [ h ] = plot_rad( wn,fxhat,obs,se,plType,bt )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

    function [vardata]  = convertVarData(wn, rad, obs, plType, btflg)
        
        vardata = rad;
        obsin = obs;
        
        if btflg
            
            obsin = convertToBT(obs,wn);
            vardata = convertToBT(rad,wn);
        end
        
        if plType == 1
            
            vardata = vardata-obsin;
            
        elseif plType ==2
            
            vardata = 100.0*(vardata-obsin)./obsin;
            
        end
        
    end


p = zeros(1,length(fxhat)+2);
legString = cell(length(p),1);

p(1) = plot(wn,convertVarData(wn,obs,obs,plType,bt),'--k');
legString{1}='Observation';

xlim([min(wn) max(wn)]);
xlabel('Wavenumber (cm^-^1)','fontsize',12);

prefix = 'Radiance';
units = '(W/[cm^2 sr cm^-^1])';
mid = '';


if bt
    prefix = 'Brightness temperature';
    units = '(K)';
    
end

if plType == 1||plType ==2,
    
    mid = 'difference';

end

if plType ==2,
    
    units = '(%)';
    
end

ylabtext = [prefix,' ',mid,' ',units];
ylabel(ylabtext,'fontsize',12);


hold on;
exclList = {'-','--','-.','k','b','g','+','o','*','.','x','s','d','^','v','>','<','p','h'};

for i = 1:length(fxhat)
    
    lnstle  = generateLineSpec(i,exclList);
    
    if i==length(fxhat)
        lnstle = '-k';
        legString{i+1}='Final';
        
    elseif i==1
        lnstle = '-r';
        legString{i+1}='Initial';
        
    else
        legString{i+1}=['Iteration ',num2str(i)];
    end
    
    p(i+1)=plot(wn,convertVarData(wn,fxhat{i},obs,plType,bt),lnstle);
    
    
    
    
end


sediag =  diag(se);
sevar = sqrt(sediag);

maxsevar = obs+sevar;
minsevar = obs-sevar;

p(length(fxhat)+2)=plot(wn,convertVarData(wn,minsevar,obs,plType,bt),'-b');
p(length(fxhat)+3)=plot(wn,convertVarData(wn,maxsevar,obs,plType,bt),'-b');
legString{length(fxhat)+2}='Observation variance';


hold off;

hdls = p(1:length(fxhat)+2);

legend(hdls,legString,'location','best'); 

%legend(hdls,'Observation','Prior','Iterations','Final','Observation variance','location','best'); 


h=0;


    function [bt] = convertToBT(rad,wn)
        %Convert to /m
        r = rad*100.0;
        v = wn*100.0;
        
        bt = rToBT(r,v);
        
    end

   



end

