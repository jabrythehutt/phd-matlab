function [profile ] = calculateProfile( standardAtm, altitudeGrid, molecules )
%Find the profile for the standard atmosphere with specified altitude grid
% and molecules 

profile =[];


profile.alt = altitudeGrid;
profile.pres = zeros(size(altitudeGrid));
profile.tdry = zeros(size(altitudeGrid));

hObs = profile.alt(end);
hEnd = profile.alt(1);
angle = 180;



if ~exist('molecules','var')
    
    molecules = true(1,39);
    
end

cleanup_flag = false;
vbound = [100, 100.05];
lblArgs = {};
lblArgs{1} = 'MOLECULES';
lblArgs{2} = molecules;
lblArgs{3} = 'HBOUND';
lblArgs{4} = [hObs,hEnd,angle];
lblArgs{5} = 'TUNIT';
lblArgs{6} = standardAtm;
lblArgs{7} = 'PUNIT';
lblArgs{8} = standardAtm;

[wavenum, rad, tau, lblrtm_success, tmp_work_dir]...
    =simple_matlab_lblrun(cleanup_flag,standardAtm,profile,vbound,lblArgs{:});

profile = [];
if lblrtm_success
    
   profile =  extractProfileFromTAPE7([tmp_work_dir,filesep,'TAPE7']);
   unix(['rm -fR ' tmp_work_dir]);
end



end

