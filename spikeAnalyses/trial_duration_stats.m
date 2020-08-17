%TRIAL_DURATION_STATS Run stats on trial durations, split into sub-epochs (Fig S1 stats; Fig S2)

close all force;
clearvars -except UTrials;
clc;
if exist('UTrials','var')==0
   load(defaults.files('rate_unique_trials_matfile'),'UTrials'); % "Unique trials" from T (main rate table): For analyze.behavior
end

% Get descriptive statistics for total duration ('Duration'), Reach phase
% ('Reach_Duration'), and Retract phase ('Retract_Duration')
UTrials.Reach_Proportion = UTrials.Reach_Duration ./ UTrials.Duration;
UTrials = analyze.behavior.getDescriptiveTimingStats(UTrials,'Duration');
UTrials = analyze.behavior.getDescriptiveTimingStats(UTrials,'Reach_Duration');
UTrials = analyze.behavior.getDescriptiveTimingStats(UTrials,'Retract_Duration');
UTrials = analyze.behavior.getDescriptiveTimingStats(UTrials,'Reach_Proportion');

% % % After descriptive stats, fit simple models for epoch durations % % %
exc = UTrials.Properties.UserData.Exclude;
glme_duration = fitglme(UTrials,...
   "Duration~GroupID*PostOpDay+(1+PostOpDay|AnimalID)",...
   "FitMethod","REMPL",...
   "Exclude",exc);
glme_reach = fitglme(UTrials,...
   "Reach_Duration~GroupID*PostOpDay*Duration+(1+PostOpDay|AnimalID)",...
   "FitMethod","REMPL",...
   "Exclude",exc);
glme_retract = fitglme(UTrials,...
   "Retract_Duration~GroupID*PostOpDay*Duration+(1+PostOpDay|AnimalID)",...
   "FitMethod","REMPL",...
   "Exclude",exc);
glme_reach_proportion = fitglme(UTrials,...
   "Reach_Proportion~GroupID*PostOpDay*Duration+(1|AnimalID)",...
   "FitMethod","REMPL",...
   "Exclude",exc);

disp(glme_duration);
disp(glme_duration.Rsquared);
[~,~,re_stats_duration] = randomEffects(glme_duration);
disp(re_stats_duration(2:2:end,[1:4,8]));

disp(glme_reach);
disp(glme_reach.Rsquared);
[~,~,re_stats_reach] = randomEffects(glme_reach);
disp(re_stats_reach(:,[1:4,8]));

disp(glme_retract);
disp(glme_retract.Rsquared);
[~,~,re_stats_retract] = randomEffects(glme_retract);
disp(re_stats_retract(:,[1:4,8]));

disp(glme_reach_proportion);
disp(glme_reach_proportion.Rsquared);
[~,~,re_stats_proportion] = randomEffects(glme_duration);
disp(re_stats_proportion(:,[1:4,8]));

% % % Generate and save figures for Supplementary Figure S2 % % %
outPath = defaults.files('reach_extension_figure_dir');
if exist(outPath,'dir')==0
   mkdir(outPath);
end

% % Fig S2a: Total duration - all trials % %
[fig,mdl_duration] = analyze.behavior.per_animal_mean_trends(...
   UTrials,...    % First required argument is always the data table
   'Duration',... % Second required argument is the response variable name
   'Title','Total Reach Duration',...
   'DoExclusions',false,...
   'ModelFormula','%s~1+Day+Day_Cubed', ... % Optional 'ModelFormula' is per-animal trend to fit
   'YLim',[0 1.6] ... % Determined empirically
   );
saveas(fig,fullfile(outPath,'FigS2a - Duration Trends - All.png'));
savefig(fig,fullfile(outPath,'FigS2a - Duration Trends - All.fig'));
delete(fig);

% % Fig S2b: Total duration - only included successful trials % %
Utmp = UTrials;
Utmp.Properties.UserData.Exclude = Utmp.Properties.UserData.Exclude | ...
   Utmp.Outcome=="Unsuccessful";
fig = analyze.behavior.per_animal_mean_trends(...
   Utmp,...    % First required argument is always the data table
   'Duration',... % Second required argument is the response variable name
   'Title','Total Reach Duration (Neural Analysis exclusions applied)',...
   'DoExclusions',true,...
   'ModelFormula','%s~1+Day+Day_Cubed', ... % Optional 'ModelFormula' is per-animal trend to fit
   'LegendLocation','southwest' ...
   );
saveas(fig,fullfile(outPath,'FigS2b - Duration Trends - successful neural trials only.png'));
savefig(fig,fullfile(outPath,'FigS2b - Duration Trends - successful neural trials only.fig'));
delete(fig);

% % Fig S2c: Reach duration % %
fig = analyze.behavior.per_animal_mean_trends(...
   Utmp,...    % First required argument is always the data table
   'Reach_Duration',... % Second required argument is the response variable name
   'Title','Reach Phase Duration (successful trials)',...
   'DoExclusions',false,...
   'ModelFormula','%s~1+Day+Day_Cubed', ... % Optional 'ModelFormula' is per-animal trend to fit
   'LegendLocation','northeast' ...
   );
