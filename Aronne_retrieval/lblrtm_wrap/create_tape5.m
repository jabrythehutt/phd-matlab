function create_tape5(atmflag, prof, VBOUND, varargin)

% function create_tape5(atmflag,prof,VBOUND,'Parameter1',value1, ...);
%
% produce an LBLRTM TAPE5 input file, given atmospheric sounding data.
% the format of the TAPE5 file is intended to match LBLRTM version 11.3.
%
% This function can only be used to create simple upwelling or
% downwelling radiance calculations. Only the major molecular
% species are specified. (H2O, CO2, O3), as well as the important
% minor constituents (N2O, CO, CH4). These are the first 6
% molecules for LBLRTM.
%
% Required Inputs:
%
%   atmflag : integer denoting the standard atmospheric profile to use:
%           1. Tropical, 2. Midlatitude Summer, 3. Midlatitude Winter,
%           4. Subarctic Summer, 5. Subarctic Winter, 6. U.S. Standard
%       Note that all gas concentrations will use values from this
%       standard atmosphere if they are not specified.
%
%   prof : structure containing atmospheric profile data.
%       The structure must have at minimum, an array of level locations,
%       given in either pressure [mbar] OR altitude [km]:
%
%       .pres  (Nx1) level pressure (mbar)
%       .alt   (Nx1) level altitudes (km)
%
%       If only one is specified, then the profile will default to the
%       temperature profile specified by atmflag.
%       If both are specified, then the input data is assumed to fully
%       specify the atmospheric profile, so temperature should also be
%       specified:
%
%       .tdry  (Nx1) level temperature (K)
%
%       The following fields are all optional - if left blank (e.g., if the
%       structure does not have these fields) corresponding values from the
%       standard atmospheric profile will be used:
%
%       .h2o   (Nx1) level water vapor mass mixing ratio (g/kg)
%       .o3    (Nx1) level ozone (ppmv)
%       .co2   (Nx1) level carbon dioxide (ppmv)
%       .n2o   (Nx1) level nitrous oxide (ppmv)
%       .co    (Nx1) level carbon monoxide (ppmv)
%       .ch4   (Nx1) level methane (ppmv)
%
%   VBOUND : wavenumber info = [beginning_wavenumber ending_wavenumber]
%       Or, use string names to use standard default values for particular
%       sensors: (values copied from rundecker.pro)
%       'AERIch1': [ 420.094, 1849.855]
%       'AERIch2': [1750.338, 3070.000]
%
% Optional inputs: the rest of the inputs are specified by Parameter Name /
% value pairs (e.g., same as the way parameters are specified for plot line
% characteristics, etc, with MATLAB plot()).
% So, the order of the parameters is not relevant, assuming they all
% correctly are input as Name / Value pairs. Name will not be case
% sensitive. Default values are listed for each, if relevant.
%
%   zlevels/plevels: an array of levels (layer boundaries) for LBLRTM.
%       By default, the levels will be equal to the data in the altitude
%       in the prof input variable; Using this input can assign a
%       different set of levels. Mainly useful for inputting high vertical
%       resolution profiles (e.g., from a radiosonde), and then
%       downsampling to a more reasonable level spacing.
%       Use zlevels for altitude [km] OR plevels for pressure [mbar].
%       Will be ignored if full prof (alt,pres,tdry) is not input.
%
%   Comment: a descriptive comment to add to the TAPE5. Default is empty
%       string, ''.
%
%   DeltaV: scalar floating point number specifying the desired
%   wavenumber spacing in the final LBLRTM "monochromatic" radiance
%   calculation. If this is unspecified, LBLRTM will compute a wavelength
%   spacing based on the narrowest lines (e.g., the high altitude lines
%   where pressure broadening is small).
%
%   TBOUND: surface info = [temperature at surface (K), surface emissivity]
%       Default is 290 K, with emissivity of 1.0, or the temperature of the
%       first profile data point, if a profile is input.
%
%   HBOUND : geometry info =
%       [observer_altitude (km) endpoint_altitude (km) zenith_angle@observer altitude (deg)]
%
%       For a ground based sensor looking straight up, observer altitude = 0 (or the surface
%       elevation if above sea level), the endpoint altitude is the altitude of the end of the line of
%       sight (generally the highest layer). Zenith angle is 0.
%
%       For an airborne or satellite sensor looking straight down, observer altitude is the platform
%       altitude, or the TOA, and the end point altitude is now 0 (or the surface elevation).
%       Zenith angle is 180.
%
%       Default is [level_top, level_bottom, 180] - basically, a nadir
%       observation of the upwelling radiance fromspace. Top/bottom are
%       chosen as alt or pressure depending on the inputs.
%
%   FTSparams: Parameters for a simulated FTS (Fourier Transform
%       Spectrometer) observation of the computed radiance. The input
%       should be a 3 element array, with elements:
%           optical path difference [cm]
%           wavenumber min [1/cm]
%           wavenumber max [1/cm]
%           sampling interval [1/cm]
%       Or, use a string to name some particular instruments, to use their
%       default parameters: (values for AERI copied from D.Turner's
%       rundecker.pro)
%       'AERIch1': [1.03702766,  497.57589, 1803.71268, 0.48214700]
%       'AERIch2': [1.03702766, 1796.48042, 3022.09850, 0.48214700]
%       These values are passed to the appropriate input parameters to
%       LBLRTM, which will then produce the simulated FTS observation
%       assuming an unapodized interferogram. LBLRTM will produce
%       additional binary files TAPE13 (radiance) and TAPE14 (transmission)
%       which are the simulated FTS observations.
%
%       No default - if unspecified, no FTS simulation is performed.
%
%       Note, if ODonly is specified, the FTS parameters will have no
%       use, since the radiance is not computed.
%
%   includeXS: set flag to 1 (default is 0) to include heavy molecule cross
%       sections in the LBLRTM calculation. For the moment, enabling this
%       flag will include hard coded atmospheric concentrations for three
%       particular CFC / Cl molecules. These are weak lines, but some occur
%       within atmospheric windows, so they can be detectable for
%       downwelling radiance calculations.
%       These are not usually as important for upwelling radiance
%       calculations, where the absorption lines are not strong compared to
%       the surface emissivity.
%
%       Default is 0, so no cross section data is added.
%
%   CalcJacobian: set to an array of flags containing the desired Jacobian
%       calculation. The flags follow LBLRTM convention:
%       -1: Jacobian with respect to surface parameters (emissivity,
%           temperature).
%       0: w.r.t. temperature
%       1-39: w.r.t. concentration of molecular species, by number
%           (1=water vapor, 2=CO2, 3=ozone, etc. See Table I in LBLRTM
%           instructions for the full list.)
%
%       Note that additional LBLRTM runs, output files, etc. are needed
%       with a Jacobian run. A subdirectory AJ is needed in the LBLRTM run
%       directory (which must be created in advance.)
%
%       Also note that this overrides the ODonly flag.
%       Beware of combinations with gcflag that might not make sense (e.g.,
%       dry atmosphere and water vapor jacobian).
%
%       NOTE: untested for downwelling radiance jacobians!!!
%
%   gcflag : code for gas combinations used in the LBLRTM calculation.
%       This can override profile data given in prof - e.g., a given water vapor profile
%       would be ignored and all h2o concentration is assumed to be zero if gcflag = 6.
%           1. all gases
%           2. water vapor continuum only [NOTE - this code does not currently work]
%           3. water vapor line only
%           4. water vapor continuum, lines, & ozone
%           5. ozone only
%           6. dry
%
%       Default is 1. Note, this has no effect on molcules included with
%           the includeXS flag.
%
%   ODonly: set this to 1 to write out optical depth, per level. No radiance is computed.
%	If ODonly == 1 is false, then the spectral radiance will be computed.
%   Default is to comptue radiance, and not output OD files (ODonly = 0)
%
%   outputfile: string name with the output TAPE5 filename.
%       default name is "TAPE5"
%
% Outputs:
%   A TAPE5 file, named "TAPE5", is produced in the current directory.
%
% Notes:
%   0. the current tape5 file will be overwritten without warning.
%   1. Uses given profile levels for layering
%           (no checks for good/bad profile values)
%           (no extrapolating to top/bottom atmospheres)
%   2. Little to no checking is done on the validity of various input
%   parameters. For example, you could set TBOUND to [300, 2.0], which will
%   cause LBLRTM to barf because emissivity is 2.0
%
% TODO List:
%   Input checking - it would be preferable to be able to produce logical
%   error messages here in MATLAB, than wait for the cryptic ones in
%   LBLRTM.
%   Input units for profile data
%   Inputs for jacobians
%   Add more molecules to .prof
%
% MODIFICATION HISTORY:
%   A. Merrelli May 2010
%   Added 3 more species (n2o, co, ch4), changed NMOL to 6 from 7
%   (the 7th molecule is O2; I doubt that will be a needed input any time soon)
%
%   A. Merrelli Jul 2009
%   Final (probably) rewrite, using optional parameter framework. The
%   function is now as extensible as possible, as future inputs are needed.
%
%	Extensive rewrite and commenting by Aronne Merrelli, June 2009
%	Also pruned dead code, and made some parts more extensible for adding
%	additional chunks of TAPE 5 file instructions in the future.
%	Based on previous versions:
%	  Written by:	 <-- Paolo Antonelli  -->,  16-Jul-2003 (UW-SSEC)
%	  Written by:	 <-- leslie moy  -->,  02-02-2002 (UW-SSEC)
%         Cribbed from D.Tobin's writet5.m (DCT 4/3/01)
%
% REVISION INFORMATION (RCS Keyword):
%   $Id: OSS_write5_reh.m,v 1.3 2005/04/12 20:24:17 reholz Exp $
%
%------------------------------------------------------------------------------


