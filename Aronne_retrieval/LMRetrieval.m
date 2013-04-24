function [xhat_final, iter, final_prof] = ...
    LMRetrieval(prior_prof,sa,fully, fullSe, ...
    wnRange, lblArgs, aJParams,defaultAtm,channel_mask, state_mask,convergence_limit,max_iteration_count)



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

if ~exist('state_mask','var')
    state_mask = true(length(aJParams)*length(prior_prof.tdry),1);
    

end

if ~exist('channel_mask','var')
    
    channel_mask = true(length(fully),1);
    
end

if ~exist('defaultAtm','var')
    
    defaultAtm = 1;
end

convMap = containers.Map('KeyType','uint32','ValueType','any');
invConvMap = containers.Map('KeyType','uint32','ValueType','any');
for i = 1:length(aJParams)
    param = aJParams(i);
    if param>0 
        convMap(param) = @(x)exp(x);
        invConvMap(param) = @(x)log(x);
    end
    
end

fM = ForwardModel(prior_prof,wnRange,lblArgs,aJParams,defaultAtm,convMap,invConvMap,channel_mask,state_mask,cleanup_work_dir);


%Generate prior_F from prior
prior_F= [];



xa  = extractStateVector(prior_prof,aJParams,state_mask,invConvMap);

% [prior_F.Fxhat,wn] = fM.calculateRadiance(xa);
% 
% [prior_F.K,wn] = fM.calculateJacobian(xa);

delta = length(prior_prof.pres);
ix = 1;
allMols = lower(molecules());
Sa = sa;
%This presumes zero covariance between different AJ parameters
for i =1:length(aJParams)
    p = aJParams(i);
    mol = 'tdry';
    
    if p>0
        
        mol = allMols{p};
        
    end
    
    if isKey(invConvMap,p)

        convFun = invConvMap(p);

        %Also convert covariance
        Sa(ix:ix+delta-1,ix:ix+delta-1)=convertCovariance(...
        Sa(ix:ix+delta-1,ix:ix+delta-1),prior_prof.(mol),@(x,y)convFun(x));
        
    end
    
    
    ix = ix+delta;
end


inv_Sa = inv(Sa(state_mask,state_mask));

% apply channel sub mask

y = fully(channel_mask, :);
Se = fullSe(channel_mask, channel_mask);

radFn = @(x)fM.calculateRadiance(x);
jacFn = @(x)fM.calculateJacobian(x);

%Use D=inv_sa as in Rodgers (2000) p.93
[xhat_final, S, iter] = LMFsolve(radFn,xa,'CustJac',jacFn,'ScaleD',inv_Sa,...
    'MaxIter',max_iteration_count,'Display',1,'FunTol',1e-9);

final_prof= updateProfile(xhat_final,prior_prof,aJParams,state_mask,convMap);


end


