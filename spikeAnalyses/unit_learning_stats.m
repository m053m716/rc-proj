%UNIT_LEARNING_STATS Use Mitz/Wise approach for Figs 2, 3, S4: count spikes in pre-defined epochs to define activity
%
%  Sets up Figure 3: do trends in activity distinguish specific sub-types
%  of unit trends, and if so, are those trends more strongly associated
%  with one area or another?

clc;
clearvars -except r
if exist('r','var')==0
   r = utils.loadTables('rate');
else
   fprintf(1,'Found `r` (<strong>%d</strong> rows) in workspace.',size(r,1));
   k = 5;
   fprintf(1,'\n\t->\tPreview (%d rows):\n\n',k);
   disp(r(randsample(size(r,1),k),:));
end
if ismember('Group',r.Properties.VariableNames) && ~ismember('GroupID',r.Properties.VariableNames)
   r.Properties.VariableNames{'Group'} = 'GroupID';
end

% Get subset for analysis
[rSub,r] = analyze.get_subset(r,'align',{'Grasp'});
[~,rSub] = analyze.trials.getChannelWeeklyGroupings(rSub,'animal',true);
% rSub = analyze.mergePredictionData

%% Create Figure 3
% Create corresponding figures.
outPath = defaults.files('reach_extension_figure_dir');
if exist(outPath,'dir')==0
   mkdir(outPath);
end

[rClass,data,fig,tbl] = analyze.trials.fitOutcomeClassifier(rSub);
saveas(fig(1),fullfile(outPath,'Fig3b - Model-14 - Individual Channels NB - Duration.png'));
savefig(fig(1),fullfile(outPath,'Fig3b - Model-14 - Individual Channels NB - Duration.fig'));
delete(fig(1));

saveas(fig(2),fullfile(outPath,'Fig3a - Model-13 - Individual Channels NB - No Duration.png'));
savefig(fig(2),fullfile(outPath,'Fig3a - Model-13 - Individual Channels NB - No Duration.fig'));
delete(fig(2));

%% Create posterior probability visuals
tmp = rClass(rClass.Area=="RFA" & rClass.AnimalID=="RC-05" & rClass.Week==2,:);
tmp2 = tmp(tmp.ChannelID==tmp.ChannelID(1),:); % ChannelID == 177

fig = analyze.trials.plotPosterior(tmp2,'N_Retract','N_Pre_Grasp','simple');
saveas(fig,fullfile(outPath,'Fig3 - Example Posterior - N_Retract - N_Pre_Grasp - Ch 177.png'));
savefig(fig,fullfile(outPath,'Fig3 - Example Posterior - N_Retract - N_Pre_Grasp - Ch 177.fig'));
delete(fig);

fig = analyze.trials.plotPosterior(tmp2,'N_Retract','N_Reach','simple');
saveas(fig,fullfile(outPath,'Fig3 - Example Posterior - N_Retract - N_Reach - Ch 177.png'));
savefig(fig,fullfile(outPath,'Fig3 - Example Posterior - N_Retract - N_Reach - Ch 177.fig'));
delete(fig);

fig = analyze.trials.plotPosterior(tmp2,'N_Retract','Retract_Epoch_Duration');
saveas(fig,fullfile(outPath,'Fig3 - Example Posterior - N_Retract - Retract_Epoch_Duration - Ch 177.png'));
savefig(fig,fullfile(outPath,'Fig3 - Example Posterior - N_Retract - Retract_Epoch_Duration - Ch 177.fig'));
delete(fig);

fig = analyze.trials.plotPosterior(tmp2,'N_Reach','Duration');
saveas(fig,fullfile(outPath,'Fig3 - Example Posterior - N_Reach - Duration - Ch 177.png'));
savefig(fig,fullfile(outPath,'Fig3 - Example Posterior - N_Reach - Duration - Ch 177.fig'));
delete(fig);

tmp3 = tmp(tmp.ChannelID==tmp.ChannelID(993),:); % ChannelID == 186
fig = analyze.trials.plotPosterior(tmp3,'N_Retract','N_Pre_Grasp','simple');
saveas(fig,fullfile(outPath,'Fig3 - Example Posterior - N_Retract - N_Pre_Grasp - Ch 186.png'));
savefig(fig,fullfile(outPath,'Fig3 - Example Posterior - N_Retract - N_Pre_Grasp - Ch 186.fig'));
delete(fig);

fig = analyze.trials.plotPosterior(tmp3,'N_Retract','Retract_Epoch_Duration');
saveas(fig,fullfile(outPath,'Fig3 - Example Posterior - N_Retract - Retract_Epoch_Duration - Ch 186.png'));
savefig(fig,fullfile(outPath,'Fig3 - Example Posterior - N_Retract - Retract_Epoch_Duration - Ch 186.fig'));
delete(fig);