% Note on implemenation - the previous version directly wrote into the output TAPE5
% file with fprintf() along the way. Now, each line in the file is first created as a string
% in MATLAB, and then the strings are written one line at a time. This is a more tedious
% way of writing to the file but the script should be easier to follow and debug with all
% the various TAPE5 records having associated MATLAB variables.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% First, need to parse inputs.
% Return error if not an even number
if mod(length(varargin),2) ~= 0
    error('Must input optional parameters as ''Name'', value pairs.');
end

if ischar(VBOUND)
    switch upper(VBOUND)
        case 'AERICH1', VBOUND = [ 420.094, 1849.855];
        case 'AERICH2', VBOUND = [1750.338, 3070.000];
        otherwise, error(['No default VBOUND for ' VBOUND]);
    end
end

% Expected Parameter names
Parameter_Names = [{'COMMENT'}, {'HBOUND'}, {'TBOUND'},  {'FTSPARAMS'}, ...
    {'INCLUDEXS'}, {'GCFLAG'}, {'ODONLY'}, {'OUTPUTFILE'}, {'DELTAV'}, ...
    {'CALCJACOBIAN'}, {'PLEVELS'}, {'ZLEVELS'}, {'MOLECULES'},{'MOLUNITS'},{'TUNIT'},{'PUNIT'}];