saveas(fig,fullfile(outPath,'FigS2c - Reach Phase Duration - successful trials.png'));
savefig(fig,fullfile(outPath,'FigS2c - Reach Phase Duration - successful trials.fig'));
delete(fig);

% % Fig S2d: Retract duration % %
fig = analyze.behavior.per_animal_mean_trends(...
   Utmp,...    % First required argument is always the data table
   'Retract_Duration',... % Second required argument is the response variable name
   'Title','Retract Phase Duration (successful trials)',...
   'DoExclusions',false,...
   'ModelFormula','%s~1+Day+Day_Cubed', ... % Optional 'ModelFormula' is per-animal trend to fit
   'LegendLocation','northeast' ...
   );
saveas(fig,fullfile(outPath,'FigS2d - Retract Phase Duration - successful trials.png'));
savefig(fig,fullfile(outPath,'FigS2d - Retract Phase Duration - successful trials.fig'));
delete(fig);

fig = analyze.behavior.per_animal_mean_trends(...
   Utmp,...    % First required argument is always the data table
   'Reach_Proportion',... % Second required argument is the response variable name
   'Title','Proportion of Trial in Reach Phase',...
   'DoExclusions',false,...
   'ModelFormula','%s~1+Day+Day_Cubed', ... % Optional 'ModelFormula' is per-animal trend to fit
   'LegendLocation','northeast' ...
   );
saveas(fig,fullfile(outPath,'FigS2e - Reach Proportion - successful trials.png'));
savefig(fig,fullfile(outPath,'FigS2e - Reach Proportion - successful trials.fig'));
delete(fig);


% Train a classifier for "Type" of support association
Full = UTrials(~UTrials.Properties.UserData.Exclude,...
   {'AnimalID','GroupID','PostOpDay','Duration','SupportType'});
Predictors = UTrials(~UTrials.Properties.UserData.Exclude,...
   {'AnimalID','GroupID','PostOpDay','Duration'});
mdl = fitcauto(Full,'SupportType',... % Target labels to fit
   'Learners',{'discr','ensemble','linear','svm','tree'});

% Generate confusion matrix for classification of Support Type
fig = figure('Name','Support Type Classification Confusion',...
   'Color','w','Units','Normalized','Position',[0.35 0.35 0.35 0.35]);
plotconfusion(Full.SupportType,predict(mdl,Predictors));
saveas(fig,fullfile(outPath,'FigS3 - Support Classification.png'));
savefig(fig,fullfile(outPath,'FigS3 - Support Classification.fig'));
delete(fig);

% Generate bar plot of predictor importance
fig = figure('Name','Support Type Predictor Importance',...
   'Color','w','Units','Normalized','Position',[0.45 0.35 0.35 0.35]);
bar(categorical(mdl.PredictorNames),mdl.predictorImportance);
saveas(fig,fullfile(outPath,'FigS3 - Support Predictor Importance.png'));
savefig(fig,fullfile(outPath,'FigS3 - Support Predictor Importance.fig'));
delete(fig);

% Track Support Type by Post-Op Day
[Groupings,TID] = findgroups(Full(:,{'SupportType','PostOpDay'}));
[SubGroupings,TID2] = findgroups(TID(:,'SupportType'));
N = splitapply(@(x)numel(x),Full.Duration,Groupings);
[AnimalGroups,TID_A] = findgroups(Full(:,{'AnimalID','PostOpDay','SupportType'}));
Na = splitapply(@(x)numel(x),Full.Duration,AnimalGroups);
uS = unique(TID_A.SupportType);
markers = ["o","s","h"];

fig = figure('Name','Support Type by Post-Op Day','Color','w',...
   'Position',[681   644   745   335]);
ax = axes(fig,'NextPlot','add','XColor','k','YColor','k',...
   'LineWidth',1.5,'FontName','Arial');
splitapply(@(x,y,name)plot(ax,x,y,'DisplayName',string(name(1))),...
   TID.PostOpDay,N,TID.SupportType,SubGroupings);
legend(ax,'FontName','Arial','TextColor','black');
xlabel(ax,'Post-Op Day','FontName','Arial','Color','k');
ylabel(ax,'Count','FontName','Arial','Color','k');
title(ax,'Support Type by Day','FontName','Arial','Color','k');
for ii = 1:numel(uS)
   idx = TID_A.SupportType==uS(ii);
   line(ax,TID_A.PostOpDay(idx)+randn(sum(idx),1).*0.15, Na(idx),...
      'DisplayName',sprintf('Individual %s',string(uS(ii))),...
      'LineStyle','none',...
      'Marker',markers(ii),...
      'MarkerFaceColor',ax.ColorOrder(ii,:),...
      'MarkerEdgeColor','none',...
      'MarkerSize',6);
end
saveas(fig,fullfile(outPath,'FigS3 - Support Type Trends.png'));
savefig(fig,fullfile(outPath,'FigS3 - Support Type Trends.fig'));
delete(fig);

% At end, save results that have been appended as UserData fields
save(defaults.files('rate_unique_trials_matfile'),...
   'UTrials','glme_duration','glme_reach',...
   'glme_retract','glme_reach_proportion','mdl',...
   '-v7.3');
