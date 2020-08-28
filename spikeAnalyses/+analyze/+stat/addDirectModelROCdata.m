function rSub = addDirectModelROCdata(rSub,mdl)
%ADDDIRECTMODELROCDATA Add ROC area-under-curve data for channel-grouped model for directly predicting outcome labels from spike counts
%
%  rSub = analyze.stat.addDirectModelROCdata(rSub,mdl);
%
% Inputs
%  rSub  - Weekly grouped data table of rate/count data
%  mdl   - Struct containing GeneralizedLinearMixedModel
%
% Output
%  rSub  - Weekly grouped data table of rate/count data with AUC data added
%
% See also: analyze.stat, analyze.stat.computeROC, unit_learning_stats

[~,TID] = findgroups(rSub(:,{'ChannelID'}));

n = size(TID,1);
TID.All_AUC = nan(n,1);
fprintf(1,'Computing AUC...000%%\n');
curPct = 0;
for iT = 1:n
   args = {...
      'ChannelID',char(TID.ChannelID(iT)),...
      };
   [~,~,TID.All_AUC(iT)] = analyze.stat.computeROC(mdl.all.direct_outcome.mdl,args{:});
   thisPct = round(iT/n * 100);
   if thisPct-curPct >= 5
      curPct = thisPct;
      fprintf(1,'\b\b\b\b\b%03d%%\n',thisPct);
   end
end

rSub = outerjoin(...
   rSub,TID,...
   'Keys',{'ChannelID'},...
   'MergeKeys',true,...
   'Type','Left',...
   'LeftVariables',setdiff(rSub.Properties.VariableNames,{'All_AUC'}),...
   'RightVariables',{'All_AUC'});

end