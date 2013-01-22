function [fullxhat, G, A] = simple_linear_retrieval( ...
    fullK, channel_mask, fullSe, fullSa, fully, fullx0, state_mask)

% apply channel sub mask
K = fullK(channel_mask, state_mask);
y = fully(channel_mask, :);
Se = fullSe(channel_mask, channel_mask);

% apply state mask
Sa = fullSa(state_mask, state_mask);
x0 = fullx0(state_mask);

% invert S_a, 
% ToDo: perhaps add a catch for regularization, if needed.
inv_Sa = inv(Sa);

% invert S_e
inv_Se = inv(Se);

% use optimal linear (or Gauss Newton, in the future - will need to
% recompute K in that case.), to estimate xhat.

hatS = inv(K' * inv_Se * K + inv_Sa);
G = hatS * K' * inv_Se;
A = G * K;

nretrs = size(y,2);
y = fully(channel_mask,:);
%xhat = G * y + repmat(x0, [1, nretrs]);
xhat = G * y;

% state estimate will only "update" the variables called out by the mask.
nretr = size(fully,2);
fullxhat = repmat(fullx0, [1, nretr]);
fullxhat(state_mask,:) = fullxhat(state_mask,:) + xhat;
