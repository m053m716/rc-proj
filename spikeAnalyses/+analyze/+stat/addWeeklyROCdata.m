function rWeek = addWeeklyROCdata(rWeek,mdl)
%ADDWEEKLYROCDATA Add ROC area-under-curve data by weekly grouping
%
%  rWeek = analyze.stat.addWeeklyROCdata(rWeek,mdl);
%
% Inputs
%  rWeek - Weekly grouped data table of rate/count data
%  mdl   - Struct containing GeneralizedLinearMixedModel
%
% Output
%  rWeek - Weekly grouped data table of rate/count data with AUC data added
%
% See also: analyze.stat, analyze.stat.computeROC, unit_learning_stats

[~,TID] = findgroups(rWeek(:,{'GroupID','Area','Week','AnimalID'}));

n = size(TID,1);
TID.Pre_AUC = nan(n,1);
TID.Reach_AUC = nan(n,1);
TID.Retract_AUC = nan(n,1);
fprintf(1,'Computing AUC...000%%\n');
curPct = 0;
for iT = 1:n
   args = {...
      'GroupID',char(TID.GroupID(iT)),...
      'Area',char(TID.Area(iT)),...
      'Week',sprintf('Week-%d',TID.Week(iT))...
      'AnimalID',char(TID.AnimalID(iT)),...
      };
   [~,~,TID.Pre_AUC(iT)] = analyze.stat.computeROC(mdl.pre.outcome.mdl,args{:});
   [~,~,TID.Reach_AUC(iT)] = analyze.stat.computeROC(mdl.reach.outcome.mdl,args{:});
   [~,~,TID.Retract_AUC(iT)] = analyze.stat.computeROC(mdl.retract.outcome.mdl,args{:});
   thisPct = round(iT/n * 100);
   if thisPct-curPct >= 5
      curPct = thisPct;
      fprintf(1,'\b\b\b\b\b%03d%%\n',thisPct);
   end
end

rWeek.RowID = rWeek.Properties.RowNames;
rWeek = outerjoin(...
   rWeek,TID,...
   'Keys',{'GroupID','Area','Week','AnimalID'},...
   'MergeKeys',true,...
   'Type','Left',...
   'LeftVariables',setdiff(rWeek.Properties.VariableNames,{'Pre_AUC','Reach_AUC','Retract_AUC'}),...
   'RightVariables',{'Pre_AUC','Reach_AUC','Retract_AUC'});
rWeek.Properties.RowNames = rWeek.RowID;

end