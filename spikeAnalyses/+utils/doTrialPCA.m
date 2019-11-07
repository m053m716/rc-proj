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
%                 Can also be provided as a struct that must at least have
%                    a field 'X' that is the original data matrix. This
%                    format makes it easier to "redo" PCA on a
%                    previously-run pcStruct.
%
% By: Max Murphy  v1.0  2019-10-17  Original version (R2017a)
%                 v1.1  2019-10-30  Updated to take struct input

%% Simple code just for keeping things organized
if ~isstruct(X) % If X is provided as a data matrix
   pcStruct = struct;
   [pcStruct.coeff,pcStruct.score,pcStruct.latent,...
      pcStruct.tsquared,pcStruct.explained,pcStruct.mu] = ...
         pca(X,'Economy',false);
   pcStruct.X = X;
   
else % In the case that X is provided as "xPC" struct
   pcStruct = X;
   [pcStruct.coeff,pcStruct.score,pcStruct.latent,...
      pcStruct.tsquared,pcStruct.explained,pcStruct.mu] = ...
         pca(pcStruct.X,'Economy',false);
end
   
%%

end