% check that all input param names are expected ones.
for q = 1:2:length(varargin);
    if ~ischar(varargin{q})
        error(['Parameter in position ' num2str(q) ' was not a string']);
    else
        found_param_name = any(strcmpi(varargin{q}, Parameter_Names));
        if found_param_name == 0
            error(['Parameter name ' varargin{q} ' is unknown']);
        end
    end
end

% At this point, the varargin should be correct pairs of Name/Value, and
% should consist of names we are expecting. So, walk through the inputs to
% figure out what we need to do.


% set defaults, then overwrite with whatever was input.
comment = '';
simulateFTS = 0;
includeXS = 0;
gcflag = 1;
ODonly = 0;
outputfile = 'TAPE5';
deltaV = 0.0;
calcJacobians = 0;
mols = false(1,39);
%Default molecule units are ppmv (A)
molUnits = zeros(1,39);
molUnits = molUnits+65;
molUnits = char(molUnits);
userMolUnits = '';
tunit='A';
punit = 'A';

argParams = varargin(1:2:length(varargin)-1);

for q = 1:2:length(varargin);
    paramName = varargin{q};
    paramValue = varargin{q+1};
    switch upper(paramName)
        case 'COMMENT', comment = paramValue;
        case 'HBOUND', HBOUND = paramValue;
        case 'TBOUND', TBOUND = paramValue;
        case 'FTSPARAMS'
            simulateFTS = 1;
            if ischar(paramValue);
                switch upper(paramValue)
                    case 'AERICH1'
                        FTSparams = [1.03702766, ...
                            497.57589, 1803.71268, 0.48214700];
                    case 'AERICH2'
                        FTSparams = [1.03702766, ...
                            1796.48042, 3022.09850, 0.48214700];
                    otherwise, error(['No FTS parameters for ' paramValue]);
                end
            else
                FTSparams = paramValue;
            end
        case 'INCLUDEXS'
            includeXS = paramValue == 1;
        case 'GCFLAG', gcflag = paramValue;
        case 'ODONLY', ODonly = paramValue == 1;
        case 'OUTPUTFILE', outputfile = paramValue;
        case 'DELTAV'
            deltaV = paramValue;
        case 'CALCJACOBIAN'
            ODonly = 1;
            jacobian_flags = paramValue;
            calcJacobians = 1;
            simulateFTS = 0;
        case 'PLEVELS'
            levels = paramValue;
            use_alt_for_levels = 0;
            num_levels = length(levels);
        case 'ZLEVELS'
            levels = paramValue;
            use_alt_for_levels = 1;
            num_levels = length(levels);
        case 'MOLECULES'
            userMols = paramValue;
            if(islogical(userMols))
                mols(1:length(userMols))=userMols;
            elseif(isnumeric(userMols))
                mols(userMols)=true;
            end

        case 'MOLUNITS'
            
            userMolUnits = paramValue;

        case 'TUNIT'
            
            
            tunit=paramValue;
            
            if isnumeric(tunit)
                
                tunit = num2str(tunit);
                
            end
            
        case 'PUNIT'
            
            punit = paramValue;
            
            if isnumeric(punit)
                punit = num2str(punit);
                
            end
            
    end