tmp4 = tmp(tmp.ChannelID==tmp.ChannelID(778),:); % ChannelID == 184
fig = analyze.trials.plotPosterior(tmp4,'N_Retract','N_Pre_Grasp','simple');
saveas(fig,fullfile(outPath,'Fig3 - Example Posterior - N_Retract - N_Pre_Grasp - Ch 184.png'));
savefig(fig,fullfile(outPath,'Fig3 - Example Posterior - N_Retract - N_Pre_Grasp - Ch 184.fig'));
delete(fig);


%%
clc;


% Initialize data output variables and data subset to pass to figures %
Data = struct;
mdl = struct;

% Generate figures corresponding to each epoch %
% % Pre-Grasp Figures % %
[fig,mdl.pre.all,Data.pre.all] = analyze.behavior.per_animal_area_mean_trends(rSub,...
   'N_Pre_Grasp',...
   'YLabel','Spike Count',...
   'FitOptions',{...
      'FitMethod','REMPL',...
      'Distribution','binomial',...
      'DummyVarCoding','effects',...
      'Link','logit' ...
      },...
   'LegendStyle','animals',...
   'LegendLocation','eastoutside',...
   'YLim',[0 80],...
   'Tag','All-Trials-Pre-Counts',...
   'ID','10a',...
   'Title','Activity: Pre-Grasp (All Trials with Duration Exclusions)');
saveas(fig,fullfile(outPath,'FigS3 - Pre-Grasp Trends 95CB - Animal Mean Trends - All Trials.png'));
savefig(fig,fullfile(outPath,'FigS3 - Pre-Grasp Trends 95CB - Animal Mean Trends - All Trials.fig'));
delete(fig);

% % Reach Figures % %
[fig,mdl.reach.all,Data.reach.all] = analyze.behavior.per_animal_area_mean_trends(rSub,...
   'N_Reach',...
   'YLabel','Spike Count',...
   'RandomCovariates',{'Duration','Reach_Epoch_Duration'},...
   'FitOptions',{...
      'FitMethod','REMPL',...
      'Distribution','binomial',...
      'DummyVarCoding','effects',...
      'Link','logit' ...
      },...
   'LegendStyle','animals',...
   'LegendLocation','eastoutside',...
   'YLim',[0 80],...
   'Tag','All-Trials-Reach-Counts',...
   'ID','11a',...
   'Title','Activity: Reach (All Trials with Duration Exclusions)');
saveas(fig,fullfile(outPath,'FigS3 - Reach Trends 95CB - Animal Mean Trends - All Trials.png'));
savefig(fig,fullfile(outPath,'FigS3 - Reach Trends 95CB - Animal Mean Trends - All Trials.fig'));
delete(fig);

% % Retract Figures % %
[fig,mdl.retract.all,Data.retract.all] = analyze.behavior.per_animal_area_mean_trends(rSub,...
   'N_Retract',...
   'YLabel','Spike Count',...
   'RandomCovariates',{'Duration','Retract_Epoch_Duration'},...
   'FitOptions',{...
      'FitMethod','REMPL',...
      'Distribution','binomial',...
      'DummyVarCoding','effects',...
      'Link','logit' ...
      },...
   'LegendStyle','animals',...
   'LegendLocation','eastoutside',...
   'YLim',[0 80],...
   'Tag','All-Trials-Retract-Counts',...
   'ID','12a',...
   'Title','Activity: Retract (All Trials with Duration Exclusions)');
saveas(fig,fullfile(outPath,'FigS3 - Retract Trends 95CB - Animal Mean Trends - All Trials.png'));
savefig(fig,fullfile(outPath,'FigS3 - Retract Trends 95CB - Animal Mean Trends - All Trials.fig'));
delete(fig);

