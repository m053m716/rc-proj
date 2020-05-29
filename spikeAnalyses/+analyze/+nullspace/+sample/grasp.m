function D = grasp(X,t_reduced)
%GRASP  Sample "grasp" alignment
%
%  D = analyze.nullspace.sample.grasp(X,t_reduced);
%
%  -- Inputs --
%  X  :  Table generated using `X = analyze.nullspace.get_subset(T);`
%  t_reduced : Reduced sampling range for estimating PCs.
%
%  -- Output --
%  D  : Table corresponding to rows of `rate` (channels)
%           -> D.Properties.UserData.t corresponds to columns of `rate`
if nargin < 2
   t_reduced = defaults.nullspace_analyses('t_reduced');
end

X = X(X.Alignment=='Grasp',:);
t_orig = X.Properties.UserData.t;
t_mask = t_orig >= t_reduced(1) & t_orig <= t_reduced(2);

[G,D] = findgroups(X(:,{'Group','AnimalID','BlockID','Area','Channel'}));
D.Properties.UserData.t_orig = t_orig;
D.Properties.UserData.t_mask = t_mask;
[rate,nTrial] = splitapply(@(y)concat_trials_by_channel(y,t_mask),X.Rate,G);
if any(nTrial ~= nTrial(1))
   warning(['RC:' mfilename ':BadTableLayout'],...
      'Not all channels present for all trials (%s-Day-%02g)',...
      char(X.AnimalID(1)),X.PostOpDay(1));
end
D.nTrial = nTrial;
t_rel = t_orig(t_mask);
trial_index = ones(numel(t_rel),1) * (1:nTrial(1));
D.Properties.UserData.t = t_rel;
D.Properties.UserData.t_rate = repmat(t_rel,1,nTrial(1));
D.Properties.UserData.TrialIndex = trial_index;
D.Properties.UserData.NTrial = nTrial(1);
D.Rate = cell2mat(rate);
[coeff,score,~,~,explained,mu] = pca(D.Rate.');
D.Score = score.';
D.Mu = mu.';
D.Coeff = coeff;
D.Explained = explained;
D.Properties.Alignment = 'Grasp';
D.Properties.UserData.ReconFcn = ...
   @(n)analyze.pc.reconstruct(D.Score,D.Coeff,D.Mu,n);
D.Properties.UserData.TrialRateFcn = ...
   @(ch,idx)D.Rate(ch,D.Properties.UserData.TrialIndex==idx);
D.Properties.UserData.ReconNote = ...
   'Rate = D.Properties.UserData.ReconFcn(nComponents);';
D.Properties.UserData.TrialNote = ...
   'Rate = D.Properties.UserData.TrialRateFcn(iCh,iTrial);';

   function [Y,nTrial] = concat_trials_by_channel(y,t_mask)
      %CONCAT_TRIALS_BY_CHANNEL  Concatenate trials (rows) horizontally
      %
      %  [Y,nTrial] = concat_trials_by_channel(y,t_mask);
      %  
      %  -- Inputs --
      %  y : Matrix of rate data, where rows are trials for a single
      %        channel and columns are binned time-samples.
      %  t_mask : Mask vector indicating which columns to keep.
      %
      %  -- Output --
      %  Y : Cell containing a row vector of concatenated rate data for one
      %        channel.
      %  nTrial : Number of trials that were concatenated.
      
      y = y(:,t_mask);
      nTrial = size(y,1);
      y = y.';
      Y = y(:);
      Y = {Y.'};
   end

end