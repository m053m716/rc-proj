function D = grasp(X,t_event,t_reduced)
%GRASP  Sample "grasp" alignment
%
%  D = analyze.nullspace.sample.grasp(X);
%  [D,C] = analyze.nullspace.sample.grasp(X,t_premotor,t_reduced);
%
%  -- Inputs --
%  X  :  Table generated using `X = analyze.nullspace.get_subset(T);`
%  t_event : Times, relative to 'Grasp' alignment, to consider
%                 "event" activity.
%  t_reduced : Reduced sampling range for estimating PCs.
%
%  -- Output --
%  D  : Table corresponding to rows of `rate` (channels)
%           -> D.Properties.UserData.t corresponds to columns of `rate`
if nargin < 3
   t_reduced = defaults.nullspace_analyses('t_reduced');
end

if nargin < 2
   t_event = defaults.nullspace_analyses('t_event');
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
D.Properties.UserData.t_rate = repmat(t_rel,1,nTrial(1));
D.Rate = cell2mat(rate);
[coeff,score,~,~,explained,mu] = pca(D.Rate.');
D.Score = score.';
D.Mu = mu.';
D.Coeff = coeff;
D.Explained = explained;
D.Properties.UserData.ReconFcn = @analyze.pc.reconstruct;
D.Properties.UserData.ReconNote = ...
   'Rate = feval(D.Properties.UserData.ReconFcn,D.Score,D.Coeff,D.Mu,nComponents);';

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