% %% Make "swapped" label data tables for predictive models
% clc;
% Data.pre.pred = Data.pre.all;
% Data.pre.pred.GroupID = categorical(3-double(Data.pre.pred.GroupID),1:2,{'Ischemia','Intact'});
% Data.reach.pred = Data.reach.all;
% Data.reach.pred.GroupID = categorical(3-double(Data.reach.pred.GroupID),1:2,{'Ischemia','Intact'});
% Data.retract.pred = Data.retract.all;
% Data.retract.pred.GroupID = categorical(3-double(Data.retract.pred.GroupID),1:2,{'Ischemia','Intact'});
% 
% Data.pre.pred.N_Pre_Hat = predict(mdl.pre.all.mdl,Data.pre.pred).*Data.pre.pred.N_Total ./ (Data.pre.pred.N_Trials .* Data.pre.pred.N_Channels);
% Data.reach.pred.N_Reach_Hat = predict(mdl.reach.all.mdl,Data.reach.pred).*Data.reach.pred.N_Total./ (Data.reach.pred.N_Trials .* Data.reach.pred.N_Channels);
% Data.retract.pred.N_Retract_Hat = predict(mdl.retract.all.mdl,Data.retract.pred).*Data.retract.pred.N_Total./ (Data.retract.pred.N_Trials .* Data.retract.pred.N_Channels);
% Data.pre.all.N_Pre_Hat = predict(mdl.pre.all.mdl,Data.pre.all).*Data.pre.all.N_Total ./ (Data.pre.all.N_Trials .* Data.pre.all.N_Channels);
% Data.reach.all.N_Reach_Hat = predict(mdl.reach.all.mdl,Data.reach.all).*Data.reach.all.N_Total ./ (Data.reach.all.N_Trials .* Data.reach.all.N_Channels);
% Data.retract.all.N_Retract_Hat = predict(mdl.retract.all.mdl,Data.retract.all).*Data.retract.all.N_Total ./ (Data.retract.all.N_Trials .* Data.retract.all.N_Channels);
% 
% rSub = analyze.get_subset(r,'align',{'Grasp'});
% rWeek = analyze.trials.getChannelWeeklyGroupings(rSub,'animal',true);
% rSub = analyze.behavior.mergePredictionData(rSub,Data);
% rSub = analyze.behavior.mergeRatePerformance(rSub,false);
% disp('Pseudo-data generated.');
% 
% %% Fit Error Prediction models
% S = struct(...
%    'Link',@(mu)sqrt(asin(mu)./(pi/2)), ...
%    'Derivative',@(mu)1./(sqrt(2*pi).*sqrt(1 - mu.^2).*sqrt(asin(mu))), ...
%    'SecondDerivative',@(mu)sqrt(2/pi).*((mu./(2.*(1-mu.^2).^(3/2).*sqrt(asin(mu))))-(1./(4.*(1-mu.^2).*asin(mu).^(3/2)))), ...
%    'Inverse',@(y)sin((y.^2).*(pi/2))...
%    );
% tic; fprintf(1,'Fitting classification model for <strong>PRE</strong> phase...');
% mdl.pre.outcome.id = '10e';
% mdl.pre.outcome.tag = 'PRE-Outcome-Classifier';
% mdl.pre.outcome.mdl = fitglme(rSub,...
%    'Labels~GroupID*Area*PostOpDay+Performance_mu+epsilon_pre+(1+Performance_mu|AnimalID)+(1+epsilon_pre|ChannelID)',...
%    'FitMethod','REMPL',...
%    'Distribution','binomial',...
%    'Link',S,...
%    'BinomialSize',ones(size(rSub,1),1),...
%    'DummyVarCoding','effects');
% fprintf(1,'complete (%5.2f sec)\n',toc);
% tic; fprintf(1,'Fitting classification model for <strong>REACH</strong> phase...');
% mdl.reach.outcome.id = '11e';
% mdl.reach.outcome.tag = 'REACH-Outcome-Classifier';
% mdl.reach.outcome.mdl = fitglme(rSub,...
%    'Labels~GroupID*Area*PostOpDay+Performance_mu+epsilon_reach+(1+Performance_mu|AnimalID)+(1+epsilon_reach|ChannelID)',...
%    'FitMethod','REMPL',...
%    'Distribution','binomial',...
%    'Link',S,...
%    'BinomialSize',ones(size(rSub,1),1),...
%    'DummyVarCoding','effects');
% fprintf(1,'complete (%5.2f sec)\n',toc);
% tic; fprintf(1,'Fitting classification model for <strong>RETRACT</strong> phase...');
% mdl.retract.outcome.id = '12e';
% mdl.retract.outcome.tag = 'RETRACT-Outcome-Classifier';
% mdl.retract.outcome.mdl = fitglme(rSub,...
%    'Labels~GroupID*Area*PostOpDay+Performance_mu+epsilon_retract+(1+Performance_mu|AnimalID)+(1+epsilon_retract|ChannelID)',...
%    'FitMethod','REMPL',...
%    'Distribution','binomial',...
%    'BinomialSize',ones(size(rSub,1),1),...
%    'Link',S,...
%    'DummyVarCoding','effects');
% fprintf(1,'complete (%5.2f sec)\n',toc);
% 
%% Fit simple version of single-trial classifier model
S = struct(...
   'Link',@(mu)sqrt(asin(mu)./(pi/2)), ...
   'Derivative',@(mu)1./(sqrt(2*pi).*sqrt(1 - mu.^2).*sqrt(asin(mu))), ...
   'SecondDerivative',@(mu)sqrt(2/pi).*((mu./(2.*(1-mu.^2).^(3/2).*sqrt(asin(mu))))-(1./(4.*(1-mu.^2).*asin(mu).^(3/2)))), ...
   'Inverse',@(y)sin((y.^2).*(pi/2))...
   );
mdl.all.direct_outcome.id = '13a';
rSub.Labels = double(rSub.Outcome)-1;
mdl.all.direct_outcome.tag = 'ALL-Outcome-Classifier-Direct';
tic; fprintf(1,'Fitting classification model for <strong>ALL</strong> phases...');
mdl.all.direct_outcome.mdl = fitglme(rSub,...
   'Labels~1+(1+N_Pre_Grasp+N_Reach+N_Retract|ChannelID)',...
   'FitMethod','REMPL',...
   'Distribution','binomial',...
   'Link',S,...
   'BinomialSize',ones(size(rSub,1),1),...
   'DummyVarCoding','effects');
