function UTrials = getUTrials(r)
%GETUTRIALS Return table entries corresponding to unique trial elements
%
%  UTrials = analyze.rec.getUTrials(r);
%
%  This would be done for example by doing:
%  ```
%     >> r = utils.loadTables('rates');
%     >> UTrials = analyze.rec.getUTrials(r);
%  ```
%
% Inputs
%  r - Table that has variable 'Trial_ID' (trial identifier)
%
% Output
%  UTrials - Table used in trial/behavioral analyses (see:
%     trial_outcome_stats, trial_duration_stats)
%
% See also: analyze.rec

iExclude = isinf(r.Duration) | isnan(r.Complete) | isnan(r.Grasp) | isnan(r.Reach) | isinf(r.Grasp);
if isfield(r.Properties.UserData,'Excluded')
   r.Properties.UserData.Excluded(iExclude) = [];
end
r(iExclude,:) = [];

[~,iU] = unique(r.Trial_ID);
UTrials = r(iU,:);
UTrials.Properties.UserData.Type = 'UniqueTrials';
UTrials.Reach_Epoch_Proportion = UTrials.Reach_Epoch_Duration ./ UTrials.Duration;
UTrials.Properties.VariableUnits{'Reach_Epoch_Proportion'} = 'fraction';
UTrials = analyze.behavior.getDescriptiveTimingStats(UTrials,'Duration');
UTrials = analyze.behavior.getDescriptiveTimingStats(UTrials,'Reach_Epoch_Duration');
UTrials = analyze.behavior.getDescriptiveTimingStats(UTrials,'Retract_Epoch_Duration');
UTrials = analyze.behavior.getDescriptiveTimingStats(UTrials,'Reach_Epoch_Proportion');
UTrials = analyze.behavior.makeSupportAssociation(UTrials);

UTrials.Properties.UserData.Excluded = UTrials.Properties.UserData.Excluded(iU);
end