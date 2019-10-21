function pcStruct = doTrialPCA(X)
%% DOTRIALPCA  Do PCA where rows are channels and columns are concatenated time-series
%
%  pcStruct = DOTRIALPCA(X);
%
%  --------
%   INPUTS
%  --------
%     X     :     Data matrix. Columns are neurons or channels; rows are
%                    times (samples). Trials are concatenated through time
%                    so that the last sample of a given trial may have a
%                    discontinuity with the subsequent trial.
%
% By: Max Murphy  v1.0  2019-10-17  Original version (R2017a)

%% Simple code just for keeping things organized
pcStruct = struct;
[pcStruct.coeff,pcStruct.score,pcStruct.latent,...
   pcStruct.tsquared,pcStruct.explained,pcStruct.mu] = ...
      pca(X);
   
%%

end