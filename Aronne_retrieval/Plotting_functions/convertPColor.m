function [ h ] = convertFigure( fileNames,prefix)
%CONVERTFIGURETOCOLOURSCHEME Summary of this function goes here
%   Detailed explanation goes here

if exist('prefix','var')==0
    
    prefix = 'tr_';
end


if ~iscell(fileNames)
    
    fileNames = {fileNames};
    
end


for i = 1:length(fileNames)
    
    fileName = fileNames{i};
    
    h=transformFigure(fileName);
    
    
end




    function a = transformFigure(fileName)
        
        a=open(fileName);
        
        blackProps = {'Color','XColor','YColor'};
        fSProp = 'FontSize';
        handle_list = findall(a);
        
        for l = 1:length(handle_list)
            
            
            hl = handle_list(l);
            
            
            try
                fs = get(hl,'FontSize');
                if(fs<20)
                     fs = fs*2;
                    
                end
               
                set(hl,fSProp,fs);
                
                

            catch ex
                
            end
            
            try
                
                for j = 1:length(blackProps)
                     blkProp = blackProps{j};
                     set(hl,blkProp,'w');
                    
                end
                
            catch ex
                
                
                
            end
            
            
        end
        
        
        
        set(a,'Color','k');
        saveas(a,[prefix,fileName],'fig');
        
        
    end


end

