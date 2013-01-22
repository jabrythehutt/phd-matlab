function [surftemp_rms, temp_rms, q_rms, surftemp_mean, temp_mean, q_mean] = ...
    compute_retrieval_rms(xhat, x)
% function [surftemp_rms, temp_rms, q_rms] = compute_retrieval_rms(xhat, x)
%
% compute RMS error for surface temperature, temperature profile, and 
% humidity profile, from retrieved parameters.

% assumes 2*N + levels - N for temperature profile, N for humidity profile,
% and 1 for surface temperature (which is the same as the bottom level).
nlevels = size(x, 1) / 2;

% convert log q back to q.
xhat2 = xhat;
x2 = x;
xhat2(nlevels+1:end,:) = exp(xhat2(nlevels+1:end,:));
x2(nlevels+1:end,:) = exp(x2(nlevels+1:end,:));
xdiff = xhat2 - x2;

surftemp_rms = std(xdiff(1,:),0,2);
temp_rms = std(xdiff(1:nlevels,:),0,2);
q_rms = std(xdiff(nlevels+1:end,:),0,2);

surftemp_mean = mean(xdiff(1,:),2);
temp_mean = mean(xdiff(1:nlevels,:),2);
q_mean = mean(xdiff(nlevels+1:end,:),2);