end
allMols= molecules();
userMolsSpecified = ~isempty(find(strcmpi(argParams,'MOLECULES'),1));


if isempty(find(mols,1))&&~userMolsSpecified
    
    for ix = 1:length(allMols)
        
        molName = allMols{ix};
        
        if isfield(prof,lower(molName))
            mols(ix)=true;
        end
    end
end

if isempty(find(mols,1))
    
    mols(1)=true;
    prof.h2o = zeros(size(prof.alt));
    
end

molIndices = find(mols);

if (~isempty(userMolUnits))&&(length(userMolUnits)~=length(mols))
    
    
    
    for ix = 1:length(molIndices)
        
        molIndex = molIndices(ix);
        molUnits(molIndex) = userMolUnits(ix);
        
    end
    
elseif ~isempty(userMolUnits)
    
    molUnits = userMolUnits;

end

molUnits(~mols)=' ';


for ix = 1:length(molIndices)
    molIndex = molIndices(ix);
    molName = lower(allMols{molIndex});
    
    if ~isfield(prof,molName)
        molUnits(molIndex)=num2str(atmflag);
        
    end
    
end


function [valArr]=between(testVals,val1,val2)

    %check if testVal is between val1 and val2 regardless of order
    testArr = [val1,val2];
   testVal1 = min(testArr);
   testVal2 = max(testArr);
   tf= testVals>=testVal1&testVals<=testVal2;
   valArr=testVals(tf);


end



% first, check the prof input to see if we are specifying the levels with
% LBLRTM Record 3.3 & 3.6 (we have full sounding data), or with 3.3 only
% (using std. atmosphere at particular levels).
% Note that the default levels are assigned here - basically, use the
% values inside prof. This will be overwritten by the 'LEVELS' parameter
% input.
if isfield(prof, 'alt') && isfield(prof, 'pres') && isfield(prof, 'tdry')
    
    full_profile = 1;
    num_prof_pts = length(prof.alt);
    % choose alt for levels only if ZLEVELS/PLEVELS were not input
    if ~exist('use_alt_for_levels','var')
        use_alt_for_levels = 1;
        
        
        num_levels = num_prof_pts;
        levels = prof.alt;
    end
    
else
    full_profile = 0;
    % just use whichever we find first:
    if isfield(prof,'alt')
        use_alt_for_levels = 1;
        num_levels = length(prof.alt);
        levels = prof.alt;
    else
        if isfield(prof,'pres')
            use_alt_for_levels = 0;
            num_levels = length(prof.pres);
            levels = prof.pres;
        else
            error('Profile must have at least alt or pres defined');
        end
    end
end

% one check to try to prevent rediscovering the same bug over and over -
% there are problems with running the Jacobian code with a standard
% atmosphere profile. So, trap for this, and display a message. Not the
% best solution perhaps, but this allows the user to proceed anyway, if so
% desired.
if calcJacobians && ~full_profile;
    disp(['LBLRTM may not correctly compute Jacobians without a ' ...
        'user-specified profile. Double check the create_tape5 input!'])
end

% now, figure out what to do with TBOUND/HBOUND:
% If the user input either one through a keyword, use those values;
% Otherwise, copy the profile data at the boundaries, if available (default
% behavior). If neither case is true it will thus default to the hardcoded
% values, set above.
if ~exist('HBOUND','var')
    HBOUND = [levels(end) levels(1) 180.0];
end

angle = HBOUND(3);

if ~exist('TBOUND','var')
    if full_profile
        
        TBOUND = [prof.tdry(1) 1.0];
        
        if angle <90.0
            
            %TBOUND = [prof.tdry(end) 1.0];
            TBOUND = [2.7 1.0];
        end
    else
        if angle <90.0
            
            %TBOUND = [prof.tdry(end) 1.0];
            TBOUND = [2.7 1.0];
        end
    end
end




