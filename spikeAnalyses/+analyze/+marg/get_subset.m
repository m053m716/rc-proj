function [M,T] = get_subset(T)
%GET_SUBSET  Returns subset of full table for "marginalization" analyses
%
%  T = analyze.marg.get_subset(T);
%  e.g.
%     >> M = analyze.marg.get_subset(T);%Retain original data table in case
%
%  -- Inputs --
%  T : Table from `T = getRateTable(gData);`
%
%  -- Output --
%  M : Table in same format, but has subset meeting following criteria:
%        -> Duration is >= 100ms and <= 1500 ms
%        -> Reach Phase is <= 650 ms
%        -> Retract Phase is <= 750 ms
%        -> Reach, Grasp, Complete, and Pellet are all present.
%  T : Input table with "Excluded" UserData struct field updated.

[min_dur,max_dur,align,max_reach,max_retract] = defaults.complete_analyses(...
   'min_duration','max_duration','alignment_events',...
   'max_reach','max_retract');

T.Duration = T.Complete - T.Reach;
T.Reach_Epoch_Duration = T.Grasp - T.Reach;
T.Retract_Epoch_Duration = T.Complete - T.Grasp;

iDuration = T.Duration>=min_dur & T.Duration < max_dur;
iReach = T.Reach_Epoch_Duration < max_reach;
iRetract = T.Retract_Epoch_Duration < max_retract;

iAlign = ismember(T.Alignment,align);
hasPellet = T.PelletPresent=='Present';
hasReach = ~isnan(T.Reach) & ~isinf(T.Reach);
hasGrasp = ~isnan(T.Grasp) & ~isinf(T.Grasp);
hasComplete = ~isnan(T.Complete) & ~isinf(T.Complete);

% % Do Row exclusion % %
T.Properties.UserData.iDuration = iDuration;
T.Properties.UserData.iReach = iReach;
T.Properties.UserData.iRetract = iRetract;
T.Properties.UserData.iAlign = iAlign;
T.Properties.UserData.hasPellet = hasPellet;
T.Properties.UserData.hasReach = hasReach;
T.Properties.UserData.hasGrasp = hasGrasp;
T.Properties.UserData.hasComplete = hasComplete;
T.Properties.UserData.Tag = struct(...
   'Main','All Completed Attempts',...
   'Sub','',...
   'Grouping','',...
   'Other','');
iKeep = iDuration & iReach & iRetract & iAlign & hasPellet & hasReach & hasGrasp & hasComplete;
M = T(iKeep,:);
T.Properties.UserData.Excluded = ~iKeep;
if M.Properties.UserData.IsTransformed && ~isfield(M.Properties.UserData,'Processing')
   M = utils.addProcessing(M,'Smoothed');
end
M = utils.addProcessing(M,'Subset');
M.Properties.Description = 'Table for +analyze/+marg package';

% % Remove unwanted columns % %
M = utils.remove_cols(M,'Xc','Yc');
% T.PelletPresent = [];
% T.Reach = [];
% T.Grasp = [];

% % Rearrange a few of the columns % %
M = movevars(M,'RowID','Before',1);
M = movevars(M,'Trial_ID','Before',1);
if ismember('Rat',M.Properties.VariableNames)
   M = movevars(M,'Rat','After','AnimalID');
end

end