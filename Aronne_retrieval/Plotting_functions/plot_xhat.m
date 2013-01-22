function [h] = plot_xhat(xhat,truth_wvap,truth_temp,pressureVec,sa,hats,errType)


    function pcErr=  processVec(vec,truth)
        
        pcErr = vec;
        if errType==2
            pcErr = 100*((vec-truth)./truth);
            
        elseif errType ==1,
            pcErr = vec-truth;
        end
        
    end

    function vec = convertVariance(variableName,fg,diag)

        vec = sqrt(diag);
        
        if isWV(variableName)
            
           vec = exp(vec);
           vec = vec.*fg;
           vec = vec-fg;

        end
  
    end

if ~exist('errType','var')
    
    errType = 0;
    
end

vars = {'Temperature', 'Water vapour'};



xaxes = {'Error (%)','Error (%)'};

if errType==0 
   
    xaxes = {'Temperature (K)','Water vapour mixing ratio (g/Kg)'};
elseif errType == 1
    
    xaxes = {'Temperature error (K)','Water vapour mixing ratio error (g/Kg)'};
    
elseif errType ==2
        
     xaxes = {'Error (%)','Error (%)'};   
    
    
end


yaxes = {'Pressure (mb)', 'Pressure (mb)'};
nlevels = length(pressureVec);


    function tf = isWV(var)
        
        tf = strcmpi(var,vars{2});
    end
legStr = cell(length(xhat)+3,1);

for i = 1:length(vars),
    
    var =vars{i};
    
    
    %First guess
    fg = xhat{1}((i-1)*nlevels+1:i*nlevels);
    
    %Trurh
    tr = truth_temp;
    
    if isWV(var),
        
        tr = truth_wvap;
        fg = exp(fg);
    end
    
    h=subplot(120+i);
    
    p=zeros(1,length(xhat)+5);
    
    
    
    p(1)=xhatplot(var,processVec(fg,tr),pressureVec,'-r');
    
    legStr{1}='Apriori';
    
    ylim([min(pressureVec) max(pressureVec)]);
    
    xlabel(xaxes{i},'fontsize',12);
    
    if i==1,
        ylabel(yaxes{i},'fontsize',12);
    end
    
    
    title(var,'fontsize',13);
    set(gca,'YDir','reverse');
    
    hold on;
    
    p(2) = xhatplot(var,processVec(tr,tr),pressureVec,'-.k');
    legStr{2}='Truth';
    
    ivarDiag = diag(sa);
    ivarDiag = ivarDiag((i-1)*nlevels+1:i*nlevels);
    ivarVals = convertVariance(var,fg,ivarDiag);
    
    iminVarLim = fg-ivarVals;
    imaxVarLim = fg+ivarVals;
 
    exclList = {'-','--','-.','k','b','g','+','o','*','.','x','s','d','^','v','>','<','p','h'};
    
    for j = 2:length(xhat),
        
       
        lstle = generateLineSpec(j,exclList);
        
        
        if j==length(xhat)
            
            lstle = '-k';
        end
        %disp(lstle);
        
        vardata =xhat{j}((i-1)*nlevels+1:i*nlevels);
        
        
        if isWV(var),
            
            vardata =exp(vardata);
            
            
        end
        
        
        p(j+1)=xhatplot(var,processVec(vardata,tr),pressureVec,lstle);
        legStr{j+1} = ['Iteration ',num2str(j-1)];
        
        if j==length(xhat)
            
             legStr{j+1} = 'Retrieved';
        end
        
        
        if j==length(xhat),
            
            %Process final and initial variance values for plotting
            fvarDiag = diag(hats);
            
            
            
            
            fvarDiag = fvarDiag((i-1)*nlevels+1:i*nlevels);
            
            fvarVals = convertVariance(var,fg,fvarDiag);

            fminVarLim = vardata-fvarVals;
            fmaxVarLim = vardata+fvarVals;

            
            p(j+4)=xhatplot(var,processVec(fminVarLim,tr),pressureVec,'-g');
            p(j+5)=xhatplot(var,processVec(fmaxVarLim,tr),pressureVec,'-g');
            
            legStr{j+2} = 'Prior variance';
            legStr{j+3} = 'Retrieval variance';
            
            p(j+2)=xhatplot(var,processVec(iminVarLim,tr),pressureVec,'-b');
            p(j+3)=xhatplot(var,processVec(imaxVarLim,tr),pressureVec,'-b');
            
        end
        
        
    end
    
    
    hold off;
    
    hdls = [p(1:length(xhat)+2),p(end)];
    
    if i<2
        legend(hdls,legStr,'location','Best');
    end
    
end


    function h = xhatplot(varName,x,y,stle)
        
        if isWV(varName)&&errType==0,
            
            h=plot(x,y,stle);
            
        else
            h=plot(x,y,stle);
            
        end
        
    end
end