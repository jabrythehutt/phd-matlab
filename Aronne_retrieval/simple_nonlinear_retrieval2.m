function [xhat_final, convergence_met, iter, xhat, G, A, K, hatS, Fxhat, final_prof] = ...
    simple_nonlinear_retrieval2(prior_prof,sa,fully, fullSe, ...
    wnRange, lblArgs, aJParams,channel_mask, state_mask,convergence_limit,max_iteration_count)

%Updated version of simple_nonlinear_retrieval to generate prior_F rather 
%than take it as an input arg 


%
%function [xhat_final, convergence_met, iteration_count, 
%          xhat, G, A, K, Fxhat] = ...
%    simple_nonlinear_retrieval(prior, prior_F, fullSe,
%       channel_mask, state_mask, fully, sensor_params, 
%       convergence_limit)
%
% Inputs:
% prior - structure containing various fields describing the prior:
%    (all fields are required, all level-dependent variables are 
%    vectors with shape (L,1))
%    x0: the first guess state vector.
%    alt: level altitudes [km] 
%    pres: level pressures [hPa]
%    co2, o3, n2o, co, ch4: gas concentrations [ppmv], note these
%        are not retrieved, but included in the forward model run.
%    stdatm_flag: scalar variable with the standard atm. flag.
%    Tsurf: surface temperature [K]
%    esurf: surface emissivity (greybody), [unitless]
%    S_a: prior covariance matrix for T and ln(q), in a matrix
%        with shape matching x0 (e.g. if x0 is shaped (N,1), then
%        S_a must be (N,N)) 
% prior_F - structure containing forward model evaluations for the
%    prior state. must contain:
%    K: Jacobian at first guess (x0), shape (M,2*L), where L is the
%        number of levels and M is the number of spectral channels
%    Fxhat: The forward model run at the first guess, F(x0).
%        should be a vector with length (M,1)
% fullSe: (M,M) matrix containing measurement error covariance;
%    should have units [W/(cm^2 sr cm^-1)]^2 to match LBLRTM's 
%    computation
% channel_mask: (M,1) shaped logical vector, denoting channels to
%    use in the calculation (elements with value True), and which
%    to ignore (value False)
% state_mask: (2*L,1) shaped logical vector, denoting which state
%    variables to use. (same convention as channel_mask) Currently
%    this _must_ have true only for the T and ln(Q) elements of the
%    state vector, so that x0(state_mask) is a (2*L,1) vector with
%    temperature and ln(Q) stacked as [temp, ln(Q)].
% fully: (M,1) element observation vector. This should have units 
%    of [W/(cm^2 sr cm^-1)] to match LBLRTM's computation
% sensor_params: extra data describing observation, to pass to
%    LBLRTM. This should contain:
%    FTSparams: see create_tape5.m
%    wavenumber: 2-element vector with wavenumber range (1/cm) to
%        cover in the LBLRTM run.
% convergence_limit: convergence criteria, based on the mean change
%    in the state estimate (xhat), between interations, relative to
%    the posterior state error estimate (hatS). The default here is
%    0.1;
%
% outputs:
%   xhat_final - the retrieval, shaped (2*L)
%   convergence_met - logical scalar, specifying whether the convergence
%       limit was met.
%   iteration_count - number of iterations that occured
%   xhat - cell array containing state estimate at each iteration,
%       only for those variables flagged by state_mask.
%   G, A, K, Fxhat- cell arrays containing these matrices at each 
%       iteration. Any dimension corresponding to the measurement
%       vector will have length M', where M' is the number of
%       channels identified by the channel_mask.
%
% Note: the addition of the state mask was added to allow for
% partial retrievals and retrievals of other trace gases. However,
% the code is really limited to function for only T/ln(Q) profile
% retrievals, due to the hardcoded translation between xhat and the
% profile data needed by LBLRTM inside the lblrtm_update_K function.
%

nretrs = size(fully,2);

if nretrs > 1
    error('This routine can only retrieve a single profile');
end

if ~exist('convergence_limit','var')
    % this is compared with the sum of variance in the state estimate, 
    % scaled by the state estimate's covariance. This is akin to a
    % chi-squared test (normalized w.r.t. to ndof = length of state vec.)
    % somewhat arbitrarly, picked 0.1 here, so that the change is ~ 10% of
    % the expected uncertainty. I.e. a bit conservative, erring on the side
    % of extra iterations.
    convergence_limit = 0.1;
end


if ~exist('max_iteration_count','var')
    
    max_iteration_count = 10;
end


if ~exist('cleanup_work_dir','var')
    cleanup_work_dir=true;
end

if ~exist('aJParams','var')
    aJParams = [0,1];
end

%Generate prior_F from prior
prior_F= [];

lblArgsWJ = lblArgs;

lblArgsWJ{end+1} = 'CalcJacobian';
lblArgsWJ{end+1} =  aJParams;

[wn, prior_F.Fxhat] = simple_matlab_lblrun(...
    cleanup_work_dir, 1, prior_prof, wnRange, lblArgs{:});

[wn, prior_F.K] = simple_matlab_AJ_lblrun(...
    cleanup_work_dir, 1, prior_prof, wnRange,  lblArgsWJ{:});


%Construct xa and convert molecular concentrations to log values

