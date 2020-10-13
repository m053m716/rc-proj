function [rClass,data,fig,tbl] = fitOutcomeClassifier(rSub)
%FITOUTCOMECLASSIFIER Fit classification model for individual channels to recover `predicted` label of each trial
%
%  [data,C] = analyze.trials.fitOutcomeClassifier(rSub);
%
% Inputs
%  rSub - Subset of full rates (counts) data table
%
% Output
%  data - Updated data table
%  C    - Per-channel classifier models
%
% See also: Contents, unit_learning_stats


[G,C] = findgroups(rSub(:,{'ChannelID','Week'}));
tic;
fprintf(1,'Fitting Naive Bayes classifier models for each <strong>ChannelID</strong> and <strong>Week</strong> combination...');
[C.mdl,C.simple_mdl,pred,simple_pred] = splitapply(@fitBayes,rSub.N_Pre_Grasp,rSub.N_Reach,rSub.N_Total,rSub.Duration,rSub.Retract_Epoch_Duration,rSub.Outcome,G);
fprintf(1,'complete (%5.2f sec)\n',toc);

tic;
fprintf(1,'Returning weekly predictions...');
rSub.Weekly_Prediction_Outcome = rSub.Outcome;
rSub.Weekly_Prediction_Outcome_Simple = rSub.Outcome;
for ii = 1:numel(pred)
   if ~isa(C.mdl{ii},'ClassificationNaiveBayes')
      continue;
   end
   rSub.Weekly_Prediction_Outcome(G==ii) = pred{ii};
   rSub.Weekly_Prediction_Outcome_Simple(G==ii) = simple_pred{ii};
end
fprintf(1,'complete (%5.2f sec)\n',toc);

if isstruct(rSub.Properties.UserData)
   tmp = rSub.Properties.UserData;
else
   tmp = struct;
end
   
% Merge the models into main table
rClass = outerjoin(rSub,C,...
   'Keys',{'ChannelID','Week'},...
   'Type','left',...
   'LeftVariables',setdiff(rSub.Properties.VariableNames,{'mdl','simple_mdl','Rate','TP','TN','FP','FN'}),...
   'RightVariables',{'mdl','simple_mdl'});

% Remove "bad" channels
rClass.Properties.UserData = tmp;
iRemove = cellfun(@(C)~isa(C,'ClassificationNaiveBayes'),rClass.mdl,'UniformOutput',true);
rClass(iRemove,:) = [];
if isfield(rClass.Properties.UserData,'Excluded')
   rClass.Properties.UserData.Excluded(iRemove) = [];
end

% Predict individual trial labels
G = (1:size(rClass,1))';
a = zscore(rClass.N_Pre_Grasp);
b = zscore(rClass.N_Reach);
c = zscore(rClass.N_Retract);
d = zscore(rClass.Duration);
e = zscore(rClass.Retract_Epoch_Duration);

tic;
fprintf(1,'Generating posterior predictions using data marginalized on full dataset...');
[rClass.Prediction_Outcome,rClass.Prediction_Posterior,rClass.Prediction_Outcome_Simple,rClass.Prediction_Posterior_Simple] = ...
   splitapply(@predictBayes,a,b,c,d,e,rClass.mdl,rClass.simple_mdl,G);
fprintf(1,'complete (%5.2f sec)\n',toc);
rClass = analyze.trials.addConfusionData(rClass);

if nargout > 2
   [data,fig,tbl] = analyze.trials.weeklyConfusion(rClass);
   [datas,figs,tbls] = analyze.trials.weeklyConfusion(rClass,'simple');
   data = [data; datas];
   fig = [fig; figs];
   tbl = [tbl; tbls];
else
   fig = []; tbl = [];
   
   data = analyze.trials.weeklyConfusion(rClass);
   datas = analyze.trials.weeklyConfusion(rClass,'simple');
   data = [data; datas];
end

   function [mdl,simple_mdl,pred,simple_pred] = fitBayes(N_Pre_Grasp,N_Reach,N_Retract,Duration,Retract_Epoch_Duration,Outcome)
   %FITBAYES Return cell array containin NaN or Naive Bayes Classifier for trial outcome prediction on per-channel basis.
      g = findgroups(Outcome);
      if (sum(g==1)<=2) || (sum(g==2)<=2)
         mdl = {nan};
         pred = {nan(size(Outcome))};
         simple_mdl = {nan};
         simple_pred = {nan(size(Outcome))};
         return;
      end
      
      X = [N_Pre_Grasp, N_Reach, N_Retract, Duration, Retract_Epoch_Duration];
      X = (X - nanmean(X,1))./nanstd(X,[],1);
      
      if any(nanvar(X,[],1)==0)
         mdl = {nan};
         pred = {nan(size(Outcome))};
         simple_mdl = {nan};
         simple_pred = {nan(size(Outcome))};
         return;
      end
      
      Y = Outcome;      
      
      mdl = fitcnb(X,Y);
      pred = {predict(mdl,X)};
      mdl = {mdl};
      
      simple_mdl = fitcnb(X(:,1:3),Y);
      simple_pred = {predict(simple_mdl,X(:,1:3))};
      simple_mdl = {simple_mdl};
   end

   function [out,post,out_simple,post_simple] = predictBayes(N_Pre_Grasp,N_Reach,N_Retract,Duration,Retract_Epoch_Duration,mdl,simple_mdl)
      %PREDICTBAYES Use trained model to predict trial label, posterior probability, and error cost
      
      X = [N_Pre_Grasp,N_Reach,N_Retract,Duration,Retract_Epoch_Duration];      
      [out,post] = predict(mdl{:},X);
      [out_simple,post_simple] = predict(simple_mdl{:},X(:,1:3));
      
   end
end