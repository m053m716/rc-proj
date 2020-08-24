function S = fixScoringTable(S)
%FIXSCORINGTABLE Format Scoring table variables appropriately
%
%  S = analyze.rec.fixScoringTable(S);
%
% Inputs
%  S - Scoring table, as used by analyze.behavior.fixBehaviorData
%
% Output
%  S - Formatted scoring table
%
% See also: analyze.behavior, analyze.behavior.fixBehaviorData

if ismember('Group',S.Properties.VariableNames)
   S.Properties.VariableNames{'Group'} = 'GroupID';
   S.GroupID = categorical(S.GroupID);
end

if ismember('Rat',S.Properties.VariableNames)
   S.Properties.VariableNames{'Rat'} = 'AnimalID';
   S.AnimalID = categorical(S.AnimalID);
end

if ismember('Name',S.Properties.VariableNames)
   S.Properties.VariableNames{'Name'} = 'RecordingID';
   S.RecordingID = string(S.RecordingID);
end

S.Reach(S.Reach >= 65000) = inf;
S.Grasp(S.Grasp >= 65000) = inf;
S.Support(S.Support >= 65000) = inf;
S.Complete(S.Complete >= 65000) = inf;

if ismember('Reach_Grasp_Duration',S.Properties.VariableNames)
   S.Properties.VariableNames{'Reach_Grasp_Duration'} = 'Reach_Epoch_Duration';
   S.Reach_Epoch_Duration(abs(S.Reach_Epoch_Duration) > 10) = inf;
end

if ismember('Reach_Complete_Duration',S.Properties.VariableNames)
   S.Properties.VariableNames{'Reach_Complete_Duration'} = 'Duration';
   S.Duration(abs(S.Duration) > 10) = inf;
end

if ismember('Grasp_Complete_Duration',S.Properties.VariableNames)
   S.Properties.VariableNames{'Grasp_Complete_Duration'} = 'Retract_Epoch_Duration';
   S.Retract_Epoch_Duration(abs(S.Retract_Epoch_Duration) > 10) = inf;
end

if ~iscategorical(S.PelletPresent)
   S.PelletPresent = categorical(S.PelletPresent,[0 1],{'Missing','Present'});
end

if ~iscategorical(S.Outcome)
   S.Outcome = categorical(S.Outcome,[0 1],{'Unsuccessful','Successful'});
end

[~,iSort] = sort(S.RecordingID,'ascend');
S = S(iSort,:);
G = findgroups(S(:,'RecordingID')); % findgroups groupings can mess up matched order
[id,id_key] = splitapply(@(x)appendTrial(x),S.RecordingID,G);
[~,iSort] = sort(id_key,'ascend');
id = id(iSort); % Make sure parsed trials are also in ascending order
id = vertcat(id{:});
S.Trial_ID = id;

   
% Likely just due to annotation error while scoring: any trials marked as
% Successful necessarily had the pellet present (total count of such trials
% is 5 vs 3,154 correctly labeled)
iBad = S.PelletPresent=="Missing" & S.Outcome=="Successful";
fprintf(1,'<strong>%d trials</strong> with incongruous Success-Pellet labels.\n',sum(iBad));
fprintf(1,'\t->\t(versus %d correctly-labeled Successful trials)\n',sum(S.Outcome=="Successful")-sum(iBad));
fprintf(1,'\t->\t<strong>Updated mismatched trials to Pellet Present label</strong>\n');
S.PelletPresent(iBad) = categorical(ones(sum(iBad),1),[0 1],{'Unsuccessful','Successful'});

S = movevars(S,'Trial_ID','Before','PostOpDay');

   function [y,key] = appendTrial(x)
      %APPENDTRIAL Add trial index using splitapply workflow
      %
      %  y = appendTrial(x);
      %
      % Inputs
      %  x - Cell array of char vectors that are S.RecordingID (Block Name)
      %
      % Output
      %  y - Scalar cell (wrapped) string array that is the same size as x;
      %        each string is the Block name (RecordingID) with a
      %        3-digit unit-incremented index appended (1-indexed)
      
      y = strings(size(x,1),1);
      for iX = 1:size(x,1)
         y(iX) = strcat(string(x{iX}),"_",string(num2str(iX,'%03d')));
      end
      y = {y};
      key = string(x{1});
   end

end