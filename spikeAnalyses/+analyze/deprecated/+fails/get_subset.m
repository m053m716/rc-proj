function U = get_subset(T)
%GET_SUBSET  Returns subset of full rate table for "Unsuccessful" analyses
%
%  U = analyze.fails.get_subset(T);
%
%  -- Inputs --
%  T : Table from `T = getRateTable(gData);`
%
%  -- Output --
%  U : Table in same format, but has all 'Successful' trials removed and
%        only includes 'Unsuccessful' trials in alignment to Reach and
%        Grasp which meet the following criteria:
%        -> Duration is >= 100ms and <= 750ms
%        -> Reach, Grasp, and Pellet are all present.

T.Duration = T.Complete - T.Reach;
iDuration = T.Duration>=0.100 & T.Duration<=0.750;
iOutcome = T.Outcome=='Unsuccessful';
iEvent = T.PelletPresent=='Present' & ~isnan(T.Reach) & ~isinf(T.Reach) & ...
   ~isnan(T.Grasp) & ~isinf(T.Grasp);
iAlign = T.Alignment=='Reach' | T.Alignment=='Grasp';

% % Do Row exclusion % %
U = T(iDuration & iOutcome & iEvent & iAlign,:);
U.Properties.UserData.iDuration = iDuration;
U.Properties.UserData.iOutcome = iOutcome;
U.Properties.UserData.iEvent = iEvent;
U.Properties.UserData.iAlign = iAlign;
U.Properties.Description = 'Table of only Unsuccessful Attempts';

% % Remove unwanted columns % %
U.Xc = [];
U.Yc = [];
U.PelletPresent = [];
U.Reach = [];
U.Grasp = [];
U.Support = [];
U.Complete = [];

% % Rearrange a few of the columns % %
U = movevars(U,'RowID','Before','Group');
U = movevars(U,'Trial_ID','Before','Group');
U = movevars(U,'Rat','After','AnimalID');

end