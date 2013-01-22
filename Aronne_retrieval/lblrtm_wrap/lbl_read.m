function [data] = lbl_read(filename,pflag,force_file_type)

%
% function [data] = lbl_read(filename,pflag,force_file_type);
%
% Read in an LBLRTM TAPE12 file (which is an f77 unformatted sequential
% recond binary file).
%
% This was adpopted directly from PvD's lbl_read.pro.
% It should now automatically detect single vs. double panel files, but 
% does not auto detect the endian-ness of the file (as lbl_read.pro does).
%
% Inputs: filename - name of TAPE12 file to read. If not specified, 
%            a uigetfile() is spawned to get a file name from the user.
%         pflag - status flag: 1 to show status while reading in a GUI 
%            widget; set to 0 to not show status. Default is 1, so if 
%            pflag is not specified you get a GUI status widget.
%         force_file_type - Only use this flag is the automatic detection of 
%            single vs. double panel does not work. Note, that the field 
%            might be miscorrectly named "od" when it is really "rad", etc.
%
%       Since there is zero documentation on what is actually in these 
%       LBLRTM files, here is my educated guess based on the structures 
%       read in from lbl_read.pro:
%       If file_header.LBL_ID.EM=0, then this is a Optical depth file, so 
%       if will be a single panel with just OD data.
%       If EM=1, then radiance was calculated. There appear to be two
%       possibilities: if scnid is -99, then it is a double panel
%       with radiance, then transmission. If scnid is not -99, then it is a
%       single panel, with unknown contents (it is an interpolation or FFT 
%       scan of radiance, or transmission, but there appears to be no way
%       to determine this from inside the file.) So for now, just letting
%       this get called "od", though it is really either "rad" or "tau".
%
% Outputs: data - a structure containing all the TAPE12 data
%
%	data.filename		name of tape12 file
%	data.file_header	misc info [structure]
%	data.file_type		single or double panel
%	data.n_panels		# panels read
%	data.n_pts_read		# spectral points read
%	data.panel_header	panel header info [cell]
%	data.v1			min wavenumber (exact)
%	data.v2			max wavenumber (exact)
%	data.v			wavenumbers (exact) - array with N elements.
%
% If the file is a single panel, the rest of the structure will have:
%   data.od     optical depths - array (same length as v)
%
% If the file is a double panel the rest of the file will have:
%	data.rad    radiances - array (same length as v)
%	data.tau    observer to source transmission -array (same length as v)
%
% DCT 9/5/97
% A. Merrelli Jul 2009:
%   -- joined lbl_read and lbl_read2 - so, this function 
%      will now detect and read "single panel" and "double" panel LBLRTM 
%      output files.
%   -- Also cleaned up the pflag code, to make sure the figure is 
%      correctly suppressed when pflag = 0.
%   -- Corrected EOF tests - doesn't return an empty panel header, and 
%      exits correctly now instead of attempting to read another panel 
%      at EOF.
%
% A. Merrelli Jan 2010
%   -- lots of mods, for 64 bit files, and extra junk data that appears on
%      some machines (possibly due to the 64 bit CPU). Basically, added a
%      helper function that attempts to figure out the file layout.
%

if ~exist('pflag','var')
  pflag = 1;
end

if pflag
h = uicontrol;
set(gcf,'Position',[400 400 350 60],'Color',[0 0 0],...
	'NumberTitle','off','MenuBar','none')
set(h,'Units','normalized','Position',[.05 .1 .9 .8],...
	'BackGroundColor',[.8 .8 .5],'FontSize',16,'FontWeight','b')
set(h,'String','lbl_read.m');drawnow;pause(0.5)
end

% specify filename if not defined
if nargin == 0;
	[filename,pathname] = uigetfile('*');
	filename = [pathname filename];
end

% open the file as read only and binary format
fid = fopen(filename,'rb');

% attempt to determine file format. If it fails, exit immediately
[junk_data_size, default_float_type, default_int_type] = ...
    lbl_read_determine_file_type(fid);
if junk_data_size < 0
    data = 0;
    fclose(fid);
    return
end

data.filename = filename;clear filename
if pflag
set(h,'String',['file: ' '' data.filename '' ' opened']);drawnow;pause(0.5)
end

%-----------------------------------------------------------------------
%  read in file_header
%-----------------------------------------------------------------------
if pflag
set(h,'String','reading file header');drawnow;pause(0.5)
end

