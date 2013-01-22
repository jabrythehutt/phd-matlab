function [Knew,ynew,lblrtm_success] = ...
    lblrtm_update_K(xhat, prior, wavenum, FTSparams, cleanup_work_dir)
%function [Knew,ynew,lblrtm_success] = ...
%   lblrtm_update_K(xhat, prior, wavenum, FTSparams, cleanup_work_dir)
%
% Helper function to compute y and K at a new state vector, using
% LBLRTM. Note this uses simple_matlab_lblrun and
% simple_matlab_AJ_lblrun to interface to LBLRTM.
%
% Outputs are K,y, and a flag denoting success/failure of the LBLRTM run.
% (will be set to false if either run, e.g. the run to compute y or the 
% run to compute K, indicated failure)
%
% This is not quite a general function, and it is tied to the T-Q
% only retrievals being performed for the FIR clear sky modeling -
%
% Inputs: xhat - state vector with T and ln(q), which will be used
%   to compute the new y and K.
% prior: structure containing other state parameters that are not
%   being retrieved but are included in the fwd model (all are required): 
%   pressure [hPa], alt [km], (at each level),  ln(ppmv) at each level
%   for the following minor gasses: co2, o3, n2o, co, ch4, and
%   finally Tsurf [K].
% wavenum: wavenumber range for the monochromatic LBLRTM
%   calculation.
% FTSparams: FT Spectrometer parameters (see create_tape5.m in 
%   lblrtm_wrap.)
% cleanup_work_dir: logical (default is true), specifying whether
%   the LBLRTM work directory should be deleted. 

if nargin < 5
    cleanup_work_dir = true;
end


nstatevar = length(xhat);
prof.alt = prior.alt;
prof.pres = prior.pressure;
prof.tdry = xhat(1:nstatevar/2);
prof.h2o = exp(xhat(nstatevar/2+1:end));
mol_names = [{'co2'}, {'o3'}, {'n2o'}, {'co'}, {'ch4'}];
for m=1:length(mol_names);
    
    if isfield(prof,mol_names{m})

        prof.(mol_names{m}) = exp(prior.(mol_names{m}));
    
    end
end

% make sure that we are not attempting to run LBLRTM in a way that will
% crash. Current retrievals appear to generate enormous water vapor
% densities at times (totally unphysical ones), which crash LBLRTM; so,
% add a hardcoded check against large q values.
% Might not be the best place to put this check - but, this is where the
% state vector is turned back into a profile.

% using 1000g/kg - I'm not sure it is wise to use a more realistic limit
% (say 50, since I don't think any level will ever have more than 50),
% because it seems possible that an eventually converging retrieval might
% have a few large q values at certain iterations.
if any(prof.h2o >= 1e6)
    lblrtm_success = false;
    Knew = [];
    ynew = [];
    return
end


%t5arglist = [{'FTSparams'}, {FTSparams}, ...
%    {'HBOUND'}, {prior.hbound}, ...
%    {'Tbound'}, {[prior.Tsurf, prior.esurf]}];

[wavenum_grid, ynew, tau, lblrtm_success_y] = simple_matlab_lblrun(...
    cleanup_work_dir, prior.stdatm_flag(1), prof, wavenum, 'FTSparams',FTSparams,'HBound',prior.hbound,'Tbound', [prior.Tsurf, prior.esurf]); %#ok<ASGLU>
    
%t5arglist = [t5arglist, {'CalcJacobian'}, {[0 1]}];
[wavenum_grid, Knew, lblrtm_success_K] = simple_matlab_AJ_lblrun(...
    cleanup_work_dir, prior.stdatm_flag(1), prof, wavenum,'FTSparams',FTSparams,'HBound',prior.hbound,'Tbound', [prior.Tsurf, prior.esurf], 'CalcJacobian',[0 1]); %#ok<ASGLU>

lblrtm_success = lblrtm_success_y && lblrtm_success_K;
