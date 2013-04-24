%%%%%
% Prior profile from sample data (average profile at ARM - Manus
% island site (tropical profile)

load sample_data.asc
setenv('LBL_HOME','/home/dj104/lblrtm/LBL_HOME');

% construct a profile data structure with everything in physical
% units, and a prior structure with the ln(concentration)
% individual fields - note concentrations are in ln-space
% the sample data has 40 levels, I am truncating to 30 levels to
% save time with the LBLRTM run.
nlevels = 30;
profile.alt = sample_data(1:nlevels,1);  % km
profile.tdry = sample_data(1:nlevels,2); % K
profile.pres = sample_data(1:nlevels,3); % hPa
profile.h2o = sample_data(1:nlevels,4);  % g/kg

%Convert to ppmv
profile.h2o = profile.h2o*(28.966/18.0153)*1.0e3;
profile.co2 = sample_data(1:nlevels,5);  % rest are ppmv
profile.o3 = sample_data(1:nlevels,6);
profile.n2o = sample_data(1:nlevels,7);
profile.co = sample_data(1:nlevels,8);
profile.ch4 = sample_data(1:nlevels,9);


prior = profile;
cleanup_flag = true;
aJParams=[0,1];

% construct state vector - this will be T & Q only
% prior.alt = sample_data(1:nlevels,1);
% prior.tdry = sample_data(1:nlevels,2);
% prior.pres = sample_data(1:nlevels,3);
% prior.h2o = log(sample_data(1:nlevels,4));
% prior.co2 = log(sample_data(1:nlevels,5));
% prior.o3 = log(sample_data(1:nlevels,6));
% prior.n2o = log(sample_data(1:nlevels,7));
% prior.co = log(sample_data(1:nlevels,8));
% prior.ch4 = log(sample_data(1:nlevels,9));

%x0 = [prior.tdry; prior.h2o];
% other data -  the atm flag (for trace gas concentrations);
% esurf/tsurf for surface property (greybody only)
prior.stdatm_flag = 1;
prior.esurf = 1.0;
prior.Tsurf = prior.tdry(1);
prior.hbound = [prior.alt(end),prior.alt(1),180.0];

%%%%%
% Sensor noise covariance, Se
%
% Se is diagonal - this should be replaced with a better estimate
% Units must match LBLRTM (W/cm2) - this is just assuming 1 R.U. 
% NEdR (where R.U. = mW/(m2 sr cm^-1)) for all channels
% Note also that you need the correct length to match the radiance 
% vector produced by LBLRTM, which may not be known ahead of time


%%%%%
% Prior state covariance, Sa
%
% Sa is a synthetic correlated array, with some guesses as to the 
% correlation lengths and variance; units need to match prior, so
% corr length is km, temp is K, wvap is ln(q)
corr_length = 2.0;
temp_var = linspace(4,9,length(prior.alt));
temp_Sa = synthetic_Sa(prior.alt, corr_length, temp_var);
wvap_var = linspace(1.0,1.0,length(prior.alt));

wvap_Sa = synthetic_Sa(prior.alt, corr_length, wvap_var);

%Convert back to ppmv
wvap_Sa = convertCovariance(wvap_Sa,log(prior.h2o),@(x,y)exp(x));
% Add this to prior structure

sa = blkdiag(temp_Sa, wvap_Sa);

%%%%%
% Ancillary sensor data
%
% This is the remaining metadata needed to control the LBLRTM runs;
% specifically, the FTS scanning parameters, and the wavenumber
% range
sensor_params.wavenum = [175, 1025];
wnRange = sensor_params.wavenum;
sensor_params.FTSparams = [1.0, 200, 1000, 1.0];

%%%%%
% First guess
%
% Forward model run at prior state, and the associated jacobian - 
% These would normally be pre-computed, but in this case I'll use
% the code itself to generate them (the if-block following is a
% clumsy MATLAB method to create it once and then reload it if it
% can find a previously written save file

% cleanup_flag = true;
% [wn, prior_radiance] = ...
%     simple_matlab_lblrun(cleanup_flag, prior.stdatm_flag, profile, ...
%                          sensor_params.wavenum, ...
%                          'FTSparams', sensor_params.FTSparams);
% [wn, prior_K] = ...
%     simple_matlab_AJ_lblrun(cleanup_flag, prior.stdatm_flag, profile, ...
%                             sensor_params.wavenum, ...
%                             'FTSparams', sensor_params.FTSparams, ...
%                             'CalcJacobian', [0,1]);
% 
% prior_F.Fxhat = prior_radiance;
% prior_F.K = prior_K;

% assign masks - the channel_mask can be used to do limited 
% microwindowing. The state_mask is not tested for any cases other
% than full T/ln(Q) profile retrievals. (see comments in 
% simple_nonlinear_retrieval.m)
%channel_mask = true(length(wn),1);
%state_mask = true(nlevels*2,1);

lblArgs = {};
lblArgs{1} = 'FTSparams';
lblArgs{2}= sensor_params.FTSparams;

% Now, generate an observation at a different profile; make 
% this a perturbation from the prior - a dry layer at low alt., 
% and a warm layer at high alt.
truth_profile = profile;
truth_profile.tdry(15:21) = ...
    truth_profile.tdry(15:21) + [1,2,3,3,3,2,1]';
truth_profile.h2o(1:7) = ...
    truth_profile.h2o(1:7) .* [0.7,0.4,0.4,0.4,0.4,0.4,0.7]';
[wn, obs_radiance] = ...
    simple_matlab_lblrun(cleanup_flag, prior.stdatm_flag, truth_profile, ...
                         sensor_params.wavenum, ...
                         lblArgs{:});
                     
                     

% Add simulated instrument noise - fix the rand seed so this is
% repeatable
% s = RandStream('mt19937ar','seed',9);
% RandStream.setDefaultStream(s);
%obs_radiance = obs_radiance + sqrt(diag(se)).*randn(length(wn),1);

% run the retrieval
% [xhat_final, convergence_met, iter, xhat, G, A, K, Fxhat] = ...
%     simple_nonlinear_retrieval(prior, prior_F, Se, ...
%                                channel_mask, state_mask, obs_radiance, ...
%                                sensor_params);

se = diag(ones(size(obs_radiance))*1e-14);
channel_mask = true(size(obs_radiance));
state_mask = reshape(prior.h2o~=truth_profile.h2o,[],1);
state_mask = [true(size(prior.tdry));state_mask];
                           
[xhat_final,iter, final_prof] = ...
        LMRetrieval(prior,sa,obs_radiance, se, wnRange, lblArgs,...
        aJParams,prior.stdatm_flag,channel_mask,state_mask);                           

% Recompute hatS (this is computed inside the nonlinear retrieval,
% I'm not sure why I don't output that - easy to change that,
% though)
%hatS = inv(K{end}'*inv(Se(channel_mask,channel_mask))*K{end} + inv(prior.S_a));
