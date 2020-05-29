function [M,mu,MID] = subtract_rat_means(M,grouping)
%SUBTRACT_RAT_MEANS  Remove mean spike rate by AnimalID from each trial
%
% M = analyze.marg.subtract_rat_means(M,grouping);
% [M,mu,MID] = analyze.marg.subtract_rat_means(M,grouping);
%
% Inputs
%  M        - Data table from `M = analyze.marg.get_subset(T);`
%  grouping - Cell array of grouping variables (Optional)
%              -> Default is:
%              {'AnimalID','Area','Channel','Alignment','Outcome'}
%
% Output
%  M - Same as input, but each row has the mean spike rate subtracted
%        according to `AnimalID` (on a per-area/per-channel basis, applied
%        to each individual rate trace for all trials).
%        * Note: this is also split by Alignment, since it doesn't make
%           sense to subtract 'Reach' aligned trials from 'Grasp' aligned
%           ones...
%  mu   - Rows are different Animal/Area/Channel combinations; columns are
%           time-series samples for marginal rates by that grouping
%  MID  - Rows of this table indicate groupings used for `mu`
%
%  -> Adds to the `M.Properties.UserData.Processing` tab that tracks what
%     has been done to the data.

if nargin < 2
   grouping = {'AnimalID','Area','Channel','Alignment','Outcome'};
end

[G,MID] = findgroups(M(:,grouping));
mu = cell2mat(splitapply(@(rate){mean(rate,1)},M.Rate,G));
[~,iM,iMean] = outerjoin(M,MID);
M.Rate(iM,:) = M.Rate(iM,:) - mu(iMean,:);

if ~isstruct(M.Properties.UserData)
   M.Properties.UserData = struct;
end
if isfield(M.Properties.UserData,'Marginalization')
   nMarg = numel(M.Properties.UserData.Marginalization)+1;
else
   nMarg = 1;
end
marg_str = sprintf('Marg-%g-Subtracted',nMarg);
M = utils.addProcessing(M,marg_str);
M = utils.addMarginalization(M,grouping,MID,mu);
end