fread(fid,junk_data_size,'uchar');
data.file_header.user_id = setstr(fread(fid,80,'uchar'))';
data.file_header.secant = fread(fid,1,'float64');
data.file_header.p_ave = fread(fid,1,default_float_type);
data.file_header.t_ave = fread(fid,1,default_float_type);

molecule_id = zeros(64,8);
for i = 1:64;molecule_id(i,:) = fread(fid,8,'uchar')';end
data.file_header.molecule_id = setstr(molecule_id);
data.file_header.mol_col_dens = fread(fid,64,default_float_type);
data.file_header.broad_dens = fread(fid,1,default_float_type);
data.file_header.dv = fread(fid,1,default_float_type);
data.file_header.v1 = fread(fid,1,'float64');
data.file_header.v2 = fread(fid,1,'float64');
data.file_header.t_bound = fread(fid,1,default_float_type);
data.file_header.emis_bound = fread(fid,1,default_float_type);
data.file_header.LBL_id.hirac = fread(fid,1,default_int_type);
data.file_header.LBL_id.lblf4 = fread(fid,1,default_int_type);
data.file_header.LBL_id.xscnt = fread(fid,1,default_int_type);
data.file_header.LBL_id.aersl = fread(fid,1,default_int_type);
data.file_header.LBL_id.emit = fread(fid,1,default_int_type);
data.file_header.LBL_id.scan = fread(fid,1,default_int_type);
data.file_header.LBL_id.plot = fread(fid,1,default_int_type);
data.file_header.LBL_id.path = fread(fid,1,default_int_type);
data.file_header.LBL_id.jrad = fread(fid,1,default_int_type);
data.file_header.LBL_id.test = fread(fid,1,default_int_type);
data.file_header.LBL_id.merge = fread(fid,1,default_int_type);
data.file_header.LBL_id.scnid = fread(fid,1,default_float_type);
data.file_header.LBL_id.hwhm = fread(fid,1,default_float_type);
data.file_header.LBL_id.idabs = fread(fid,1,default_int_type);
data.file_header.LBL_id.atm = fread(fid,1,default_int_type);
data.file_header.LBL_id.layr1 = fread(fid,1,default_int_type);
data.file_header.LBL_id.nlayr = fread(fid,1,default_int_type);
data.file_header.n_mol  = fread(fid,1,default_int_type);
data.file_header.layer = fread(fid,1,default_int_type);
data.file_header.yi1 = fread(fid,1,default_float_type);
yid = zeros(10,8);
for i = 1:10;yid(i,:) = fread(fid,8,'uchar')';end
data.file_header.yid = setstr(yid(1:7,:));
% read in 4 (or 8) bytes before and after every record 
fread(fid,junk_data_size,'uchar');

clear molecule_id yid i

% check for 3rd argument - forces the file type. 
% 1 implies single panel, 2 implies double panel. If the input was not 
% 1 or 2, then set back to auto.
if nargin > 2
    auto_detect_file_type = 0;
    switch force_file_type
        case 1
            auto_detect_file_type = 0;
            data.file_type = 'SINGLE';
        case 2
            auto_detect_file_type = 0;
            data.file_type = 'DOUBLE';
        otherwise, auto_detect_file_type = 1;
    end
else
    auto_detect_file_type = 1;
end

% for auto - just check the value of EM.
if auto_detect_file_type
    if data.file_header.LBL_id.emit == 0
        data.file_type = 'SINGLE';
    else
        data.file_type = 'DOUBLE';
    end
end

% Estimate number of spectral points and initialize arrays
n_pts_estimate=ceil((data.file_header.v2-data.file_header.v1)/data.file_header.dv +1.5);
switch data.file_type
    case 'SINGLE'
        optdepth = zeros(n_pts_estimate,1);
    case 'DOUBLE'
        radiance = zeros(n_pts_estimate,1);
        transmission = zeros(n_pts_estimate,1);
end

%-----------------------------------------------------------------------
%  read data panel by panel
%-----------------------------------------------------------------------

% initialize counters
data.n_panels = 0;
data.n_pts_read = 0;

% While not end-of-file, read the next panel

