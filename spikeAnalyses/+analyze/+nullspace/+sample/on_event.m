function TID = on_event(X,event)
%PREMOTOR  Sample at "zero" alignment for some event
%
%  TID = analyze.nullspace.sample.on_event(X,event);
%
%  -- Inputs --
%  X  :  Table generated using `X = analyze.nullspace.get_subset(T);`
%  t_premotor : Times, relative to 'Reach' alignment, to consider
%                 "premotor" activity.
%
%  -- Output --
%  TID  : Table corresponding to rows of `Rate` (channels)
%           -> TID.Properties.UserData.t corresponds to columns of `Rate`

t_on = defaults.nullspace_analyses('t_on');
t_orig = X.Properties.UserData.t;
t_mask = t_orig >= t_on(1) & t_orig <= t_on(2);
X = X(X.Alignment==event,:);
[G,TID] = findgroups(X(:,{'Group','AnimalID','BlockID','Area','Channel'}));
TID.State = splitapply(@(y)get_state(y,t_mask),X.Rate,G);

   function state = get_state(y,t_mask)
      %GET_STATE  Get average event-aligned state
      %
      %  state = get_state(y,t_mask);
      %  
      %  -- Inputs --
      %  y : Matrix of rate data, where rows are trials for a single
      %        channel and columns are binned time-samples.
      %  t_mask : Mask vector indicating which columns to keep.
      %
      %  -- Output --
      %  state : Scalar; average neural state at event alignment
      
      z = y(:,t_mask);
      state = mean(mean(z,2),1);
   end

end