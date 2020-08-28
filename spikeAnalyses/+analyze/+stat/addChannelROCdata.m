function rSub = addChannelROCdata(rSub,mdl)
%ADDCHANNELROCDATA Add ROC area-under-curve data by channel grouping
%
%  rSub = analyze.stat.addChannelROCdata(rSub,mdl);
%
% Inputs
%  rSub  - Weekly grouped data table of rate/count data
%  mdl   - Struct containing GeneralizedLinearMixedModel
%
% Output
%  rSub  - Weekly grouped data table of rate/count data with AUC data added
%
% See also: analyze.stat, analyze.stat.computeROC, unit_learning_stats

[~,TID] = findgroups(rSub(:,{'Week','ChannelID'}));

n = size(TID,1);
TID.Pre_AUC = nan(n,1);
TID.Reach_AUC = nan(n,1);
TID.Retract_AUC = nan(n,1);
fprintf(1,'Computing AUC...000%%\n');
curPct = 0;
for iT = 1:n
   args = {...
      'ChannelID',char(TID.ChannelID(iT)),...
      'Week',sprintf('Week-%d',TID.Week(iT))...
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

rSub.RowID = rSub.Properties.RowNames;
rSub = outerjoin(...
   rSub,TID,...
   'Keys',{'Week','ChannelID'},...
   'MergeKeys',true,...
   'Type','Left',...
   'LeftVariables',setdiff(rSub.Properties.VariableNames,{'Pre_AUC','Reach_AUC','Retract_AUC'}),...
   'RightVariables',{'Pre_AUC','Reach_AUC','Retract_AUC'});
rSub.Properties.RowNames = rSub.RowID;

end