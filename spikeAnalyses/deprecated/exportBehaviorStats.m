%% ACCOUNT FOR MISSING DAYS
% Parse summary of behavior from blocks and fill missing values
if exist('S','var')==0
   S = getBlockSummary(gData);   
end
Sfull = addMissingRows(S,'PostOpDay',min(S.PostOpDay):max(S.PostOpDay),'Rat');
Sfull = fillMissingByGroup(Sfull,'Group','Rat');
Sfull = sortrows(Sfull,{'Rat','PostOpDay'});

%% MAKE TABLE FOR REPEATED-MEASURES MODEL FIT
% Rearrange data using dummy variable matrix
t = dummyvar(Sfull.PostOpDay-2);
score = t.* Sfull.Score;

[Rat,rIdx] = unique(Sfull.Rat);
Group = categorical(repmat({'undefined'},numel(Rat),1));
Score = zeros(numel(Rat),size(score,2));
for iR = 1:numel(Rat)
   Group(iR) = Sfull.Group(rIdx(iR));
   s = score(ismember(Sfull.Rat,Rat{iR}),:); % Should be diagonal
   Score(iR,:) = diag(s);
end

% Fill missing values
Score = fillmissing(Score,'linear',2,'EndValues','nearest');

T = table(Rat,Group,Score);
% Format table to have ungrouped variables
% Trm = T;
% Trm = [Trm(:,1:2),table(Trm.Score(:,1),'VariableNames',{'Score1'}),table(Trm.Score(:,2),'VariableNames',{'Score2'}),table(Trm.Score(:,3),'VariableNames',{'Score3'}),table(Trm.Score(:,4),'VariableNames',{'Score4'}),table(Trm.Score(:,5),'VariableNames',{'Score5'}),table(Trm.Score(:,6),'VariableNames',{'Score6'}),table(Trm.Score(:,7),'VariableNames',{'Score7'}),table(Trm.Score(:,8),'VariableNames',{'Score8'}),table(Trm.Score(:,9),'VariableNames',{'Score9'}),table(Trm.Score(:,10),'VariableNames',{'Score10'}),table(Trm.Score(:,11),'VariableNames',{'Score11'}),table(Trm.Score(:,12),'VariableNames',{'Score12'}),table(Trm.Score(:,13),'VariableNames',{'Score13'}),table(Trm.Score(:,14),'VariableNames',{'Score14'}),table(Trm.Score(:,15),'VariableNames',{'Score15'}),table(Trm.Score(:,16),'VariableNames',{'Score16'}),table(Trm.Score(:,17),'VariableNames',{'Score17'}),table(Trm.Score(:,18),'VariableNames',{'Score18'}),table(Trm.Score(:,19),'VariableNames',{'Score19'}),table(Trm.Score(:,20),'VariableNames',{'Score20'}),table(Trm.Score(:,21),'VariableNames',{'Score21'}),table(Trm.Score(:,22),'VariableNames',{'Score22'}),table(Trm.Score(:,23),'VariableNames',{'Score23'}),table(Trm.Score(:,24),'VariableNames',{'Score24'}),table(Trm.Score(:,25),'VariableNames',{'Score25'}),table(Trm.Score(:,26),'VariableNames',{'Score26'}),table(Trm.Score(:,27),'VariableNames',{'Score27'}),table(Trm.Score(:,28),'VariableNames',{'Score28'}),table(Trm.Score(:,29),'VariableNames',{'Score29'})];
% Time = table((min(S.PostOpDay):max(S.PostOpDay))','VariableNames',{'Time'});
% Time = table((3:4:27)','VariableNames',{'Time'});
% Time = table((4:14:24)','VariableNames',{'Time'});

%% FIT MODEL
% rm = fitrm(Trm,'Score1-Score29 ~ Group',...
%    'WithinDesign',Time);
% rm = fitrm(Trm,'Score1,Score5,Score9,Score13,Score17,Score21,Score25 ~ Group',...
%    'WithinDesign',Time);
% rm = fitrm(Trm,'Score2,Score16,Score26~Group',...
%    'WithinDesign',Time);