%UNIT_LEARNING_STATS Use Mitz/Wise approach for Figs 2, S4: count spikes in pre-defined epochs to define activity
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

tic;

%%
clc;
% Create corresponding figures.
outPath = defaults.files('reach_extension_figure_dir');
if exist(outPath,'dir')==0
   mkdir(outPath);
end

% Initialize data output variables and data subset to pass to figures %
Data = struct;
mdl = struct;
rSub = r;
rSub.Properties.UserData.Excluded = rSub.Properties.UserData.Excluded | rSub.Outcome=="Unsuccessful";

% Generate figures corresponding to each epoch %
% % Pre-Grasp Figures % %
[fig,mdl.pre.count,Data.pre.count] = analyze.behavior.per_animal_area_mean_trends(rSub,...
   'N_Pre_Grasp',...
   'YLabel','Spike Count',...
   'YLim',[0 60],...
   'Tag','Fig2a',...
   'Title','Activity: Pre-Grasp (successful + included)');
saveas(fig,fullfile(outPath,'Fig2a - Pre-Grasp Trends 95CB - Animal Mean Trends.png'));
savefig(fig,fullfile(outPath,'Fig2a - Pre-Grasp Trends 95CB - Animal Mean Trends.fig'));
delete(fig);

[fig,mdl.pre.rate,Data.pre.rate] = analyze.behavior.per_animal_area_mean_rates(rSub,...
   'N_Pre_Grasp',...
   'YLabel','Spike Rate',...
   'YLim',[5 25],...
   'ModelNumber',10,...
   'Title','Activity: Pre-Grasp Rates (successful + included)');
saveas(fig,fullfile(outPath,'Fig2d - Pre-Grasp Rates 95CB - Animal Mean Trends.png'));
savefig(fig,fullfile(outPath,'Fig2d - Pre-Grasp Rates 95CB - Animal Mean Trends.fig'));
delete(fig);

% % Reach Figures % %
[fig,mdl.reach.count,Data.reach.count] = analyze.behavior.per_animal_area_mean_trends(rSub,...
   'N_Reach',...
   'YLabel','Spike Count',...
   'YLim',[0 35],...
   'Tag','Fig2b',...
   'Title','Activity: Reach (successful + included)');
saveas(fig,fullfile(outPath,'Fig2b - Reach Trends 95CB - Animal Mean Trends.png'));
savefig(fig,fullfile(outPath,'Fig2b - Reach Trends 95CB - Animal Mean Trends.fig'));
delete(fig);

[fig,mdl.reach.rate,Data.reach.rate] = analyze.behavior.per_animal_area_mean_rates(rSub,...
   'N_Reach',...
   'DurationVar','Reach_Epoch_Duration',...
   'YLabel','Spike Rate',...
   'YLim',[5 25],...
   'ModelNumber',11,...
   'Title','Activity: Reach Rates (successful + included)');
saveas(fig,fullfile(outPath,'Fig2e - Reach Rates 95CB - Animal Mean Trends.png'));
savefig(fig,fullfile(outPath,'Fig2e - Reach Rates 95CB - Animal Mean Trends.fig'));
delete(fig);

% % Retract Figures % %
[fig,mdl.retract.count,Data.retract.count] = analyze.behavior.per_animal_area_mean_trends(rSub,...
   'N_Retract',...
   'YLabel','Spike Count',...
   'YLim',[0 35],...
   'Tag','Fig2c',...
   'Title','Activity: Retract (successful + included)');
saveas(fig,fullfile(outPath,'Fig2c - Retract Trends 95CB - Animal Mean Trends.png'));
savefig(fig,fullfile(outPath,'Fig2c - Retract Trends 95CB - Animal Mean Trends.fig'));
delete(fig);

[fig,mdl.retract.rate,Data.retract.rate] = analyze.behavior.per_animal_area_mean_rates(rSub,...
   'N_Retract',...
   'DurationVar','Retract_Epoch_Duration',...
   'YLabel','Spike Rate',...
   'YLim',[5 25],...
   'ModelNumber',12,...
   'Title','Activity: Retract Rates (successful + included)');
saveas(fig,fullfile(outPath,'Fig2f - Retract Rates 95CB - Animal Mean Trends.png'));
savefig(fig,fullfile(outPath,'Fig2f - Retract Rates 95CB - Animal Mean Trends.fig'));
delete(fig);

