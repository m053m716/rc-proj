function [rWeek,rSub] = getChannelWeeklyGroupings(rSub,grouping,doMerge)
%GETCHANNELWEEKLYGROUPINGS Returns weekly groupings table for unit_learning_stats
%
%  rWeek = analyze.trials.getChannelWeeklyGroupings(rSub);
%  [rWeek,rSub] = analyze.trials.getChannelWeeklyGroupings(rSub,grouping,doMerge);
%
% Inputs
%  rSub     - Subset of `r`, the table of raw spike counts
%  grouping - Grouping type ('animal' (def) | 'area' | 'channel')
%  doMerge  - (default: false); set true to automatically merge
%  
% Output
%  rWeek - Table with summarized epoch data that is aggregated on a
%           per-channel, per-week basis.
%  rSub  - Updated table (useful if `doMerge` == true)
%
% See also: analyze.trials, unit_learning_stats

if nargin < 3
   doMerge = false;
end

if nargin < 2
   grouping = 'Animal';
end

if doMerge
   rSub = analyze.behavior.mergeRatePerformance(rSub,true);
end


switch lower(grouping)
   case 'animal'
      [weekGroups,rWeek] = findgroups(rSub(:,{'GroupID','AnimalID','Week','Area'}));
      rWeek.Properties.RowNames = arrayfun(@(group,animalID,area,week)...
         sprintf('%s_%s_%s_Wk%d',string(group),string(animalID),string(area),week),...
            rWeek.GroupID,rWeek.AnimalID,rWeek.Area,rWeek.Week,'UniformOutput',false);
   case 'area'
      [weekGroups,rWeek] = findgroups(rSub(:,{'GroupID','AnimalID','Week','Area'}));
      rWeek.Properties.RowNames = arrayfun(@(animalID,area,week)...
         sprintf('%s_%s_Wk%d',string(animalID),string(area),week),...
            rWeek.AnimalID,rWeek.Area,rWeek.Week,'UniformOutput',false);
   case 'channel'
      [weekGroups,rWeek] = findgroups(rSub(:,{'GroupID','AnimalID','ChannelID','Week','Area'}));
      rWeek.Properties.RowNames = arrayfun(@(group,area,channelID,week)...
         sprintf('%s_%s_%s_Wk%d',string(group),string(area),string(channelID),week),...
            rWeek.GroupID,rWeek.Area,rWeek.ChannelID,rWeek.Week,'UniformOutput',false);
   otherwise
      error('Unrecognized grouping: %s',grouping);
end

rWeek.Week_Cubed = rWeek.Week.^3;
rWeek.Week_Sigmoid = exp(3.*(rWeek.Week-2.5))./(1 + exp(3.*(rWeek.Week-2.5)))-0.5;
rWeek.n_Channels = splitapply(@(x)numel(unique(x)),rSub.ChannelID,weekGroups);
rWeek.n_Blocks = splitapply(@(x)numel(unique(x)),rSub.BlockID,weekGroups);
rWeek.n_Trials = splitapply(@(x)numel(unique(x)),rSub.Trial_ID,weekGroups);
rWeek.n_Obs = splitapply(@(x)numel(x),weekGroups,weekGroups);
rWeek.n_Total = splitapply(@(x)round(nanmean(x)),rSub.N_Total,weekGroups);
rWeek.Performance_mu = splitapply(@nanmean,rSub.Performance_mu,weekGroups);
rWeek.Duration = splitapply(@nanmean,rSub.Duration,weekGroups);
rWeek.Reach_Epoch_Duration = splitapply(@nanmean,rSub.Reach_Epoch_Duration,weekGroups);
rWeek.Retract_Epoch_Duration = splitapply(@nanmean,rSub.Retract_Epoch_Duration,weekGroups);

% Make model for spike counts during "Pre" epoch
rWeek.n_Pre_mean = splitapply(@(x)round(nanmean(x)),rSub.N_Pre_Grasp,weekGroups);
rWeek.n_Pre_std  = splitapply(@nanstd,rSub.N_Pre_Grasp,weekGroups);
rWeek.n_Reach_mean = splitapply(@(x)round(nanmean(x)),rSub.N_Reach,weekGroups);
rWeek.n_Reach_std  = splitapply(@nanstd,rSub.N_Reach,weekGroups);
rWeek.n_Retract_mean = splitapply(@(x)round(nanmean(x)),rSub.N_Retract,weekGroups);
rWeek.n_Retract_std  = splitapply(@nanstd,rSub.N_Retract,weekGroups);

rWeek.Properties.UserData.nTrialsMinimum = 5;
iExc = rWeek.n_Trials < rWeek.Properties.UserData.nTrialsMinimum;
rWeek.Properties.UserData.nExcludedChannels = sum(iExc);
rWeek(iExc,:) = [];

% Add variable types to UserData
vType = cell(size(rWeek.Properties.VariableNames));
for iV = 1:numel(vType)
   vType{iV} = class(rWeek.(rWeek.Properties.VariableNames{iV}));
end
rWeek.Properties.UserData.VariableTypes = vType;

end