fprintf(1,'complete (%5.2f sec)\n',toc);

% rSub.Prediction_Outcome = predict(mdl.all.direct_outcome.mdl,rSub);
% rSub = analyze.trials.addConfusionData(rSub);
% [data2,fig2,tbl2] = analyze.trials.weeklyConfusion(rSub);

%% Estimate model for Figure 3b

mdl.all.direct_outcome_performance.id = '13b';
mdl.all.direct_outcome_performance.tag = 'Channel-Outcome-Classifier-plus-Performance';
tic; fprintf(1,'Fitting classification model for <strong>ALL</strong> phases...');
mdl.all.direct_outcome_performance.mdl = fitglme(rSub,...
   'Labels~1+Performance_mu+(1+N_Pre_Grasp+N_Reach+N_Retract|ChannelID)',...
   'FitMethod','REMPL',...
   'Distribution','binomial',...
   'Link',S,...
   'BinomialSize',ones(size(rSub,1),1),...
   'DummyVarCoding','effects');
fprintf(1,'complete (%5.2f sec)\n',toc);

%%

rSub.Prediction_Outcome = predict(mdl.all.direct_outcome_performance.mdl,rSub);
[rAUC,TID] = analyze.trials.addThresholdPrior(rSub);
rAUC = analyze.trials.addConfusionData(rAUC,rAUC.Prior); % prior == threshold
[data3,fig,tbl3] = analyze.trials.weeklyConfusion(rAUC);
saveas(fig,fullfile(outPath,'Fig3 - Outcome Classifier - Individual Channels - Performance Included.png'));
savefig(fig,fullfile(outPath,'Fig3 - Outcome Classifier - Individual Channels - Performance Included.fig'));
delete(fig);



%% Display classification model info
clc;
utils.displayModel(mdl.pre.outcome);
utils.displayModel(mdl.reach.outcome);
utils.displayModel(mdl.retract.outcome);

%% Make figure to show predictive model result: Pre Phase
fig = analyze.stat.plotROC(mdl.pre.outcome.mdl);
saveas(fig,fullfile(outPath,'Fig3 - Outcome Prediction ROC - Pre Counts - All.png'));
savefig(fig,fullfile(outPath,'Fig3 - Outcome Prediction ROC - Pre Counts - All.fig'));
delete(fig);

fig = analyze.stat.batchROC(mdl.pre.outcome.mdl,'GroupID*Area*Week','Ischemia');
saveas(fig,fullfile(outPath,'Fig3 - Outcome Prediction ROC - Pre Counts - Ischemia.png'));
savefig(fig,fullfile(outPath,'Fig3 - Outcome Prediction ROC - Pre Counts - Ischemia.fig'));
delete(fig);

fig = analyze.stat.batchROC(mdl.pre.outcome.mdl,'GroupID*Area*Week','Intact');
saveas(fig,fullfile(outPath,'Fig3 - Outcome Prediction ROC - Pre Counts - Intact.png'));
savefig(fig,fullfile(outPath,'Fig3 - Outcome Prediction ROC - Pre Counts - Intact.fig'));
delete(fig);
disp('<strong>Pre</strong> ROC figures complete.');

%% Make figure to show predictive model result: Reach Phase
fig = analyze.stat.plotROC(mdl.reach.outcome.mdl);
saveas(fig,fullfile(outPath,'Fig3 - Outcome Prediction ROC - Reach Counts - All.png'));
savefig(fig,fullfile(outPath,'Fig3 - Outcome Prediction ROC - Reach Counts - All.fig'));
delete(fig);

fig = analyze.stat.batchROC(mdl.reach.outcome.mdl,'GroupID*Area*Week','Ischemia');
saveas(fig,fullfile(outPath,'Fig3 - Outcome Prediction ROC - Reach Counts - Ischemia.png'));
savefig(fig,fullfile(outPath,'Fig3 - Outcome Prediction ROC - Reach Counts - Ischemia.fig'));
delete(fig);

fig = analyze.stat.batchROC(mdl.reach.outcome.mdl,'GroupID*Area*Week','Intact');
saveas(fig,fullfile(outPath,'Fig3 - Outcome Prediction ROC - Reach Counts - Intact.png'));
savefig(fig,fullfile(outPath,'Fig3 - Outcome Prediction ROC - Reach Counts - Intact.fig'));
delete(fig);
disp('<strong>Reach</strong> ROC figures complete.');

%% Make figure to show predictive model result: Retract Phase
fig = analyze.stat.plotROC(mdl.retract.outcome.mdl);
saveas(fig,fullfile(outPath,'Fig3 - Outcome Prediction ROC - Retract Counts - All.png'));
savefig(fig,fullfile(outPath,'Fig3 - Outcome Prediction ROC - Retract Counts - All.fig'));
delete(fig);

