function [h ] = plotHatS(path,plotType,multiplier,suffix,lgy,altPres)

if exist('path','var')==0
    
    path = pwd;
    
end

if exist('lgy','var')==0
   
    lgy=false;
end

if exist('altPres','var')==0
   
    altPres = true;
end

if exist('plotType','var')==0
    
    plotType =0;
    
end

if exist('suffix','var')==0
   
    suffix = '';
end

if exist('multiplier','var')==0
    
    multiplier =1;
    
end


%path = path to directory containing saved result files
%plotType: 0 = errors in terms of mr units
%plotType: 1 = errors in terms of percent deviation from truth

h=0;
variance = [];
varVals = [];
altVec = [];
stateError = [];
truthProf = [];

listing = dir(path);
for i = 1:length(listing)
    
    nameStr = listing(i,1).name;
    
    if strncmp(nameStr,'results_',8)
        vars  = load(nameStr);
        
        if(isempty(altVec))
            
             altVec = vars.profile.alt;
            
            if altPres
                altVec = vars.profile.pres;
            end
           
            
        end
        if isempty(truthProf)
            
            truthProf = vars.truth_profile.h2o;
            
        end

        vrce = diag(vars.hatS);
        vrce = vrce(length(vars.profile.alt)+1:end);
        vrce = exp(sqrt(vrce))-1;
        
        
        
        retrievedState = exp(vars.xhat_final(length(vars.profile.alt)+1:end));
        
        
        
        
        errs = retrievedState-truthProf;
        

        if plotType==1
            
          
            errs = 100*errs./truthProf;
            vrce = 100.0*vrce;
            
        else
            
            vrce = vrce.*retrievedState;
            
        end
        
        variance = [variance,vrce];
        
        stateError =[stateError,errs];
        
        varStr = strrep(nameStr,'results_','');
        varStr = strrep(varStr,'.mat','');
        varVal = str2double(varStr);
        varVals = [varVals,varVal];

    end
    
end 

[varVals,ix]=sort(varVals);

stateError=stateError(:,ix);
variance = variance(:,ix);
xlbl = 'H2O mixing ratio (g/Kg)';

if plotType ==1
   
    xlbl = 'Mixing ratio error (%)';
end

figure;


plotVecs(variance,altVec,2);


altLabel = 'Altitude (Km)';

if altPres
   altLabel = 'Pressure (mb)'; 
end
 xlabel(xlbl,'fontsize',12);
 ylabel(altLabel,'fontsize',12);
 title('Retrieval variance','fontsize',13);
 
 legList = cell(length(varVals),1);
 %legString = 'legend(';
 for i = 1:length(varVals)
     
     
     val = multiplier*varVals(i);
     valStr  = num2str(val);

     legList{i}=[valStr,suffix];
     
     %legString  = [legString,'''',num2str(multiplier*varVals(i)),suffix,''','];
     
     
 end
 
 %legString = [legString,'''location'',''EastOutside'')'];
 %disp(legString);
 %eval(legString);
 
 legend(legList,'location','EastOutside');
 ylim([vars.profile.alt(1),vars.profile.alt(end)]);



figure;
plotVecs(stateError,altVec,2);
xlabel(xlbl,'fontsize',12);        
ylabel(altLabel,'fontsize',12);
title('Retrieved state','fontsize',13);
ylim([vars.profile.alt(1),vars.profile.alt(end)]);
 
    function hl = plotVecs(vecs1,vecs2,dim)
        
        hl = -1;
        stlIx = 1;
        
        for k = 1:size(vecs1,dim)
            
            for m = 1:size(vecs2,dim)
                
                
                if dim==2
                    vec1 = vecs1(:,k);
                    vec2 = vecs2(:,m);
                else
                    
                    vec1 = vecs1(k,:);
                    vec2 = vecs2(m,:);
                    
                end
                
                lstl = generateLineSpec(stlIx);
                
                if hl==-1
                    
                    
                    if lgy
                        hl = semilogy(vec1,vec2,lstl);
                    else
                         hl = plot(vec1,vec2,lstl); 
                        
                    end
                    
                    if altPres
                        
                        set(gca,'YDir','reverse');
                        
                    end
                   
                    hold on;
                    
                else
                    
                    
                    if lgy
                        hl = semilogy(vec1,vec2,lstl);
                    else
                         hl = plot(vec1,vec2,lstl); 
                        
                    end 
                    
                end

                stlIx = stlIx+1;
            end
            
        end
        
        hold off;
        
    end


end

