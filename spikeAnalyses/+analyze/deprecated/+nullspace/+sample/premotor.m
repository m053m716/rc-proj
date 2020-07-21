function TID = premotor(X,t_premotor)
%PREMOTOR  Sample "premotor" alignment
%
%  TID = analyze.nullspace.sample.premotor(X,t_premotor);
%
%  -- Inputs --
%  X  :  Table generated using `X = analyze.nullspace.get_subset(T);`
%  t_premotor : Times, relative to 'Reach' alignment, to consider
%                 "premotor" activity.
%
%  -- Output --
%  TID  : Table corresponding to rows of `Rate` (channels)
%           -> TID.Properties.UserData.t corresponds to columns of `Rate`

if nargin < 2
   t_premotor = defaults.nullspace_analyses('t_premotor');
end

x = analyze.slice(X,'Alignment','Reach');
t_orig = x.Properties.UserData.t;
t_mask = t_orig >= t_premotor(1) & t_orig <= t_premotor(2);

[G,TID] = findgroups(x(:,{'Group','AnimalID','BlockID','Area','Channel'}));
TID.Properties.UserData.t_orig = t_orig;
TID.Properties.UserData.t_mask = t_mask;
[rate,nTrial] = splitapply(@(y)concat_trials_by_channel(y,t_mask),x.Rate,G);
if any(nTrial ~= nTrial(1))
   warning('Not all channels present for all trials (%s-Day-%02g)',...
      char(X.AnimalID(1)),X.PostOpDay(1));
end
TID.nTrial = nTrial;
t_rel = t_orig(t_mask);
TID.Properties.UserData.t_rate = repmat(t_rel,1,nTrial(1));
TID.Rate = cell2mat(rate);

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
      nTrial = size(y,1);
      y = y(:,t_mask).';
      Y = y(:);
      Y = {Y.'};
   end

end