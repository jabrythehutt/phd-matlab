%Test plotting of channel selection 

fileNameStructs = dir;
relIx = false(size(fileNameStructs));
fileNames = cell(size(fileNameStructs));
atmNames = containers.Map();
atmNames('1')='Tropical';
atmNames('2') = 'Mid-latitude summer';
atmNames('5')='Sub-arctic winter';
fileNamesByAtm = containers.Map();


atmTrop = containers.Map();
atmTrop('Tropical') = 15.7;
atmTrop('Mid-latitude summer') = 12.93;
atmTrop('Sub-arctic winter') = 8.95;

utdepth = 3;

for i = 1:length(fileNameStructs)
    
    fNameStruct = fileNameStructs(i);
    
    fName = fNameStruct.name;

    if length(fName)>6
        
        if strcmpi(fName(end-5:end),'cs.mat')&&strcmpi(fName(1:4),'atm-')

            relIx(i)=true;
            fileNames{i}=fName;
            atmNum = fName(5:5);
            atmName = atmNames(atmNum);
            
            if ~isKey(fileNamesByAtm,atmName)
                fileNamesByAtm(atmName)= cell(0);
            end
            
            fileNamesByAtm(atmName) = [fileNamesByAtm(atmName),{fName}];
        end
        
        
    end
    
end

fileNames = fileNames(relIx);

ks = keys(fileNamesByAtm);

allFigs = zeros(1,length(ks));
allAxs = zeros(size(allFigs));
%clrBars = zeros(size(allFigs));
fomLims = zeros(1,2);


for i = 1:length(ks)
    atmName = ks{i};
    fNames = fileNamesByAtm(ks{i});
    [figH,axH,fLims,obsAlts,wn]=plotCS2(fNames,atmName); 
    trop = atmTrop(atmName);
    
%     for j = 1:2
%         
%         ax = axH(j);
%         
%         ylim(ax,[0 20]);
%         line([wn(1),wn(end)],[trop,trop],'Parent',ax,'Color','g','LineStyle','--','LineWidth',1);
%         line([wn(1),wn(end)],[trop-utdepth,trop-utdepth],'Parent',ax,'Color','g','LineStyle','--','LineWidth',1);
%         
%     end

    fomLims(1)=  min([fLims(1),fomLims(1)]);
    fomLims(2) = max([fLims(2),fomLims(2)]);
    
    allAxs((2*(i-1))+1:2*i)=axH;
    
    %clrBars((2*(i-1))+1:2*i)=cBarH;
    
end

for i = 1:length(allAxs)
    
    
    %ax = allAxs(i);
    %set(ax,'CLim',fomLims);
    
    
    
    %colorbar(ax);
    
    
    
    
end