while feof(fid) == 0

    % --------------------------------------------------------
    % read in panel header
    % --------------------------------------------------------

    % read in 4 (or 8) bytes before and after every record
    fread(fid,junk_data_size,'uchar');

    % read in panel header - put these in temporary variables, since 
    % it appears that this might not be a valid panel (LBLRTM may 
    % output a panel header with -99 for the number of points, which 
    % should indicate an empty panel, presumably.)
    tmp_panel_header_v1 = fread(fid,1,'float64');
    tmp_panel_header_v2 = fread(fid,1,'float64');
    tmp_panel_header_dv = fread(fid,1,default_float_type);
    tmp_panel_header_np = fread(fid,1,default_int_type);

    % read in 4 (or 8) bytes before and after every record
    fread(fid,junk_data_size,'uchar');

    % --------------------------------------------------------
    % read current panel data
    % --------------------------------------------------------

    if tmp_panel_header_np ~= -99

        % valid panel, so store the panel header information.
        data.panel_header.v1{data.n_panels+1} = tmp_panel_header_v1;
        data.panel_header.v2{data.n_panels+1} = tmp_panel_header_v2;
        data.panel_header.dv{data.n_panels+1} = tmp_panel_header_dv;
        data.panel_header.n_pts{data.n_panels+1} = tmp_panel_header_np;
        
        if pflag
            if fix((data.n_panels+1)/50)-(data.n_panels+1)/50 == 0
                set(h,'String',['reading panel # ' num2str(data.n_panels+1) ]);
                drawnow
            end
        end

        switch data.file_type

            case 'SINGLE'
                fread(fid,junk_data_size,'uchar');
                od = validateread(fid,data.panel_header.n_pts{data.n_panels+1},default_float_type);
                fread(fid,junk_data_size,'uchar');
                pt1 = data.n_pts_read + 1;
                pt2 = data.n_pts_read + data.panel_header.n_pts{data.n_panels+1};
                optdepth(pt1:pt2) = od;
                clear od

            case 'DOUBLE'
                fread(fid,junk_data_size,'uchar');
                rad = validateread(fid,data.panel_header.n_pts{data.n_panels+1},default_float_type);
                fread(fid,junk_data_size,'uchar');
                fread(fid,junk_data_size,'uchar');
                tau = validateread(fid,data.panel_header.n_pts{data.n_panels+1},default_float_type);
                fread(fid,junk_data_size,'uchar');

                pt1 = data.n_pts_read + 1;
                pt2 = data.n_pts_read + data.panel_header.n_pts{data.n_panels+1};
                radiance(pt1:pt2) = rad;
                transmission(pt1:pt2) = tau;
                clear rad tau

        end % of switch (single or double panel)

        % increment number of points read
        data.n_pts_read = data.n_pts_read + ...
            data.panel_header.n_pts{data.n_panels+1};

        % increment panel number
        data.n_panels = data.n_panels +1;

    end
end  % on end-of-file while loop




if pflag
set(h,'String','close file and return data');drawnow
end

switch data.file_type
    case 'SINGLE'
        data.od = optdepth(1:data.n_pts_read);
    case 'DOUBLE'
        data.rad = radiance(1:data.n_pts_read);
        data.tau = transmission(1:data.n_pts_read);
end
data.v1 = data.panel_header.v1{1};
data.v2 = data.panel_header.v2{data.n_panels};
data.v = linspace(data.v1,data.v2,data.n_pts_read)';

fclose(fid);

if pflag
  close(gcf)
  drawnow
end

%
% REVISION INFORMATION (RCS Keyword):
%   $Id: lbl_read.m,v 1.1 2009/07/02 17:11:59 reholz Exp $
%
%REVISION INFORMATION (RCS Keyword variable)
%------------------------------------------------------------------------------
rcs_id =  '$Id: lbl_read.m,v 1.1 2009/07/02 17:11:59 reholz Exp $' ;


function [data]=validateread(fileid,arg2,datatype)

    data = fread(fileid,arg2,datatype);
    
    for i=1:length(data)
       
        testVal = data(i);
        if isnan(testVal)
           data(i)=0.0; 
        end
        
    end
    
    


%------------------------------------------------------------------------------
%
% EXPANDED REVISION INFORMATION (RCS Keywords):
%
%   $Id: lbl_read.m,v 1.1 2009/07/02 17:11:59 reholz Exp $
%   $Author: reholz $
%   $Log: lbl_read.m,v $
%   Revision 1.1  2009/07/02 17:11:59  reholz
%   functions reads the the tape 12 file from lblrtm
%
%   Revision 1.3  2001/04/09 16:22:14  davet
%   fixed cvs keyword variable "rcs_id"
%
%   Revision 1.2  2001/04/09 16:11:18  davet
%   added cvs keywords to all files.
%
%   $Locker:  $ 
%
%------------------------------------------------------------------------------


