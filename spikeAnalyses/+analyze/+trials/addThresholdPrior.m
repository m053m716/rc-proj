function [rAUC,TID] = addThresholdPrior(rSub)
%ADDTHRESHOLDPRIOR Add thresholding prior for Unsuccessful (0) or Successful (1)
%
%  rSub = analyze.trials.addThresholdPrior(rSub,mdl);
%
% Inputs
%  rSub - Data table with successful & unsuccessful trials
%           -> Must have 'PredictionOutcome' variable.
%
% Output
%  rAUC - Same data table but with 'Prior' variable added to be used as
%           threshold for determining confusion matrix statistics. 

AUC_THRESH = 0.66; % AUC must meet or exceed this in at least 1 week (per channel) for its subsequent inclusion

% Recover "Prior" which is threshold for optimal discrimination
[G,TID] = findgroups(rSub(:,{'ChannelID','Week'}));
[TID.AUC,TID.Prior] = splitapply(@analyze.trials.computeWeeklyChannelROC,...
   rSub.Outcome,rSub.Prediction_Outcome,G);

% Only set Threshold as NaN if none of the Weeks are informative
[G,tid] = findgroups(TID(:,'ChannelID'));
tid.flag = splitapply(@(auc)setNaNThresh(auc,AUC_THRESH),TID.AUC,G);
TID = outerjoin(TID,tid,'Type','left',...
   'LeftVariables',{'ChannelID','Week','Prior','AUC'},...
   'RightVariables',{'flag'},...
   'Keys',{'ChannelID'});
TID.Prior(TID.flag) = nan;

if isstruct(rSub.Properties.UserData)
   tmp = rSub.Properties.UserData;
else
   tmp = struct;
end

rAUC = outerjoin(rSub,TID,...
   'Type','left',...
   'LeftVariables',setdiff(rSub.Properties.VariableNames,{'Prior','Rate','FN','FP','TP','TN'}),...
   'RightVariables',{'Prior','AUC'},...
   'Keys',{'ChannelID','Week'});

rAUC.Properties.UserData = tmp;

   function flag = setNaNThresh(AUC,AUC_THRESH)
      flag = all(AUC < AUC_THRESH);
   end

end