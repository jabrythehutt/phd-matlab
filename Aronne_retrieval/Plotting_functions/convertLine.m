function [ h] = convertLine( fileNames,prefix )

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
                lwProp = 'LineWidth';
                lw = get(hl,lwProp);
                
                if(lw<2.0)
                    
                    lwToSet= lw*10;
                end
                set(hl,lwProp,lwToSet);
                
            catch ex
                
            end
            
            
            try
                fs = get(hl,'FontSize');
                if(fs<20)
                    
                    fs = fs*4;
                    
                end
                
 
                set(hl,fSProp,fs);

            catch ex
                
            end
            
            try
                
               whitebg('black');
            catch ex
                
            end
            
%             try
%                 
%                 for j = 1:length(blackProps)
%                      blkProp = blackProps{j};
%                      set(hl,blkProp,'w');
%                     
%                 end
%                 
%             catch ex
%                 
%                 
%                 
%             end
            
            
        end
        
        
        
        set(a,'Color','k');
        saveas(a,[prefix,fileName],'fig');
        
        
    end


end

