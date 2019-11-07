function xbar = doPCAreconstruction(score,coeff,mu)
%% DOPCARECONSTRUCTION  Y = utils.doPCAreconstruction(score,coeff,mu);
%
%  - Inputs -
%
%  score : PCA scores as returned by PCA applied to data matrix where rows
%            are timesteps and columns are recording channels. Score matrix
%            should be dimensions nTimesteps x nTimesteps, unless there are
%            more channels than nTimesteps, in which case it will be
%            nTimesteps x (nTimesteps - 1).
%
%  coeff : PCA coefficients as returned by PCA applied to data matrix where
%            rows are timesteps and columns are recording channels. Coeff
%            matrix should be nChannels x nTimesteps, or if nChannels >
%            nTimesteps, then it will be nChannels x (nTimesteps - 1).
%
%  mu    : Column averages of input data to PCA. Should be 1 x nChannels.
%
%  - Alternative Input -
%
%  score : "xPC" struct of GROUP class object (returned by XPCA method).
%
%  coeff : (Optional) Can be specified as the number of PCs to use in the
%              reconstruction (scalar int).
%
%  -- Output --
%
%  xbar : Reconstructed original data, or if only one input (struct) is
%           provided, then it is the input struct with either 'xbar' field
%           appended to it or 'xbar_red' field if a reduced number of
%           PCs are used for reconstruction (if coeff is specified).
%
% By: Max Murphy  2019-10-30  R2017a

%%
if isstruct(score)
   xPC = score;
   if nargin < 2
      xPC.xbar = xPC.score*(xPC.coeff') + xPC.mu;
      
      % These should be 0 and 1 respectively, or something is wrong
      xPC.mse = mean((xPC.X - xPC.xbar).^2,1);
      xPC.mse_norm = (xPC.mse./var(xPC.X,[],1));
      xPC.varcapt = 1 - xPC.mse_norm;
   else
      xPC.xbar_red = xPC.score(:,1:coeff)*(xPC.coeff(:,1:coeff)') + xPC.mu;
      xPC.li = coeff; % So that the # components used for xbar_red is known
      xPC.mse_red = mean((xPC.X - xPC.xbar_red).^2,1);
      xPC.mse_red_norm = (xPC.mse_red./var(xPC.X,[],1));
      xPC.varcapt_red = 1 - xPC.mse_red_norm;
   end
   
   xbar = xPC; % Output is still "xbar"
   
else % Otherwise just use the inputs as they are
   xbar = score*(coeff') + mu;
end


end