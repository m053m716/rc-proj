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

%%
% % % After descriptive stats, fit simple models for epoch durations % % %
UTrials.Day = UTrials.PostOpDay;
UTrials.Day_Cubed = UTrials.Day.^3;
U_success = UTrials;
U_success(U_success.Outcome=="Unsuccessful",:) = [];
glme.trialDuration = struct;

% Only fit successful trials, but do not use Neural exclusions %
glme.trialDuration.duration.mdl = fitglme(UTrials,...
   "Duration~1+GroupID*Day+(1+Day|AnimalID)",...
   "FitMethod","REMPL",...
   "Distribution",'normal',...
   "DummyVarCoding",'effects',...
   "Link",'log');
glme.trialDuration.duration.id = 5;

U_neu = UTrials;
U_neu(U_neu.Properties.UserData.Exclude | U_neu.Outcome=="Unsuccessful",:) = [];
glme.trialDuration.duration_neu.mdl = fitglme(U_neu,...
   "Duration~1+GroupID*Day+(1+Day+Duration|AnimalID)",...
   "FitMethod","REMPL",...
   "Distribution",'normal',...
   "DummyVarCoding",'effects',...
   "Link",'log');
glme.trialDuration.duration_neu.id = 6;

glme.trialDuration.reach.mdl = fitglme(U_success,...
   "Reach_Duration~1+GroupID*Day+(1+Day+Duration|AnimalID)",...
   "FitMethod","REMPL",...
   "Distribution",'normal',...
   "DummyVarCoding",'effects',...
   "Link",'log');
glme.trialDuration.reach.id = 7;

glme.trialDuration.retract.mdl = fitglme(U_success,...
   "Retract_Duration~1+GroupID*Day+(1+Day+Duration|AnimalID)",...
   "FitMethod","REMPL",...
   "Distribution",'normal',...
   "DummyVarCoding",'effects',...
   "Link",'log');
glme.trialDuration.retract.id = 8;

glme.trialDuration.proportion.mdl = fitglme(U_success,...
   "Reach_Proportion~1+GroupID*Day+(1+Day+Duration|AnimalID)",...
   "FitMethod","REMPL",...
   "Distribution",'normal',...
   "DummyVarCoding",'effects',...
   "Link",'log');
glme.trialDuration.proportion.id = 9;

%% Display models
clc;
% fprintf(1,'GLME: <strong>Duration</strong> (MODEL-%d)\n',glme.trialDuration.duration.id);
% disp(glme.trialDuration.duration.mdl);
% disp('------------------------------------------------------------------');
% fprintf(1,'<strong>Fit (MODEL-%d):</strong>\n',glme.trialDuration.duration.id);
% disp(glme.trialDuration.duration.mdl.Rsquared);
% disp('------------------------------------------------------------------');
% 
% fprintf(1,'GLME: <strong>Duration (trials for neural analyses)</strong> (MODEL-%d)\n',glme.trialDuration.duration_neu.id);
% disp(glme.trialDuration.duration_neu.mdl);
% disp('------------------------------------------------------------------');
% fprintf(1,'<strong>Fit (MODEL-%d):</strong>\n',glme.trialDuration.duration_neu.id);
% disp(glme.trialDuration.duration_neu.mdl.Rsquared);
% disp('------------------------------------------------------------------');
% 
% fprintf(1,'GLME: <strong>Reach Phase Duration</strong> (MODEL-%d)\n',glme.trialDuration.reach.id);
% disp(glme.trialDuration.reach.mdl);
% disp('------------------------------------------------------------------');
% fprintf(1,'<strong>Fit (MODEL-%d):</strong>\n',glme.trialDuration.reach.id);
% disp(glme.trialDuration.reach.mdl.Rsquared);
% disp('------------------------------------------------------------------');
% 
% fprintf(1,'GLME: <strong>Retract Phase Duration</strong> (MODEL-%d)\n',glme.trialDuration.retract.id);
% disp(glme.trialDuration.retract.mdl);
% disp('------------------------------------------------------------------');
% fprintf(1,'<strong>Fit (MODEL-%d):</strong>\n',glme.trialDuration.retract.id);
% disp(glme.trialDuration.retract.mdl.Rsquared);
% disp('------------------------------------------------------------------');
% 
% fprintf(1,'GLME: <strong>Reach Proportion</strong> (MODEL-%d)\n',glme.trialDuration.proportion.id);
% disp(glme.trialDuration.proportion.mdl);
% disp('------------------------------------------------------------------');
% fprintf(1,'<strong>Fit (MODEL-%d):</strong>\n',glme.trialDuration.proportion.id);
% disp(glme.trialDuration.proportion.mdl.Rsquared);
% disp('------------------------------------------------------------------');

utils.displayModel(glme.trialDuration.duration,0.05,'Fig.S2a');
utils.displayModel(glme.trialDuration.duration_neu,0.05,'Fig.S2b');
utils.displayModel(glme.trialDuration.reach,0.05,'Fig.S2c');
utils.displayModel(glme.trialDuration.retract,0.05,'Fig.S2d');
utils.displayModel(glme.trialDuration.proportion,0.05,'Fig.S2e');

%%
% Save models %
tic; fprintf(1,'Saving Fig [S2] models...');
tmp = glme.trialDuration;
save(defaults.files('duration_models_matfile'),'-struct','tmp');
clear tmp;
fprintf(1,'complete\n'); 
fprintf(1,'\t->\t%6.2f seconds elapsed\n',toc);
utils.addHelperRepos();
sounds__.play('bell',0.8,-15);

%%
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

% % Fig S2e: Reach phase proportion % %
fig = analyze.behavior.per_animal_mean_trends(...
   Utmp,...    % First required argument is always the data table
   'Reach_Proportion',... % Second required argument is the response variable name
   'Title','Proportion of Trial in Reach Phase',...
   'DoExclusions',false,...
   'YLim',[0 1],...
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
