function T = get_subset(T,varargin)
%GET_SUBSET  Returns subset of full table for "marginalization" analyses
%
%  T = analyze.get_subset(T);
%  e.g.
%     >> r = analyze.get_subset(r); % Table of spike counts
%
%  -- Inputs --
%  T : Table with behavioral time fields, PelletPresent field
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
%  T : Table in same format, but has subset meeting following criteria:
%        -> Duration is >= 100ms and <= 750ms
%        -> Reach, Grasp, Complete, and Pellet are all present.

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

if ~ismember('Duration',T.Properties.VariableNames)
   T.Duration = T.Complete - T.Reach;
   T.Properties.VariableUnits{'Duration'} = 'sec';
end
if ~ismember('Reach_Epoch_Duration',T.Properties.VariableNames)
   T.Reach_Epoch_Duration = T.Grasp - T.Reach;
   T.Properties.VariableUnits{'Reach_Epoch_Duration'} = 'sec';
end
if ~ismember('Retract_Epoch_Duration',T.Properties.VariableNames)
   T.Retract_Epoch_Duration = T.Complete - T.Grasp;
   T.Properties.VariableUnits{'Retract_Epoch_Duration'} = 'sec';
end

iDuration = (T.Duration>=pars.min_dur) & (T.Duration < pars.max_dur);
iReach = T.Reach_Epoch_Duration < pars.max_reach;
iRetract = T.Retract_Epoch_Duration < pars.max_retract;

iAlign = ismember(string(T.Alignment),string(pars.align));
hasPellet = (T.PelletPresent=='Present') & (~isundefined(T.PelletPresent));
hasReach = ~isnan(T.Reach) & ~isinf(T.Reach);
hasGrasp = ~isnan(T.Grasp) & ~isinf(T.Grasp);
hasComplete = ~isnan(T.Complete) & ~isinf(T.Complete);

tTotal = (T.Properties.UserData.t(end)-T.Properties.UserData.t(1))*1e-3; % convert to seconds
iRateHighEnough = (T.N_Total./tTotal) >= pars.min_rate;
iRateLowEnough = (T.N_Total./tTotal) <= pars.max_rate;

% % Do Row exclusion % %
iKeep = iDuration & iReach & iRetract & iAlign & hasPellet & hasReach & hasGrasp & hasComplete & iRateHighEnough & iRateLowEnough;
T = T(iKeep,:);
if ismember('PostOpDay',T.Properties.VariableNames)
   T.Day = T.PostOpDay;
   T.Week = ceil(T.PostOpDay/7);
elseif ismember('Day',T.Properties.VariableNames)
   T.PostOpDay = T.Day;
   T.Week = ceil(T.PostOpDay/7);
end

T.Properties.UserData.iDuration = iDuration;
T.Properties.UserData.iReach = iReach;
T.Properties.UserData.iRetract = iRetract;
T.Properties.UserData.iAlign = iAlign;
T.Properties.UserData.hasPellet = hasPellet;
T.Properties.UserData.hasReach = hasReach;
T.Properties.UserData.hasGrasp = hasGrasp;
T.Properties.UserData.hasComplete = hasComplete;
T.Properties.UserData.iRateHighEnough = iRateHighEnough;
T.Properties.UserData.iRateLowEnough = iRateLowEnough;
T.Properties.UserData.Excluded = false(size(T,1),1);
% if isfield(T.Properties.UserData,'Excluded')
%    T.Properties.UserData.Excluded = T.Properties.UserData.Excluded(iKeep);
% end

end