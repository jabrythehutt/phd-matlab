function [A,G,K] = rodgers_example()
    logp = linspace(0,10,101)';
    K = simulated_weighting_fn(logp)';
    Se = simulated_meas_covar(K,0.25);
    Sa = simulated_prior_covar(logp, 100);
    G = inv(K'*inv(Se)*K + inv(Sa)) * K' * inv(Se);
    A = G * K;
    trace(A)
end

function S = simulated_meas_covar(wf, variance);
    wf_dimen = size(wf);
    nmeas = wf_dimen(1);
    S = eye(nmeas) * variance;
end

function S = simulated_prior_covar(logp, variance);
    nn = length(logp);
    S = zeros(nn);
    for r = 1:nn
        for c = 1:r
            S(r,c) = variance * exp( -abs(r-c)*(-2*log(0.95)) );
            S(c,r) = S(r,c);
        end
    end
end

function wf = simulated_weighting_fn(logp)
    centers = exp(-2-0.75*(0:7)');
    
    wf = zeros(length(logp),length(centers));
    p = exp(-logp);
    % wf = p * exp(-p/pn);
    % (d/dp) wf = -p/pn exp(-p/pn) + exp(-p/pn)
    %   ==> max at p/pn = 1
    %   ==> max value = pn * exp(-1);
    for q=1:length(centers);
        A = 1./(centers(q));
        wf(:,q) = A * p .* exp( -p / centers(q) );
        if q==3
            norm=sum(wf(:,q));
            wf(:,q)=exp(-(logp+log(centers(q))).^2*40);
            wf(:,q)=wf(:,q)/sum(wf(:,q));
            wf(:,q)=wf(:,q)*norm;
        end
    end
end

function temp = simulated_temp_profile(logp);

    temp = zeros(length(logp),1);

    lapse_rate = (218-288)/1.5;
    mask = logp < 1.5;
    temp(mask) = 288 + logp(mask) * lapse_rate;

    mask = logp >= 1.5 & logp < 3.75;
    temp(mask) = 218;

    lapse_rate = (282-218)/(6.7-3.75);
    mask = logp >= 3.75 & logp < 6.7;
    temp(mask) = 218 + (logp(mask)-3.75) * lapse_rate;

    mask = logp >= 6.7 & logp < 7.4;
    temp(mask) = 282;

    lapse_rate = (215-282)/(10-7.4);
    mask = logp >= 7.4 & logp <= 10;
    temp(mask) = 282 + (logp(mask)-7.4) * lapse_rate;

    if any(logp > 10);
        disp('values of logp over 10 return 0');
    end

end % profile simulation
