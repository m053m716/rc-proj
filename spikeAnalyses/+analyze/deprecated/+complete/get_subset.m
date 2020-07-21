function T = get_subset(T)
%GET_SUBSET  Returns subset of full table for "Completed" trials analyses
%
%  T = analyze.complete.get_subset(T);
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
T.Properties.Description = 'Table for +analyze/+complete package';

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