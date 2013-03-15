function [ h ] = plotCovarianceProfile( cov_prof,unit_map)

%Display all the 2d covariance plots in a cov-prof structure
%unit_map is a map containing the LBLRTM units relating to each parameter


allFields = fieldnames(cov_prof);
pressVec= cov_prof.pres;

uNameMap = containers.Map();

uNameMap('A')='ppmv';
uNameMap('H')='RH %';
uNameMap('C')= 'g/Kg';
uNameMap('B')='cm^-^3';

for i = 1:length(allFields)
    
    fldName = allFields{i};
    val = getfield(cov_prof,fldName);
    sze = size(val);
    %If it is a square matrix
    if length(sze)==2
        
        if sze(1)==sze(2)
            
            figure;
            h = pcolor(pressVec,pressVec,val);
            shading flat;
            xlabel('Pressure (mb)','Fontsize',12);
            ylabel('Pressure (mb)','Fontsize',12);
            uName = uNameMap(unit_map(fldName));
            fldName = upper(fldName);
            if strcmpi(fldName,'tdry')
                uName = 'K';
                fldName = 'Temperature';
            end
            
            title([fldName,' covariance (',uName,')'],'Fontsize',13);
            set(gca,'YDir','reverse');
            set(gca,'XDir','reverse');
            colorbar;
        end
        
    end
    
    
    
end 
end

