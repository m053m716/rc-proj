function r = fixBehaviorData(R,S)
%FIXBEHAVIORDATA If RowID and Row names mismatch, then run this to get correctly-associated trial outcomes
%
%  r = analyze.behavior.fixBehaviorData(R,S);
%
% Inputs
%  R - Table of raw spike counts
%  S - "Stats-By-Trial" xlsx file read into table format
%
% Output
%  r - Data table with correctly-associated behavioral outcomes by row
%
% See also: analyze.behavior

tic;
% % Fix properties of `S` (scoring table) % %
S = analyze.rec.fixScoringTable(S);

% % Fix properties of `R` (rates or counts table) % %
if ismember('Group',R.Properties.VariableNames)
   R.Properties.VariableNames{'Group'} = 'GroupID';
   if ~iscategorical(R.GroupID)
      R.GroupID = categorical(R.GroupID);
   end
end

if ~isstring(R.Trial_ID)
   R.Trial_ID = string(R.Trial_ID);
end
if ~ismember('RecordingID',R.Properties.VariableNames)
   R.RecordingID = extractBefore(R.Trial_ID,17);
end

if ~ismember('ObservationID',R.Properties.VariableNames)
   ID = extractAfter(R.Trial_ID,17);
   A = extractBefore(string(R.Alignment),2);
   R.ObservationID = strcat(string(R.AnimalID),...
      "_D",string(num2str(R.PostOpDay,'%02d')),...
      "_",A,ID,...
      "_",string(R.Area),string(num2str(R.Channel,'%02d')));
end
[u,iU] = unique(R.ObservationID);
if numel(u)~=size(R,1)
   fprintf(1,'<strong>%d</strong> apparently redundant observations detected\n',...
      size(R,1)-numel(u));
   R = R(iU,:);
   fprintf(1,'\t->\t<strong>(removed)</strong>\n');
else
   fprintf(1,'<strong>No redundant observations detected.</strong>\n');
end

% % Display example of each table prior to merge % %
disp('<strong>Scoring table:</strong>');
disp(S(1:5,:));
disp('<strong>Data table:</strong>');
disp(R(1:5,:));

% % Use table join to merge the tables % %
fprintf('Merging...');
r = outerjoin(R,S,...
   'Keys',{'GroupID','AnimalID','RecordingID','PostOpDay','Trial_ID'},...
   'Type','Left',...
   'LeftVariables',setdiff(R.Properties.VariableNames,{'Reach','Grasp','Support','Complete','Duration','PelletPresent','Outcome','Reach_Epoch_Duration','Retract_Epoch_Duration'}),...
   'RightVariables',{'Reach','Grasp','Support','Complete','Duration','PelletPresent','Outcome','Reach_Epoch_Duration','Retract_Epoch_Duration'});
if ismember('RowID',r.Properties.VariableNames)
   r.RowID = [];
end
r.Properties.RowNames = r.ObservationID;
r.Properties.UserData.Excluded = ...
   (r.Alignment~="Grasp") | ...
   (r.N_Total./2.4 >= 300) | ...
   (r.N_Total./2.4 <= 2.5) | ...
   (r.Duration <= 0.100) |  ...
   (r.Duration >= 0.750);
r.Properties.UserData.RateRange = [2.5 300];
r.Properties.UserData.DurationRange = [0.100 0.750];
r.Properties.UserData.SpikeYLim = [0 50];
r.Properties.VariableUnits{'Rate'} = 'spikes'; % Use old "Rate" name for compatibility
r.Properties.VariableUnits{'Reach'} = 'sec';
r.Properties.VariableUnits{'Grasp'} = 'sec';
r.Properties.VariableUnits{'Support'} = 'sec';
r.Properties.VariableUnits{'Complete'} = 'sec';
r.Properties.VariableUnits{'Duration'} = 'sec';
r.Properties.VariableUnits{'Reach_Epoch_Duration'} = 'sec';
r.Properties.VariableUnits{'Retract_Epoch_Duration'} = 'sec';
r.Properties.VariableUnits{'N_Pre_Grasp'} = 'spikes';
r.Properties.VariableUnits{'N_Grasp'} = 'spikes';
r.Properties.VariableUnits{'N_Reach'} = 'spikes';
r.Properties.VariableUnits{'N_Retract'} = 'spikes';
r.Properties.VariableUnits{'N_Total'} = 'spikes';


r = movevars(r,{'ObservationID','RecordingID','Trial_ID'},'Before','Alignment');
r = movevars(r,{'GroupID','AnimalID'},'Before','Alignment');
r = movevars(r,'Outcome','Before','Area');

r = analyze.trials.addCountVariables(r);

fprintf(1,'complete (%5.2f sec)\n',toc);
% % Show example rows from output table % %
fprintf(1,'\n\t->\tPreview (%d rows):\n\n',5);
disp(r(randsample(size(r,1),5),:));
end