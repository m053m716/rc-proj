function [rSub,r] = get_subset(r,varargin)
%GET_SUBSET  Returns subset of full table for "marginalization" analyses
%
%  [rSub,r] = analyze.get_subset(r);
%  e.g.
%     >> [rSub,r] = analyze.get_subset(r); % Table of spike counts
%
%  -- Inputs --
%  r : Table with behavioral time fields, PelletPresent field
%  varargin : (Optional) <'name',value> pairs
%     - 'min_dur' : Minimum value for Total trial duration (inclusive, sec)
%     - 'max_dur' : Maximum value for Total trial duration (exclusive, sec)
%     - 'align'   : Cell array of included alignment events ({'Reach','Grasp'})
%     - 'max_reach' : Max duration (sec, exclusive) for Reach epoch/phase
%     - 'max_retract' : Max duration (sec, exclusive) for Retract epoch/phase
%     - 'min_rate' : Minimum (total spikes)/(trial duration)
%     - 'max_rate' : Maximum (total spikes)/(trial duration)
%
%  -- Output --
%  rSub : Table in same format, but has subset meeting following criteria:
%        -> Duration is >= 100ms and <= 1500ms
%        -> Reach Phase is <= 650 ms
%        -> Retract Phase is <= 750 ms
%        -> Rate >= 6.5 spikes/sec & <= 300 spikes/sec averaged on Trial.
%        -> Reach, Grasp, Complete, and Pellet are all present.
%  r    : Original data table
%
% See also: unit_learning_stats, analyze, analyze.behavior, analyze.stats

pars = struct;
[pars.min_dur,pars.max_dur,pars.align,pars.max_reach,pars.max_retract,pars.min_rate,pars.max_rate] =  ...
   defaults.complete_analyses(...
      'min_duration','max_duration','alignment_events',...
      'max_reach','max_retract','min_rate','max_rate');
fn = fieldnames(pars);
if numel(varargin) > 0
   if isstruct(varargin{1})
      pars = varargin{1};
      varargin(1) = [];
   end
end
for iV = 1:2:numel(varargin)
   idx = strcmpi(fn,varargin{iV});
   if sum(idx)==1
      pars.(fn{idx}) = varargin{iV+1};
   end
end

if ~ismember('Duration',r.Properties.VariableNames)
   r.Duration = r.Complete - r.Reach;
   r.Properties.VariableUnits{'Duration'} = 'sec';
end
if ~ismember('Reach_Epoch_Duration',r.Properties.VariableNames)
   r.Reach_Epoch_Duration = r.Grasp - r.Reach;
   r.Properties.VariableUnits{'Reach_Epoch_Duration'} = 'sec';
end
if ~ismember('Retract_Epoch_Duration',r.Properties.VariableNames)
   r.Retract_Epoch_Duration = r.Complete - r.Grasp;
   r.Properties.VariableUnits{'Retract_Epoch_Duration'} = 'sec';
end

iDuration = (r.Duration>=pars.min_dur) & (r.Duration < pars.max_dur);
iReach = r.Reach_Epoch_Duration < pars.max_reach;
iRetract = r.Retract_Epoch_Duration < pars.max_retract;

iAlign = ismember(string(r.Alignment),string(pars.align));
hasPellet = (r.PelletPresent=='Present') & (~isundefined(r.PelletPresent));
hasReach = ~isnan(r.Reach) & ~isinf(r.Reach);
hasGrasp = ~isnan(r.Grasp) & ~isinf(r.Grasp);
hasComplete = ~isnan(r.Complete) & ~isinf(r.Complete);

tTotal = (r.Properties.UserData.t(end)-r.Properties.UserData.t(1))*1e-3; % convert to seconds
iRateHighEnough = (r.N_Total./tTotal) >= pars.min_rate;
iRateLowEnough = (r.N_Total./tTotal) <= pars.max_rate;

if ismember('PostOpDay',r.Properties.VariableNames)
   r.Day = r.PostOpDay;
   r.Week = ceil(r.PostOpDay/7);
elseif ismember('Day',r.Properties.VariableNames)
   r.PostOpDay = r.Day;
   r.Week = ceil(r.PostOpDay/7);
end

% % Do Row exclusion % %
iKeep = iDuration & iReach & iRetract & iAlign & hasPellet & hasReach & hasGrasp & hasComplete & iRateHighEnough & iRateLowEnough;
rSub = r(iKeep,:);
r.Properties.UserData.Excluded = ~iKeep;


rSub.Properties.UserData.iDuration = iDuration;
rSub.Properties.UserData.iReach = iReach;
rSub.Properties.UserData.iRetract = iRetract;
rSub.Properties.UserData.iAlign = iAlign;
rSub.Properties.UserData.hasPellet = hasPellet;
rSub.Properties.UserData.hasReach = hasReach;
rSub.Properties.UserData.hasGrasp = hasGrasp;
rSub.Properties.UserData.hasComplete = hasComplete;
rSub.Properties.UserData.iRateHighEnough = iRateHighEnough;
rSub.Properties.UserData.iRateLowEnough = iRateLowEnough;
rSub.Properties.UserData.Excluded = false(size(rSub,1),1);
rSub = utils.addProcessing(rSub,'Subset');
end