fig = analyze.stat.batchROC(mdl.retract.outcome.mdl,'GroupID*Area*Week','Ischemia');
saveas(fig,fullfile(outPath,'Fig3 - Outcome Prediction ROC - Retract Counts - Ischemia.png'));
savefig(fig,fullfile(outPath,'Fig3 - Outcome Prediction ROC - Retract Counts - Ischemia.fig'));
delete(fig);

fig = analyze.stat.batchROC(mdl.retract.outcome.mdl,'GroupID*Area*Week','Intact');
saveas(fig,fullfile(outPath,'Fig3 - Outcome Prediction ROC - Retract Counts - Intact.png'));
savefig(fig,fullfile(outPath,'Fig3 - Outcome Prediction ROC - Retract Counts - Intact.fig'));
delete(fig);
disp('<strong>Retract</strong> ROC figures complete.');

%% Get Area-Under-Curve statistic for different weekly-groupings
rSub = analyze.stat.addChannelROCdata(rSub,mdl);
rPivot = analyze.stat.pivotChannelAUCtable(rSub);
rSub = analyze.stat.addDirectModelROCdata(rSub,mdl);
% rWeek = analyze.stat.addWeeklyROCdata(rWeek,mdl);
% rPivot = analyze.stat.pivotWeeklyAUCtable(rWeek);
disp('Weekly <strong>AUC</strong> data included with weekly-grouped table.');

%% Make figure for Area-Under Curve trends
fig = figure('Name','Weekly AUC Trends','Color','w'); 
gCats = categorical(strcat(string(rSub.GroupID),"::",string(rSub.Area)));
gplotmatrix(rSub.Week+double(gCats).*0.1,...
   [rSub.Pre_AUC, rSub.Reach_AUC, rSub.Retract_AUC],...
   gCats,...
   [0.9 0.1 0.1; 0.9 0.1 0.1; 0.1 0.1 0.9; 0.1 0.1 0.9],...
   'x.os',[],'on','hist',{'Week'},{'AUC_{Pre}','AUC_{Reach}','AUC_{Retract}'});
ax = findobj(fig.Children,'-depth',0,'Tag','');
set(ax,'YLim',[0 1],'XColor','k','YColor','k','FontName','Arial','LineWidth',1.25);
set(findobj(fig.Children,'Tag','legend'),'Position',[0.3 0.85 0.25 0.089]);
saveas(fig,fullfile(outPath,'Fig3 - Weekly Classifier AUC by Group Area and Phase.png'));
savefig(fig,fullfile(outPath,'Fig3 - Weekly Classifier AUC by Group Area and Phase.fig'));
delete(fig);

fig = figure('Name','Performance and AUC','Color','w');
gscatter(rPivot.Performance_mu,rPivot.AUC,rPivot.Phase,[],[],[],...
   'on','Performance','AUC');
xlim([-1 1]); ylim([0 1]);
saveas(fig,fullfile(outPath,'Fig3 - Scatter AUC by Performance.png'));
savefig(fig,fullfile(outPath,'Fig3 - Scatter AUC by Performance.fig'));
delete(fig);
disp('Scatter plot of AUC trends by Animal and Performance saved.');

%% Fit model relating Performance and AUC
mdl.auc = struct;

mdl.auc.trend.id = '13a';
mdl.auc.trend.tag = 'AUC-Week-Trend';
tic; fprintf(1,'Estimating model to predict <strong>Area Under Curve</strong>...');
mdl.auc.trend.mdl = fitglme(rPivot,'AUC~Duration+(1+Phase*Phase_Duration|ChannelID)',...
   'FitMethod','REMPL',...
   'DummyVarCoding','effects'); % ~ 1-minute
fprintf(1,'complete (%6.2f sec)\n',toc);

% Add predicted values to table
rPivot.AUC_pred = predict(mdl.auc.trend.mdl,rPivot);
rPivot.AUC_resid = rPivot.AUC - rPivot.AUC_pred;

% mdl.auc.performance.id = '13b';
% mdl.auc.performance.tag = 'Performance-AUC_detrended-Trend';
% tic; fprintf(1,'Estimating model to predict <strong>Behavioral Function</strong> with random effect of AUC...');
% mdl.auc.performance.mdl = fitglme(rPivot,'Performance_mu~GroupID*Area*Week+(1+AUC_pred|ChannelID)',...
%    'FitMethod','REMPL',...
%    'DummyVarCoding','effects',...
%    'Link','identity');
% fprintf(1,'complete (%6.2f sec)\n',toc);
% 
% fig = analyze.stat.panelized_residuals(mdl.auc.performance.mdl);
% saveas(fig,fullfile(outPath,'Fig3c - Behavior Prediction Unit Model - Residuals.png'));
% savefig(fig,fullfile(outPath,'Fig3c - Behavior Prediction Unit Model - Residuals.fig'));
% delete(fig);