function [junk_field_length, default_float_type, default_int_type] = ...
    lbl_read_determine_file_type(fid)
%
% this is a helper function to attempt to determine the file format of the
% LBLRTM binary panel file.
%
% This is a horrible section of code, because the LBLRTM doesn't appear to
% produce any meta data about its own format, so we will attempt to read
% the file in a couple different ways and hope that one works. If it
% doesn't, throw a stop error, since this function isn't going to work.
%
% the 4 possibilities are:
%
% file_type 1: Junk fields are 4 bytes., default floats are 32 bit.
% file_type 2: Junk fields are 4 bytes, default floats are 64 bit.
% file_type 3: Junk fields are 8 bytes, default floats are 32 bit.
% file_type 4: Junk fields are 8 bytes, default floats are 64 bit.
%
% It is possible that file types 3 & 4 are solely due to gfortran compiler
% problems on 64 bit linux. From my limited experience attempting to
% compile LBLRTM on a few machines:
% Using the Intel ifort compiler produces files of type 1 or 2 only. 
% Using gfortran on 32 bit Mac OS X produces file type 1 (have been unable
% to compile it with default double precision).
% Using f77 on 32 bit linux produces file type 1.
% Using gfortran on 64 bit linux produces file type 3 and 4.

% these types are simply attempted, in a serial fashion. If one produces
% valid numbers, then return the corresponding parameters. if we reach the
% end of the function (meaning all 4 were tried), then return an error.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Try case 1 reads, then rewind the file.
junk = fread(fid,4,'uchar');
test_user_id = fread(fid,80,'uchar');
test_secant = fread(fid,1,'float64');
test_p_average = fread(fid,1,'float32');
test_t_average = fread(fid,1,'float32');
fseek(fid,0,'bof');

% check for sensible values for the average Pressure and Temperature.
% they will be in hPa and K, respectively. Will give a wide range here, 
% just in case someone is trying something 'non-standard'.
valid_nums = (test_p_average > 1e-4) & (test_p_average < 1e4) & ...
    (test_t_average > 100) & (test_t_average < 400);
% if it was valid, set the field types and exit the function here.
if valid_nums
    junk_field_length = 4;
    default_float_type = 'float32';
    default_int_type = 'int32';
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Repeat for case 2, then rewind the file.
junk = fread(fid,4,'uchar');
test_user_id = fread(fid,80,'uchar');
test_secant = fread(fid,1,'float64');
test_p_average = fread(fid,1,'float64');
test_t_average = fread(fid,1,'float64');
fseek(fid,0,'bof');

valid_nums = (test_p_average > 1e-4) & (test_p_average < 1e4) & ...
    (test_t_average > 100) & (test_t_average < 400);
if valid_nums
    junk_field_length = 4;
    default_float_type = 'float64';
    default_int_type = 'int64';
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Repeat for case 3, then rewind the file.
junk = fread(fid,4,'uchar');
junk = fread(fid,4,'uchar');
test_user_id = fread(fid,80,'uchar');
test_secant = fread(fid,1,'float64');
test_p_average = fread(fid,1,'float32');
test_t_average = fread(fid,1,'float32');
fseek(fid,0,'bof');

valid_nums = (test_p_average > 1e-4) & (test_p_average < 1e4) & ...
    (test_t_average > 100) & (test_t_average < 400);
if valid_nums
    junk_field_length = 8;
    default_float_type = 'float32';
    default_int_type = 'int32';
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Repeat for case 4, then rewind the file.
junk = fread(fid,4,'uchar');
junk = fread(fid,4,'uchar');
test_user_id = fread(fid,80,'uchar');
test_secant = fread(fid,1,'float64');
test_p_average = fread(fid,1,'float64');
test_t_average = fread(fid,1,'float64');
fseek(fid,0,'bof');

valid_nums = (test_p_average > 1e-4) & (test_p_average < 1e4) & ...
    (test_t_average > 100) & (test_t_average < 400);
if valid_nums
    junk_field_length = 8;
    default_float_type = 'float64';
    default_int_type = 'int64';
    return
end
    
% Should only get to this point if all read attempts failed.
% so bomb the program here.
error('All 3 possible read methods failed - file cannot be read');
junk_field_length = -1;
default_float_type = 'no idea';