%% Break down rSub into weeks and get table of empirical values/stats
rSub = rSub(~rSub.Properties.UserData.Excluded,:);
rSub.Properties.UserData.Excluded = rSub.Properties.UserData.Excluded(~rSub.Properties.UserData.Excluded);
rSub.Week = ceil(rSub.PostOpDay/7);
rSub.Properties.UserData.Excluded(rSub.Week > 4) = [];
rSub(rSub.Week > 4,:) = [];
[weekGroups,rWeek] = findgroups(rSub(:,{'Group','AnimalID','Week','Area'}));
rWeek.Week_Cubed = rWeek.Week.^3;
rWeek.n_Obs = splitapply(@numel,weekGroups,weekGroups);
% Make model for spike counts during "Pre" epoch
rWeek.n_Pre_mean = splitapply(@nanmean,rSub.N_Pre_Grasp,weekGroups);
rWeek.n_Pre_std  = splitapply(@nanstd,rSub.N_Pre_Grasp,weekGroups);
mdl.pre.weeks = fitglme(rWeek,...
   'n_Pre_mean~Group*Area*Week+(1+Week+Week_Cubed|AnimalID)',...
   'FitMethod','REMPL',...
   'DummyVarCoding','effects');
rWeek = analyze.stat.parseLevelTests(rWeek,mdl.pre.weeks);
% Make model for spike rate during "Reach" epoch
rWeek.rate_Reach_mean = splitapply(@nanmean,rSub.N_Reach./rSub.Reach_Epoch_Duration,weekGroups);
rWeek.rate_Reach_std  = splitapply(@nanstd,rSub.N_Reach./rSub.Reach_Epoch_Duration,weekGroups);
mdl.reach.weeks = fitglme(rWeek,...
   'rate_Reach_mean~Group*Area*Week+(1+Week+Week_Cubed|AnimalID)',...
   'FitMethod','REMPL',...
   'DummyVarCoding','effects');
rWeek = analyze.stat.parseLevelTests(rWeek,mdl.reach.weeks);
% Make model for spike rate during "Retract" epoch
rWeek.rate_Retract_mean = splitapply(@nanmean,rSub.N_Retract./rSub.Retract_Epoch_Duration,weekGroups);
rWeek.rate_Retract_std  = splitapply(@nanstd,rSub.N_Retract./rSub.Retract_Epoch_Duration,weekGroups);
mdl.retract.weeks = fitglme(rWeek,...
   'rate_Retract_mean~Group*Area*Week+(1+Week+Week_Cubed|AnimalID)',...
   'FitMethod','REMPL',...
   'DummyVarCoding','effects');

%% Make tables

% Make table for individual animal effects
rWeek = analyze.stat.parseLevelTests(rWeek,mdl.retract.weeks);
writetable(rWeek,fullfile(defaults.files('local_tank'),'TABLE-S4.xlsx'));


% Aggregate and test random effects to get significance by
% {Group,Area,Week}
T = struct;
fcn = struct('mu',@(x)nanmean(x),'sigma',@(x)nanstd(x));
T.pre = analyze.stat.groupLevelTests(rWeek,mdl.pre.weeks,rSub,fcn,{'N_Pre_Grasp'});
writetable(T.pre,fullfile(defaults.files('local_tank'),'TABLE-1.xlsx'),'Sheet','N_PRE');

% Change function handle for the rate ones
fcn = struct('mu',@(x,t)nanmean(rdivide(x,t)),'sigma',@(x,t)nanstd(rdivide(x,t)));
T.reach = analyze.stat.groupLevelTests(rWeek,mdl.reach.weeks,rSub,fcn,{'N_Reach','Reach_Epoch_Duration'});
writetable(T.reach,fullfile(defaults.files('local_tank'),'TABLE-1.xlsx'),'Sheet','RATE_REACH');

T.retract = analyze.stat.groupLevelTests(rWeek,mdl.retract.weeks,rSub,fcn,{'N_Retract','Retract_Epoch_Duration'});
writetable(T.retract,fullfile(defaults.files('local_tank'),'TABLE-1.xlsx'),'Sheet','RATE_RETRACT');

%% Display model outputs
clc;
utils.displayModel(mdl.pre.count,0.05,'Fig2a','MODEL-10a');
utils.displayModel(mdl.reach.count,0.05,'Fig2b','MODEL-11a');
utils.displayModel(mdl.retract.count,0.05,'Fig2c','MODEL-12a');
utils.displayModel(mdl.pre.rate.main,0.05,'Fig2d','MODEL-10b');
utils.displayModel(mdl.reach.rate.main,0.05,'Fig2e','MODEL-11b');
utils.displayModel(mdl.retract.rate.main,0.05,'Fig2f','MODEL-12b');
utils.displayModel(mdl.pre.weeks,0.05,'Table1','MODEL-10c');
utils.displayModel(mdl.reach.weeks,0.05,'Table2','MODEL-11c');
utils.displayModel(mdl.retract.weeks,0.05,'Table3','MODEL-12c');

%% Save model outputs
tic; fprintf(1,'Saving Fig [2,S4] models...');
save(defaults.files('rate_models_pre_reach_retract_matfile'),'-struct','mdl');
fprintf(1,'complete\n'); 
fprintf(1,'\t->\t%6.2f seconds elapsed\n',toc);
utils.addHelperRepos();
sounds__.play('bell',0.8,-15);