[gAUC,rWeek_AUC] = findgroups(rPivot(:,{'GroupID','AnimalID','Area','Week','Phase','ChannelID'}));
rWeek_AUC.Performance_mu = tanh(splitapply(@nanmean,rPivot.Performance_mu,gAUC))*0.5+0.5;
rWeek_AUC.AUC_mu = splitapply(@nanmean,rPivot.AUC,gAUC);
rWeek_AUC.Duration = splitapply(@nanmean,rPivot.Duration,gAUC);
rWeek_AUC.Phase_Duration = splitapply(@nanmean,rPivot.Phase_Duration,gAUC);
rWeek_AUC.AUC_pred = predict(mdl.auc.trend.mdl,rWeek_AUC);
rWeek_AUC.AUC_resid = rWeek_AUC.AUC_mu - rWeek_AUC.AUC_pred;

rWeek_AUC.Properties.RowNames = strcat(...
   string(rWeek_AUC.AnimalID),...
   string(rWeek_AUC.Area),'_W',...
   string(rWeek_AUC.Week),...
   string(rWeek_AUC.Phase),'_C',...
   string(rWeek_AUC.ChannelID));
mdl.auc.weeks.id = '13b';
mdl.auc.weeks.tag = 'Performance-AUC_detrended-Weekly';
tic; fprintf(1,'Estimating model to predict <strong>Weekly Behavioral Function</strong> with random effect of AUC...');
mdl.auc.weeks.mdl = fitglme(rWeek_AUC,'Performance_mu~GroupID*Week+(1+AUC_resid+Phase|AnimalID:Area)',...
   'FitMethod','REMPL',...
   'DummyVarCoding','effects',...
   'Link','logit');
fprintf(1,'complete (%6.2f sec)\n',toc);

fig = analyze.stat.panelized_residuals(mdl.auc.weeks.mdl);
saveas(fig,fullfile(outPath,'Fig3d - Weekly Behavior Prediction Unit Model - Residuals.png'));
savefig(fig,fullfile(outPath,'Fig3d - Weekly Behavior Prediction Unit Model - Residuals.fig'));
delete(fig);

disp('Model relating Performance to AUC & Week complete.');
utils.displayModel(mdl.auc);

% %% Make statistical model for AUC Trends
% mdl.pre.AUC.id  = '10f';
% mdl.pre.AUC.tag = 'Weekly-Pre-ROC-AUC';
% mdl.pre.AUC.mdl = fitglme(rWeek,...
%    'Pre_AUC~GroupID*Week+(1+Area|AnimalID)',...
%    'FitMethod','REMPL',...
%    'Distribution','normal',...
%    'Link',S,...
%    'Exclude',isnan(rWeek.Pre_AUC),...
%    'DummyVarCoding','effects');
% 
% mdl.reach.AUC.id  = '11f';
% mdl.reach.AUC.tag = 'Weekly-Reach-ROC-AUC';
% mdl.reach.AUC.mdl = fitglme(rWeek,...
%    'Reach_AUC~GroupID*Week+(1+Area|AnimalID)',...
%    'FitMethod','REMPL',...
%    'Distribution','normal',...
%    'Link',S,...
%    'Exclude',isnan(rWeek.Pre_AUC),...
%    'DummyVarCoding','effects');
% 
% mdl.retract.AUC.id  = '12f';
% mdl.retract.AUC.tag = 'Weekly-Retract-ROC-AUC';
% mdl.retract.AUC.mdl = fitglme(rWeek,...
%    'Retract_AUC~GroupID*Week+(1+Area|AnimalID)',...
%    'FitMethod','REMPL',...
%    'Distribution','normal',...
%    'Link',S,...
%    'Exclude',isnan(rWeek.Pre_AUC),...
%    'DummyVarCoding','effects');
% 
% %% Display AUC model info
% clc;
% utils.displayModel(mdl.pre.AUC);
% utils.displayModel(mdl.reach.AUC);
% utils.displayModel(mdl.retract.AUC);

%% Do multi-model prediction for trends at the "Week" level
rSub_s = rSub;
rSub_s.Properties.UserData.Excluded(rSub_s.Outcome=="Unsuccessful") = [];
rSub_s.PostOpDay_Cubed = rSub_s.PostOpDay.^3;
rSub_s(rSub_s.Outcome=="Unsuccessful",:) = [];
[fig,mdl.pre.multi_mdl,T.pre_full] = analyze.behavior.multi_model_fit(rSub_s,...
   'N_Pre_Grasp','Title','Pre-Grasp Epoch','YLim',[0 60],...
   'DurationTrendVar','Duration',...
   'Tag','Successful-Pre-Detrended-Performance',...
   'ID','10b');
saveas(fig,fullfile(outPath,'FigS3a - Pre Counts 95CB - Grouped Mean Trends - Successful Trials.png'));
savefig(fig,fullfile(outPath,'FigS3a - Pre Counts 95CB - Grouped Mean Trends - Successful Trials.fig'));
delete(fig);

