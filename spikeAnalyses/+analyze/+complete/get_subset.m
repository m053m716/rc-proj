function U = get_subset(T)
%GET_SUBSET  Returns subset of full table for "Completed" trials analyses
%
%  U = analyze.complete.get_subset(T);
%
%  -- Inputs --
%  T : Table from `T = getRateTable(gData);`
%
%  -- Output --
%  U : Table in same format, but has subset meeting following criteria:
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
U = T(iDuration & iAlign & hasPellet & hasReach & hasGrasp & hasComplete,:);
U.Properties.UserData.iDuration = iDuration;
U.Properties.UserData.iAlign = iAlign;
U.Properties.UserData.hasPellet = hasPellet;
U.Properties.UserData.hasReach = hasReach;
U.Properties.UserData.hasGrasp = hasGrasp;
U.Properties.UserData.hasComplete = hasComplete;
U.Properties.Description = 'Table for +analyze/+successful package';

% % Remove unwanted columns % %
U.Xc = [];
U.Yc = [];
U.PelletPresent = [];
U.Reach = [];
U.Grasp = [];

% % Rearrange a few of the columns % %
U = movevars(U,'RowID','Before','Group');
U = movevars(U,'Trial_ID','Before','Group');
U = movevars(U,'Rat','After','AnimalID');

end