% levels = between(levels,HBOUND(1),HBOUND(2));
% 
% num_levels = length(levels);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% finished parsing inputs - get started with the real work.
% there are no more error() calls from here forward
%

% Open the output file (LBLRTM format)
fid = fopen(outputfile,'w');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Record 1.1 : initialization character & comments
rec_1_1 = sprintf('$ %s \n', comment);
fprintf(fid, rec_1_1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Record 1.2. LBLRTM Control Variables.
% Most of these do not change, since we are only using a subset of the possible
% set of LBLRTM runs.
rec_1_2_format = ' HI=%1d F4=%1d CN=%1d AE=0 EM=%1d SC=%1d FI=0 PL=%1d TS=0 AM=%1d MG%2d LA=0 OD=%1d XS=%1d   00   00\n';
HI_flag = 1;
F4_flag = 1;
AM_flag = 1;
PL_flag = 0;

if gcflag == 1;
    CN_flag = 1;
else
    CN_flag = 6;
end

if ODonly == 1
    MG_flag = 1;
    EM_flag = 0;
else
    MG_flag = 0;
    EM_flag = 1;
end

if includeXS == 1
    XS_flag = 1;
else
    XS_flag = 0;
end

if simulateFTS
    SC_flag = 2;
else
    SC_flag = 0;
end

if deltaV > 0;
    OD_flag = 1;
else
    % need to use fixed auto DV, if we are computing jacobians
    % (otherwise, spectral grid may change between layers, which isn't
    % good)
    if calcJacobians
        OD_flag = 3;
    else
        OD_flag = 0;
    end
end

rec_1_2 = sprintf(rec_1_2_format, HI_flag, F4_flag, CN_flag, EM_flag, ...
    SC_flag, PL_flag, AM_flag, MG_flag, OD_flag, XS_flag);
fprintf(fid, rec_1_2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Record 1.2.a  continuum multipliers (only use if CN=6)
% codes from LBLRTM - multiplicative factors to multiply default values - so, 0 here
% means that feature is not used, the 1 means the default will be used. the 7 coefficients:
% 1 - w.vapor self, 2 - w.vapor foreign, 3 - co2, 4 - ozone, 5 - o2, 6 - n2, 7 - rayleigh
switch (gcflag)
    case 2, rec_1_2_a = sprintf('%10.3f%10.3f%10.3f%10.3f%10.3f%10.3f%10.3f\n',[1 1 0 0 0 0 0]); %wco
    case 3, rec_1_2_a = sprintf('%10.3f%10.3f%10.3f%10.3f%10.3f%10.3f%10.3f\n',[0 0 0 0 0 0 0]); %wnc
    case 4, rec_1_2_a = sprintf('%10.3f%10.3f%10.3f%10.3f%10.3f%10.3f%10.3f\n',[1 1 0 1 0 0 0]); %wvo
    case 5, rec_1_2_a = sprintf('%10.3f%10.3f%10.3f%10.3f%10.3f%10.3f%10.3f\n',[0 0 0 1 0 0 0]); %ozo
    case 6, rec_1_2_a = sprintf('%10.3f%10.3f%10.3f%10.3f%10.3f%10.3f%10.3f\n',[0 0 1 0 1 1 1]); %dry
end  %switch(gcflag)
if gcflag > 1
    fprintf(fid, rec_1_2_a);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Record 1.3 LBLRTM specifications.
% Only non-default used here is the wavenumber bounds

if OD_flag == 1
    % use %70s, as padding get the spacing correct (dvout is the 90-100
    % characters in the line)
    rec_1_3 = sprintf('%10.3f%10.3f%70s%10.8f\n', VBOUND(1), VBOUND(2), '', deltaV);
else
    rec_1_3 = sprintf('%10.3f%10.3f\n',[VBOUND(1) VBOUND(2)]);
end
fprintf(fid, rec_1_3);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Record 1.4 boundary temperature and emissivity
%   TBOUND  = [surface_temperature (K) scalar_surface_emissivity ()]
rec_1_4 = sprintf('%10.3f%10.3f%10.3f%10.3f\n',[TBOUND(1) TBOUND(2) 0 0]);
% if this is an ODonly calculation, don't write it into the file (it will
% be needed later for the Radiance jacobian calculations.)
if ODonly ~= 1
    fprintf(fid, rec_1_4);
end

% Record 2.X are not used, since AM flag is 1 in record 1.2 (using LBLATM.)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Record 3.1 LBLATM parameters - the atmosphere profile info

if full_profile
    MODEL = 0;			 % user supplied atmospheric profile
else
    MODEL = atmflag;     % not full profile data - will use std.
end
ITYPE = 2;			     % slant path calculation



ix = (levels >= min(HBOUND(1),HBOUND(2)))&(levels<=max(HBOUND(1),HBOUND(2)));
num_levs = length(find(ix));
levs = levels(ix);


if use_alt_for_levels

    IBMAX = num_levs;		     % number of layer boundaries
else
    IBMAX = -num_levs;
end
NOZERO = 1;			     % suppress zeroing absorber amounts
NOPRNT = 1;			     % selects short printout
NMOL   = max(molIndices);			     % number of molecules
if calcJacobians
    IPUNCH = 2;
else
    IPUNCH = 1;
end
IFXTYP = 0;
MUNITS = 0;
RE = 0;
HSPACE = 100;
VBAR = (VBOUND(1)+VBOUND(2))/2;
rec_3_1 = sprintf('%5i%5i%5i%5i%5i%5i%5i%2i %2i%10.3f%10.3f%10.3f\n',...
    [MODEL ITYPE IBMAX NOZERO NOPRNT NMOL IPUNCH IFXTYP MUNITS RE HSPACE VBAR]);
fprintf(fid, rec_3_1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Record 3.2 - slant path parameters
% {H1} observer altitude = HBOUND(1)
% {H2} end point altitude = HBOUND(2)
% {ANGLE} zenith angle at H1 =0 for uplooking = 180 for downlooking = HBOUND(3)


rec_3_2 = sprintf('%10.3f%10.3f%10.3f\n',[HBOUND(1) HBOUND(2) angle]);
fprintf(fid, rec_3_2);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Record 3.3 - level input
% skip record 3.3.a
% Record 3.3.b is just an arraywise print of the levels, 8 per line.
rec_3_3_b_format = '%10.3f%10.3f%10.3f%10.3f%10.3f%10.3f%10.3f%10.3f\n';
num_rec_3_3_b_lines = ceil(num_levs/8);
rec_3_3_b = cell(num_rec_3_3_b_lines,1);

for q = 1:num_rec_3_3_b_lines-1;

    rec_3_3_b{q} = sprintf(rec_3_3_b_format, levs( q*8-7:q*8 ));
end
% slight hack to ensure the newline makes it to the file - if there are less
% than 8 values remaining in prof.alt, the \n will be skipped. So,
% add it "manually" to the output from sprintf()
rec_3_3_b_format = '%10.3f%10.3f%10.3f%10.3f%10.3f%10.3f%10.3f%10.3f';
q = num_rec_3_3_b_lines;
rec_3_3_b{q} = [sprintf(rec_3_3_b_format, levs( q*8-7:end )) '\n'];
for q = 1:num_rec_3_3_b_lines;
    fprintf(fid, rec_3_3_b{q});
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Record 3.4 - Profile controls
if full_profile
    
    rec_3_4 = sprintf('%5i points in the user defined profile\n',num_prof_pts);
    fprintf(fid,rec_3_4);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Record 3.5 profile data input
    
    % create defaults for each of the molecular species that we
    % are specifying in the profile data.
    % the default is the number of the standard atmosphere profile;
    % specify 6 since we specified 6 in the LBLATM info (NMOL in rec 3.1)
    
    %atmflag=2;
    
    %     switch atmflag
    %         case 1, atmflagstring='111111';
    %         case 2, atmflagstring='222222';
    %         case 3, atmflagstring='333333';
    %         case 4, atmflagstring='444444';
    %         case 5, atmflagstring='555555';
    %         case 6, atmflagstring='666666';
    %     end  %switch(atmflag)
    
    atmflagstring = molUnits;
    
    
    % first check for profile data. Change from default standard atm., if specified.
    % if not specified, leave at default standard atmosphere, and create zero array.
    %defaultAtm = 2;

    
    %     if isfield(prof, 'h2o')
    %         h2o_profile = prof.h2o;
    %         atmflagstring(1) = 'A';
    %     else
    %         h2o_profile = zeros(num_prof_pts,1);
    %     end
    %     if isfield(prof, 'co2')
    %         co2_profile = prof.co2;
    %         atmflagstring(2) = 'A';
    %     else
    %         co2_profile = zeros(num_prof_pts,1);
    %     end
    %     if isfield(prof, 'o3')
    %         o3_profile = prof.o3;
    %         atmflagstring(3) = 'A';
    %     else
    %         o3_profile = zeros(num_prof_pts,1);
    %     end
    %     if isfield(prof, 'n2o')
    %         n2o_profile = prof.n2o;
    %         atmflagstring(4) = 'A';
    %     else
    %         n2o_profile = zeros(num_prof_pts,1);
    %     end
    %     if isfield(prof, 'co')
    %         co_profile = prof.co;
    %         atmflagstring(5) = 'A';
    %     else
    %         co_profile = zeros(num_prof_pts,1);
    %     end
    %     if isfield(prof, 'ch4')
    %         ch4_profile = prof.ch4;
    %         atmflagstring(6) = 'A';
    %     else
    %         ch4_profile = zeros(num_prof_pts,1);
    %     end
    
    % second check gcflag - if some gasses are turned off, change the flag to A, which
    % means a value of 0.0 in the level input will set the molecule concentration to zero.
    % note this will override input profile data - e.g., an input water vapor profile
    % might be ignored.
    %     switch gcflag
    %         case 1; % don't need to do anything for all gasses in use.
    %         case 2; % I'm not sure what to actually do here - how do you turn off w.v. lines, but leave cont.?
    %         case 3
    %             atmflagstring(2:3)='AA'; % turn off co2 , ozone
    %             co2_profile = zeros(num_prof_pts,1);
    %             o3_profile = zeros(num_prof_pts,1);
    %         case 4
    %             atmflagstring(2)='A';    % turn off co2
    %             co2_profile = zeros(num_prof_pts,1);
    %         case 5
    %             atmflagstring(1:2)='AA'; % turn off water vapor, co2
    %             co2_profile = zeros(num_prof_pts,1);
    %             h2o_profile = zeros(num_prof_pts,1);
    %         case 6
    %             atmflagstring(1)='A';    % turn off water vapor
    %             h2o_profile = zeros(num_prof_pts,1);
    %     end
    
    % ok, can now make the strings for level data - note each level is split across
    % 2 lines
    rec_3_5 = cell(num_prof_pts*2,1);
    
    for q = 1:num_prof_pts;
        % note the AA here implies the pressure in mbar and temperature in K
        % (as described in the header comments)
        rec_3_5{q*2-1} = [sprintf(['%10.3f%10.3f%10.3f     ',punit,tunit,' L '], ...
            prof.alt(q), prof.pres(q), prof.tdry(q)),atmflagstring,'\n'];
        rec_3_5{q*2}='';
        
        for ix =1:max(molIndices)
            molIndex = ix;
            unit = atmflagstring(molIndex);
            val = 0.0;
            if isnan(str2double(unit))&&(~strcmp(unit,' '))
                molName = lower(allMols{molIndex});
                if isfield(prof,molName)
                    molprof = getfield(prof,molName);
                    val = molprof(q);
                end
            end
            
            fieldStr = sprintf('%15.8e',val);
            remtest = rem(ix,8);
            if(remtest==0||ix==max(molIndices))
                
                fieldStr = [fieldStr,'\n'];
            end
            
            rec_3_5{q*2}=[rec_3_5{q*2},fieldStr];
            
        end
        
        %         rec_3_5{q*2} = sprintf('%15.8e%15.8e%15.8e%15.8e%15.8e%15.8e\n', ...
        %             [h2o_profile(q); co2_profile(q); o3_profile(q); n2o_profile(q); ...
        %             co_profile(q); ch4_profile(q)] );
        fprintf(fid, rec_3_5{q*2-1});
        fprintf(fid, rec_3_5{q*2});
    end
    
end % of full profile

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Record 3.7 - Cross section control
%
% These inputs are for heavy molecule absorption lines. The data for these
% molecular species are not in the TAPE3 from HITRAN, so they are specified
% through cross section data (FSCDXS and the subdirectory xs in the LBLRTM
% run directory).
% For the moment, just using hard-coded information.

if includeXS
    
    fprintf(fid,'%5i%5i%5i selected x-sections are :\n',[3 0 0]);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Record 3.7.1 - Cross section names
    fprintf(fid,'CCL4      F11       F12 \n');
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Record 3.8, 3.8.1, 3.8.2 - Cross section level controls
    
    fprintf(fid,'%5i%5i  \n',[2 0]);
    fprintf(fid,'%10.3f     AAA\n',min(prof.alt));
    %CFC11 and CFC12 are half of the official values
    fprintf(fid,'%10.3e%10.3e%10.3e\n',[1.105e-04 1.343e-04 2.527e-04]);
    fprintf(fid,'%10.3f     AAA\n',max(prof.alt));
    fprintf(fid,'%10.3e%10.3e%10.3e\n',[1.105e-04 1.343e-04 2.527e-04]);
    fprintf(fid,'-1.\n');
    
end % of includeXS section

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Record 10.1 - "FFT scan"
% this will simulate an unapodized FTS observation with an input OPD.
% (e.g., the instrument line function will be a pure sinc function).
% 
% if simulateFTS && ~calcJacobians
%     rec_10_1_format = '%10.3f%10.3f%10.3f%5d  -12     %10.3f   12    1    1%5d\n';
%     rec_10_2_format = '%10.3f\n';
%     rec_10_1_line1 = sprintf(rec_10_1_format, FTSparams(1), FTSparams(2), ...
%         FTSparams(3), 1, FTSparams(4), 50);
%     rec_10_1_line2 = sprintf(rec_10_1_format, FTSparams(1), FTSparams(2), ...
%         FTSparams(3), 0, FTSparams(4), 51);
%     
%     rec_10_2_line = sprintf(rec_10_2_format,3.8528);
%     fprintf(fid, rec_10_1_line1);
%     fprintf(fid, rec_10_2_line);
%     
%     fprintf(fid, rec_10_1_line2);
%     fprintf(fid, rec_10_2_line);
%     fprintf(fid, '-1\n');
% end

if simulateFTS && ~calcJacobians
    rec_9_1_format = '%10.3f%10.3f%10.3f%5d                       12    1    1%5d\n';

    rec_9_1_line1 = sprintf(rec_9_1_format, FTSparams(1), FTSparams(2), ...
        FTSparams(3), 1, 50);
    rec_9_1_line2 = sprintf(rec_9_1_format, FTSparams(1), FTSparams(2), ...
        FTSparams(3), 0, 51);
    

    fprintf(fid, rec_9_1_line1);
    fprintf(fid, rec_9_1_line2);
    fprintf(fid, '-1\n');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Extra runs for Jacobians.
% Run 2 = Compute downwelling radiance, from OD computed in run 1 (above)
if calcJacobians
    fprintf(fid, '\n');
    run2_rec_1_1 = '$ Run 2 - Downwelling Radiance (RDDNlayer_nnn) for AJ calculation \n';
    fprintf(fid, run2_rec_1_1);
    % set flags for downwelling radiance files
    % note these are "hardcoded" for the jacobian calculation - and mostly
    % 0, except for MG=40 (tells LBLRTM to read the OD files and create
    % RDDN files), and the OD value that depends on the DV spacing (use
    % default self-calculated DV or an input value), and EM=1 (computing
    % radiance)
    
    run2_rec_1_2 = sprintf(rec_1_2_format, 0, 0, 0, 1, 0, 0, 0, 40, OD_flag, 0);
    fprintf(fid, run2_rec_1_2);
    % re-use record 1.3, so the DV spacing matches.
    fprintf(fid, rec_1_3);
    % re-use record 1.4, so surface properties match.
    fprintf(fid, rec_1_4);
    % Record 1.6 - name of OD files (should be named ODint_ by default)
    fprintf(fid, 'ODint_\n');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Extra runs for Jacobians.
% Run 3 - N = Jacobians based on perturbed OD and downwelling Radiance
% (RDDN) computed in Runs 1 and 2, above (respectively)

% input flags = re-using CN from from the first run (not 100% sure this is
% correct, yet !!), EM = 3 (compute AJ), 41 (upwelling), 40 (downwelling)
% NOTE - haven't tried downwelling AJ yet, so hardcoded upwelling.
% OD flag re-used from above (get the same DV)
if calcJacobians
    
    imrg = 41;
    
    if angle <90.0
        
        imrg = 40;
    end
    
    runq_rec_1_2 = sprintf(rec_1_2_format, 1, 1, CN_flag, 3, 0, 0, 0, imrg, OD_flag, 0);
    for q = 1:length(jacobian_flags);
        % extra line space (just to make the TAPE5 a little more human
        % readable - Pretty sure LBLRTM will just be scanning for the next "%").
        fprintf(fid, '\n');
        runq_rec_1_1 = ['$ Run ' sprintf('%d',q+2) ' Analytic Jacobian - RDderivUPW in AJ subdir\n'];
        fprintf(fid, runq_rec_1_1);
        fprintf(fid, runq_rec_1_2);
        % re-use record 1.3, so the DV spacing matches.
        fprintf(fid, rec_1_3);
        % re-use record 1.4, so surface properties match.
        fprintf(fid, rec_1_4);
        % Record 1.5 - specifies the jacobian parameter.
        fprintf(fid, '%5d\n', jacobian_flags(q));
        % Record 1.6 - name of OD files (should be named ODint_ by default)
        fprintf(fid, 'ODint_\n');
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% End of TAPE5 file marker - we are done!
fprintf(fid,'%%\n');
fclose(fid);

end