[fig,mdl.reach.multi_mdl,T.reach_full] = analyze.behavior.multi_model_fit(rSub_s,...
   'N_Reach','Title','Reach Epoch','YLim',[0 60],...
   'DurationTrendVar','Reach_Epoch_Duration',...
   'Tag','Successful-Reach-Detrended-Performance',...
   'ID','11b');
saveas(fig,fullfile(outPath,'FigS3b - Reach Counts 95CB - Grouped Mean Trends - Successful Trials.png'));
savefig(fig,fullfile(outPath,'FigS3b - Reach Counts 95CB - Grouped Mean Trends - Successful Trials.fig'));
delete(fig);

[fig,mdl.retract.multi_mdl,T.retract_full] = analyze.behavior.multi_model_fit(rSub_s,...
   'N_Retract','Title','Retract Epoch','YLim',[0 60],...
   'DurationTrendVar','Retract_Epoch_Duration',...
   'Tag','Successful-Retract-Detrended-Performance',...
   'ID','12b');
saveas(fig,fullfile(outPath,'FigS3c - Retract Counts 95CB - Grouped Mean Trends - Successful Trials.png'));
savefig(fig,fullfile(outPath,'FigS3c - Retract Counts 95CB - Grouped Mean Trends - Successful Trials.fig'));
delete(fig);
disp('Multi-model daily trend estimates complete.');

%% Get prediction models first
rWeek_s = analyze.trials.getChannelWeeklyGroupings(rSub_s,'animal',true);

mdl.pre.predict.id = '10c';
mdl.pre.predict.tag = 'Weekly-Pre-Predicted_Successes';
mdl.pre.predict.mdl = fitglme(rWeek_s,...
   'n_Pre_mean~Week+Duration+(1+Week|AnimalID)',...
   'FitMethod','REMPL',...
   'Distribution','binomial',...
   'Link','logit',...
   'BinomialSize',rWeek_s.n_Total,...
   'Weights',rWeek_s.n_Blocks,...
   'DummyVarCoding','effects');

mdl.reach.predict.id = '11c';
mdl.reach.predict.tag = 'Weekly-Reach-Predicted_Successes';
mdl.reach.predict.mdl = fitglme(rWeek_s,...
   'n_Reach_mean~Week+Reach_Epoch_Duration+Duration+n_Pre_mean+(1+Week|AnimalID)',...
   'FitMethod','REMPL',...
   'Distribution','binomial',...
   'Link','logit',...
   'BinomialSize',rWeek_s.n_Total,...
   'Weights',rWeek_s.n_Blocks,...
   'DummyVarCoding','effects');

mdl.retract.predict.id = '12c';
mdl.retract.predict.tag = 'Weekly-Retract-Predicted_Successes';
mdl.retract.predict.mdl = fitglme(rWeek_s,...
   'n_Retract_mean~Week+Retract_Epoch_Duration+Duration+n_Pre_mean+(1+Week|AnimalID)',...
   'FitMethod','REMPL',...
   'Distribution','binomial',...
   'Link','logit',...
   'BinomialSize',rWeek_s.n_Total,...
   'Weights',rWeek_s.n_Blocks,...
   'DummyVarCoding','effects');
disp(mdl.pre.predict.mdl.Rsquared);
disp(mdl.reach.predict.mdl.Rsquared);
disp(mdl.retract.predict.mdl.Rsquared);

% Use prediction values in subsequent models
rWeek_s.n_Pre_pred = predict(mdl.pre.predict.mdl,rWeek_s).*rWeek_s.n_Total;
rWeek_s.n_Reach_pred = predict(mdl.reach.predict.mdl,rWeek_s).*rWeek_s.n_Total;
rWeek_s.n_Retract_pred = predict(mdl.retract.predict.mdl,rWeek_s).*rWeek_s.n_Total;
rWeek_s.Pre_err = rWeek_s.n_Pre_mean - rWeek_s.n_Pre_pred;
rWeek_s.Reach_err = rWeek_s.n_Reach_mean - rWeek_s.n_Reach_pred;
rWeek_s.Retract_err = rWeek_s.n_Retract_mean - rWeek_s.n_Retract_pred;
disp('Prediction models estimated.');

%% Fit GLME for weekly/channel grouped count data
% Make model for spike counts during "Pre" or "Baseline" epoch
clc;
mdl.pre.detrended.id = '10d';
mdl.pre.detrended.tag = 'Weekly-Pre-Detrended-Count-Successes';
mdl.pre.detrended.mdl = fitglme(rWeek_s,...
   'n_Pre_mean~GroupID*Area+(1+n_Pre_pred|AnimalID)',...
   'FitMethod','REMPL',...
   'Distribution','binomial',...
   'Link','logit',...
   'BinomialSize',rWeek_s.n_Total,...
   'Weights',rWeek_s.n_Blocks,...
   'DummyVarCoding','effects');

