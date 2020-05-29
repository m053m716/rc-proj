function T = get_subset(T)
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
%  T : Table in same format, but has subset meeting following criteria:
%        -> Duration is >= 100ms and <= 750ms
%        -> Reach, Grasp, Complete, and Pellet are all present.

[min_dur,max_dur,align] = defaults.complete_analyses(...
   'min_duration','max_duration','alignment_events');

T.Duration = T.Complete - T.Reach;
iDuration = T.Duration>=min_dur & T.Duration<=max_dur;
iAlign = ismember(T.Alignment,align);
hasPellet = T.PelletPresent=='Present';
hasReach = ~isnan(T.Reach) & ~isinf(T.Reach);
hasGrasp = ~isnan(T.Grasp) & ~isinf(T.Grasp);
hasComplete = ~isnan(T.Complete) & ~isinf(T.Complete);

% % Do Row exclusion % %
T = T(iDuration & iAlign & hasPellet & hasReach & hasGrasp & hasComplete,:);
T.Properties.UserData.iDuration = iDuration;
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
if T.Properties.UserData.IsTransformed && ~isfield(T.Properties.UserData,'Processing')
   T = utils.addProcessing(T,'Smoothed');
end
T = utils.addProcessing(T,'Subset');
T.Properties.Description = 'Table for +analyze/+marg package';

% % Remove unwanted columns % %
T = utils.remove_cols(T,'Xc','Yc');
% T.PelletPresent = [];
% T.Reach = [];
% T.Grasp = [];

% % Rearrange a few of the columns % %
T = movevars(T,'RowID','Before',1);
T = movevars(T,'Trial_ID','Before',1);
if ismember('Rat',T.Properties.VariableNames)
   T = movevars(T,'Rat','After','AnimalID');
end

end