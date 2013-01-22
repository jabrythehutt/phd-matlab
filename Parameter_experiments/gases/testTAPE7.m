%Create test run to interpret TAPE7 data
setenv('LBL_HOME','/home/dj104/lblrtm/LBL_HOME');

% pathToProfile = '/home/dj104/Retrieval/Aronne_retrieval/Profiles/MIDLATITUDE_SUMMER.csv';
% prof = readCSVProfile(pathToProfile);
% 
% hObs = 8.0;
% endH = profile.alt(end);
% angle = 0.0;
% 
% startWn = 100;
% endWn = 150;
% dv =1;
% 
% 
% extraArgs = cell(1);
% extraArgs{1} = 'HBOUND';
% extraArgs{2} = [hObs, endH,angle];
% extraArgs{3} = 'MOLECULES';
% extraArgs{4} = true(1,29);
% 
% 
% vbound  = [startWn endWn];
% 
% cleanup_flag = false;
% [wavenum, rad, tau, lblrtm_success, tmp_work_dir]...
%     =simple_matlab_lblrun(cleanup_flag,2,prof,vbound,extraArgs{:});
% 
% layerdata = read_tape7([temp_work_dir,'/TAPE7']);


profile = calculateProfile(1,linspace(0,50,20),true(1,29));

disp('finished');