% Make model for spike counts during "Reach" epoch
mdl.reach.detrended.id = '11d';
mdl.reach.detrended.tag = 'Weekly-Reach-Detrended-Count-Successes';
mdl.reach.detrended.mdl = fitglme(rWeek_s,...
   'n_Reach_mean~GroupID*Area+(1+n_Reach_pred|AnimalID)',...
   'FitMethod','REMPL',...
   'Distribution','binomial',...
   'Link','logit',...
   'BinomialSize',rWeek_s.n_Total,...
   'Weights',rWeek_s.n_Blocks,...
   'DummyVarCoding','effects');


% Make model for spike counts during "Retract" epoch
mdl.retract.detrended.id = '12d';
mdl.retract.detrended.tag = 'Weekly-Retract-Detrended-Count-Successes';
mdl.retract.detrended.mdl = fitglme(rWeek_s,...
   'n_Retract_mean~GroupID*Area+(1+n_Retract_pred|AnimalID)',...
   'FitMethod','REMPL',...
   'Distribution','binomial',...
   'Link','logit',...
   'BinomialSize',rWeek_s.n_Total,...
   'Weights',rWeek_s.n_Blocks,...
   'DummyVarCoding','effects');
disp('Detrended models estimated.');

%% Make tables
% Make table for individual animal effects
writetable(rWeek_s,fullfile(defaults.files('local_tank'),'TABLE-S4.xlsx'));

% Aggregate and test random effects to get significance by
% {Group,Area,Week}
T = struct;
% fcn = struct('mu',@(x)nanmean(x),'sigma',@(x)nanstd(x));
% T.pre= analyze.stat.groupLevelTests(rWeek_s,mdl.pre.weeks,rSub,fcn,{'N_Pre_Grasp'});
T.pre = analyze.stat.weekTrendTable(mdl.pre.detrended.mdl);
writetable(T.pre,fullfile(defaults.files('local_tank'),'TABLE-1.xlsx'),'Sheet','N_PRE');
fig = analyze.trials.plotTableData(T,'Pre');
saveas(fig,fullfile(outPath,'Fig2a - Pre Weekly Group Area Count Trends - Successes.png'));
savefig(fig,fullfile(outPath,'Fig2a - Pre Weekly Group Area Count Trends - Successes.fig'));
delete(fig);

% T.reach = analyze.stat.groupLevelTests(rWeek_s,mdl.reach.weeks,rSub,fcn,{'N_Reach'});
T.reach = analyze.stat.weekTrendTable(mdl.reach.detrended.mdl);
writetable(T.reach,fullfile(defaults.files('local_tank'),'TABLE-1.xlsx'),'Sheet','N_REACH');
fig = analyze.trials.plotTableData(T,'Reach');
saveas(fig,fullfile(outPath,'Fig2b - Reach Weekly Group Area Count Trends - Successes.png'));
savefig(fig,fullfile(outPath,'Fig2b - reach Weekly Group Area Count Trends - Successes.fig'));
delete(fig);

% T.retract = analyze.stat.groupLevelTests(rWeek_s,mdl.retract.weeks,rSub,fcn,{'N_Retract'});
T.retract = analyze.stat.weekTrendTable(mdl.retract.detrended.mdl);
writetable(T.retract,fullfile(defaults.files('local_tank'),'TABLE-1.xlsx'),'Sheet','N_RETRACT');
fig = analyze.trials.plotTableData(T,'Retract');
saveas(fig,fullfile(outPath,'Fig2c - Retract Weekly Group Area Count Trends - Successes.png'));
savefig(fig,fullfile(outPath,'Fig2c - Retract Weekly Group Area Count Trends - Successes.fig'));
delete(fig);
disp('Tables saved.');

%% Display model outputs for daily trends
clc;
% Fig. S3a
utils.displayModel(mdl.pre.multi_mdl.simple); % (daily predictions for detrending, with success rate)
utils.displayModel(mdl.pre.multi_mdl);        % (detrended daily fit)
% Fig. S3b
utils.displayModel(mdl.reach.multi_mdl.simple);
utils.displayModel(mdl.reach.multi_mdl);
% Fig. S3c
utils.displayModel(mdl.retract.multi_mdl.simple);
utils.displayModel(mdl.retract.multi_mdl);

%% Display model outputs for weekly trends
% clc;
% Fig. 2a
utils.displayModel(mdl.pre.predict);   % (weekly prediction for detrending, without "performance")
utils.displayModel(mdl.pre.detrended); % (detrended weekly fit)
% Fig. 2b
utils.displayModel(mdl.reach.predict);
utils.displayModel(mdl.reach.detrended);
% Fig. 2c
utils.displayModel(mdl.retract.predict);
utils.displayModel(mdl.retract.detrended);

%% Save model outputs
tic; fprintf(1,'Saving Fig [2,S4] models...');
save(defaults.files('rate_models_pre_reach_retract_matfile'),'-struct','mdl');
fprintf(1,'complete\n'); 
fprintf(1,'\t->\t%6.2f seconds elapsed\n',toc);
utils.addHelperRepos();
sounds__.play('bell',0.8,-15);
