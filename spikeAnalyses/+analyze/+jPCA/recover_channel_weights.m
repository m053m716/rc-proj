function out = recover_channel_weights(P,S)
%RECOVER_CHANNEL_WEIGHTS Recover weightings for individual channels jPCs
%
%  out = analyze.jPCA.recover_channel_weights(P,S);
%
% Inputs
%  P   - Projection struct array from analyze.jPCA
%  S   - Summary struct from analyze.jPCA that matches `P`
%
% Output
%  out - Scalar cell. Cell contains:
%        Updated projection struct array with new field: 'W'
%        -> 'W' is the weightings for original rate data, using jPCA matrix

n = size(P(1).state,1); % # samples per trial
nTrial = numel(P); 
M = analyze.jPCA.convert_Mskew_to_jPCs(S.Mskew);
nPC = size(M,1);
C = S.PCA.vectors_all; 

% Principal components map scores onto rates as: 
%     rates = scores * C' + repmat(mean(rates,1),n,1);
%
% We would like to recover the mapping from rates to scores, then map rates
% one channel at a time using the recovered transformation matrices, so we
% can see the related channel-specific activations when we look at a
% particular jPC plane.
Ci = inv(C'); 

% Create data matrix using original observed rates
X = vertcat(P.data);
X = X - nanmean(X); % Remove cross-condition mean from rates.
nChannels = size(X,2);

% Our "activations" are therefore a tensor that is different for each
% channel.
W = nan(size(X,1),nPC,nChannels);

% Use projection matrix and PC coefficients to recover rotated rates
for iCh = 1:nChannels
   W(:,:,iCh) = X(:,iCh)*Ci(iCh,1:nPC)*M;
end

% Distribute back as individual trials
Wc = mat2cell(W,ones(1,nTrial).*n,nPC,nChannels);
[P.W] = deal(Wc{:});

% Wrap it as a cell so we can use with `splitapply` workflow
out = {P};

end