% Example of using the LBLRTM wrappers.
%
% Wrappers expect the following:
% environment variable LBL_HOME should be set to a directory
% containing the following sub-directory structure:
%
% $LBL_HOME:
%   |-bin
%   |-hitran
%   |---xs
%
% bin must contain the exectuable with the name 'lblrtm';
% hitran must contain three things:
%   -- the TAPE3 file written by the lnfl program supplied by AER 
%     in the LBLRTM package, and it must be named 'tape3.data';
%   -- a subdirectory named 'xs' containing the molecular cross
%     section data; this is supplied in the LBLRTM package in:
%     'run_examples/run_example_user_defined_upwelling/xs'
%   -- the FSCDXS file, which is supplied in the LBLRTM package in
%     the same subdirectory as xs.
%


%%%%%%%
%
% Inputs:
%
% See header in create_tape5 for input descriptions. The higher level
% wrapper function will just pass these inputs to create_tape5.
% In this case we are just giving the level data (T/P/Z) as inputs,
% the gas concentrations will use the standard atmosphere
% (tropical, in this case), is used, since atm_flag=1.

% The first few args are required. Note changing the cleanup flag to
% false will leave the temporary run directory in place.
% For the profile, this is a purely synthetic profile that runs 
% 0-15 km with 1km spacing in altitude; 300-200 K in temperature at
% a constant lapse rate; and exponentially decaying for
% pressure. This is unphysical, but not so severely that LBLRTM
% will stop.
setenv('LBL_HOME','/home/dj104/lblrtm/LBL_HOME');
opengl neverselect;



profile.alt = linspace(0,15,16);
profile.tdry = linspace(300,200,16);
profile.pres = 10.^linspace(3,2,16);
profile.so2 = zeros(size(profile.pres));

% remaining args are optional, so we need to input them as pairs of 
% "input_name" , input_data; The order here
% does not matter as long as each name/value pair is contiguous.

wn_range = [575.0, 1225.0];
atmflag = 1;
cleanup_flag = false;
args = cell(1);
args{1} = 'HBOUND';
args{2} = [profile.alt(1), profile.alt(end),0.0];
args{3} = 'FTSparams';
args{4} = [10.0, 600.0, 1200.0, 1.0];
args{5} = 'MOLECULES';
args{6} = true(1,39);

[wnum, rad, trans] = ... 
    simple_matlab_lblrun(cleanup_flag, atmflag, profile, wn_range, ...
                         args{:});

% Analytic Jacobian run uses the same inputs, but we need to add
% one additional input to tell which jacobians to compute - this
% matches the LBLRTM definition, so -1 is the surface temp and
% emis. derivative; 0 = profile temperature; 1 = H2O, etc...
args{7} = 'CalcJacobian';
args{8} = 0;
[wnum, K] = ...
    simple_matlab_AJ_lblrun(cleanup_flag, atmflag, profile, wn_range, ...
                         args{:});

figure(1);
subplot(311);
plot(wnum,rad*1e7);
xlabel('wavenumber [cm^{-1}]')
ylabel('radiance [mW/(m^{2} sr cm^{-1}]')
subplot(312);
plot(wnum,trans);
xlabel('wavenumber [cm^{-1}]')
ylabel('Transmission')
subplot(313);
pcolor(wnum, profile.alt, K');
shading flat
xlabel('wavenumber [cm^{-1}]')
ylabel('altitude [km]')
