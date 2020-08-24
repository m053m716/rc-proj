%UNIT_PREDICTION_STATS Does activity in Intact rats at specific epochs predict trial outcomes?
%
%  Sets up Figure 3: do trends in activity distinguish specific sub-types
%  of unit trends, and if so, are those trends more strongly associated
%  with one area or another?

clc;
clearvars -except r
if exist('r','var')==0
   r = utils.loadTables('count');
else
   fprintf(1,'Found `r` (<strong>%d</strong> rows) in workspace.',size(r,1));
   k = 5;
   fprintf(1,'\n\t->\tPreview (%d rows):\n\n',k);
   disp(r(randsample(size(r,1),k),:));
end
% `r` has the following exclusions:
%  -> 'Grasp' aligned only
%  -> Min total trial rate: > 2.5 spikes/sec
%  -> Max total trial rate: < 300 spikes/sec
%  -> Min trial duration: 100-ms
%  -> Max trial duration: 750-ms
%  -> Note: some of these are taken care of by
%     r.Properties.UserData.Excluded
r.Properties.UserData.Excluded = ...
   (r.Alignment~="Grasp") | ...
   (r.N_Total./2.4 >= 300) | ...
   (r.N_Total./2.4 <= 2.5) | ...
   (r.Duration <= 0.100) |  ...
   (r.Duration >= 0.750);
if ismember('Group',r.Properties.VariableNames) && ~ismember('GroupID',r.Properties.VariableNames)
   r.Properties.VariableNames{'Group'} = 'GroupID';
end

%% Break down rSub into weeks and get table of empirical values/stats
B = utils.readBehaviorTable([],true);
rSub = outerjoin(r,B,...
   'Keys',{'GroupID','AnimalID','PostOpDay'},...
   'MergeKeys',true,'Type','Left',...
   'LeftVariables',setdiff(r.Properties.VariableNames,{'Performance_mu','Performance_hat_mu','Performance_hat_cb95'}),...
   'RightVariables',{'Performance_mu','Performance_hat_mu','Performance_hat_cb95'});
rSub = rSub(~rSub.Properties.UserData.Excluded,:);
rSub.Properties.UserData.Excluded = rSub.Properties.UserData.Excluded(~rSub.Properties.UserData.Excluded);
rSub.Week = ceil(rSub.PostOpDay/7);
rSub.Properties.UserData.Excluded(rSub.Week > 4) = [];
rSub(rSub.Week > 4,:) = [];


rWeek = analyze.trials.getChannelWeeklyGroupings(rSub);
rWeek_ch = analyze.trials.getChannelWeeklyGroupings(rSub,'channel');