xa = zeros(length(aJParams)*length(prior_prof.pres),1);


delta = length(prior_prof.pres);
ix = 1;
allMols = lower(molecules());
Sa = sa;
for i =1:length(aJParams)
    p = aJParams(i);
    
    if p==0
        
        xa(ix:ix+delta-1)=prior_prof.tdry;
    elseif p>0

        mol = allMols(p);
        xa(ix:ix+delta-1)=log(prior_prof.(mol));

        %Also convert covariance
        Sa(ix:ix+delta-1,ix:ix+delta-1)=convertCovariance(...
        Sa(ix:ix+delta-1,ix:ix+delta-1),prior_prof.(mol),@(x,y)log(x));
        
    end
    
    
    ix = ix+delta;
end


inv_Sa = inv(Sa);

% apply channel sub mask

y = fully(channel_mask, :);
Se = fullSe(channel_mask, channel_mask);

% invert S_e
%inv_Se = inv(Se);

% use optimal linear (or Gauss Newton, in the future - will need to
% recompute K in that case.), to estimate xhat.

convergence_met = false;
iter = 1;
K = cell(max_iteration_count,1);
xhat = cell(max_iteration_count+1,1);
Fxhat = cell(max_iteration_count,1);
G = cell(max_iteration_count,1);
A = cell(max_iteration_count,1);
hatS = cell(max_iteration_count,1);


fullx=xa;
%xhat{1} = xa;

xhat{1} = fullx;

%Fxhat{1} = prior_F.Fxhat(channel_mask);
%K{1} = prior_F.K(channel_mask,state_mask);


Fxhat{1} = prior_F.Fxhat;
K{1} = prior_F.K;
tic

while ~convergence_met && (iter <= max_iteration_count)

    if iter > 1
        %K{iter} = null_update_K(K{iter-1}, xhat{iter});
        %Fxhat{iter} = Fxhat{iter-1};
        %fullx(state_mask)=xhat{iter};
        
        fullx=xhat{iter};
        
        [newFullK, newy, lblrtm_success] = ...
            lblrtm_update_K2(fullx, wnRange,lblArgs, aJParams, cleanup_work_dir);
        
        
        
        % note this is not a full K - only the first 2 rows
        % (Tsurf & esurf) need to be dropped.
        if size(newFullK,2) ~= length(xa);
            disp(['Fwd model did not return a full sized K, returning ' ...
                  'failed run']);
            lblrtm_success = false;
        end
        if lblrtm_success
%             K{iter} = newFullK(channel_mask,state_mask);
%             Fxhat{iter} = newy(channel_mask);

            if (length(newFullK)+1)==length(channel_mask)
                newFullK = [newFullK;newFullK(end,:)];
                newy = [newy;newy(end)];
            end
            
            
            
            K{iter} = newFullK;
            Fxhat{iter} = newy;
        else
            break
        end
    end
    
    kiter = K{iter};
    kiter = kiter(channel_mask,state_mask);
    
    fxhatiter = Fxhat{iter};    
        
    fxhatiter = fxhatiter(channel_mask);
    
    
    xhatiter = xhat{iter};
    xhatiter = xhatiter(state_mask);
    
    
    inv_hatS = kiter' * Se \ kiter + inv_Sa;
    G{iter} = inv_hatS \ kiter' / Se;
    A{iter} = G{iter} * kiter;
    
    hatS{iter} = inv(inv_hadS);
    
%     inv_hatS = kiter' * inv_Se * kiter + inv_Sa;
%     hatS = inv(inv_hatS);
%     G{iter} = hatS * kiter' * inv_Se;
%     A{iter} = G{iter} * kiter;

    ylocal = y - fxhatiter + kiter*(xhatiter - xa);
    
     xhatin = G{iter} * ylocal + xa;
     
     

    xhat{iter+1} = xhat{iter};
    xhat{iter+1}(state_mask)=xhatin;

    if iter > 1
        % note, not using Rodgers' "shortcut" (Eq. 5.31), since I am not
        % computing xhat the same way (I want to save A, G). In any case, 
        % the computation time difference is trivial w.r.t. forward model 
        % time, so this is an insignificant penalty.
        dxhat = xhatin - xhatiter;
        d2_test = dxhat' * inv_hatS * dxhat / length(xa);
        convergence_met = d2_test < convergence_limit;
    end
    fprintf('Completed iteration %d , time elapsed %f minutes\n', iter, toc/60);
    iter = iter + 1;

end

if iter <= max_iteration_count
    G = G(1:iter-1);
    A = A(1:iter-1);
    K = K(1:iter-1);
    hatS = hatS(1:iter-1);
    xhat = xhat(1:iter);
    Fxhat = Fxhat(1:iter-1);
end


xhat_final=xhat{end};



%Create an output profile by converting back from log
final_prof = prior_prof;

allMols = lower(molecules());
ix = 1;
delta = length(final_prof.tdry);

for i=1:length(aJParams)
    p = aJParams(i);
    vec = xhat(ix:ix+delta-1);
    
    if p==0
        
        
        final_prof.tdry=vec;
        
    elseif p>0
        
        m = allMols{p};
        
        final_prof.(m)=exp(vec);
        
    end
    ix = ix+delta;
end




