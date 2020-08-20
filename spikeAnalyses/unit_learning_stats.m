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
% % Define "fixed-epoch" models % %
fprintf(1,'Fitting <strong>Pre</strong> epoch...');
glme.unitLearning = struct;
glme.unitLearning.pre.mdl = fitglme(r,"N_Pre_Grasp~1+Area*Group*PostOpDay+(1|AnimalID)+(1+PostOpDay*Reach_Epoch_Duration|ChannelID)",...
   "Exclude",r.Properties.UserData.Excluded,...
   "FitMethod","REMPL",...
   "Distribution","Poisson",...
   "Link","log");
glme.unitLearning.pre.id = nan;
fprintf(1,'complete\n');
fprintf(1,'Fitting <strong>Grasp</strong> epoch...');
N = r.N_Total;
N(r.Properties.UserData.Excluded | r.Outcome=="Unsuccessful") = 1;
glme.unitLearning.grasp.mdl = fitglme(r,"N_Grasp~1+Area*Group*PostOpDay+(1|AnimalID)+(1+PostOpDay*Duration+N_Pre_Grasp|ChannelID)",...
   "Exclude",r.Properties.UserData.Excluded | r.Outcome=="Unsuccessful",...
   "FitMethod","REMPL",...
   "BinomialSize",N,...
   "Distribution","Binomial",...
   "Link","logit");
glme.unitLearning.grasp.id = nan;
fprintf(1,'complete\n');
% % Define "variable-epoch" models % %
fprintf(1,'Fitting <strong>Reach</strong> epoch...');
glme.unitLearning.reach.mdl = fitglme(r,"N_Reach~1+Area*Group*PostOpDay+(1|AnimalID)+(1+PostOpDay*Reach_Epoch_Duration+N_Pre_Grasp|ChannelID)",...
   "Exclude",r.Properties.UserData.Excluded | r.Outcome=="Unsuccessful",...
   "FitMethod","REMPL",...
   "Distribution","Poisson",...
   "Link","log");
glme.unitLearning.reach.id = nan;
fprintf(1,'complete\n');
fprintf(1,'Fitting <strong>Retract</strong> epoch...');
glme.unitLearning.retract.mdl = fitglme(r,"N_Retract~1+Area*Group*PostOpDay+(1|AnimalID)+(1+PostOpDay*Retract_Epoch_Duration+N_Pre_Grasp|ChannelID)",...
   "Exclude",r.Properties.UserData.Excluded | r.Outcome=="Unsuccessful",...
   "FitMethod","REMPL",...
   "Distribution","Poisson",...
   "Link","log");
glme.unitLearning.retract.id = nan;
fprintf(1,'complete\n');
fprintf(1,'%6.2f seconds elapsed\n',toc);

% % Display model outputs
% fprintf(1,'\n-------------------------------------------------------------\n');
% fprintf(1,'<strong>Multi-Unit Trend Model Estimates</strong>\n');
% fprintf(1,'\n-------------------------------------------------------------\n');
% fprintf(1,'\n\n<strong>Pre-Grasp</strong> (MODEL-%d)\n\n',glme.unitLearning.pre.id);
% disp(glme.unitLearning.pre.mdl);
% fprintf(1,'\n-------------------------------------------------------------\n');
% fprintf(1,'\n<strong>FIT</strong> (MODEL-%d)\n',glme.unitLearning.pre.id);
% disp(glme.unitLearning.pre.mdl.Rsquared);
% fprintf(1,'\n-------------------------------------------------------------\n');
% fprintf(1,'\n\n<strong>Reach</strong> (MODEL-%d)\n\n',glme.unitLearning.reach.id);
% disp(glme.unitLearning.reach.mdl);
% fprintf(1,'\n-------------------------------------------------------------\n');
% fprintf(1,'\n<strong>FIT</strong> (MODEL-%d)\n',glme.unitLearning.reach.id);
% disp(glme.unitLearning.reach.mdl.Rsquared);
% fprintf(1,'\n-------------------------------------------------------------\n');
% fprintf(1,'\n\n<strong>Grasp</strong> (MODEL-%d)\n\n',glme.unitLearning.grasp.id);
% disp(glme.unitLearning.grasp.mdl);
% fprintf(1,'\n-------------------------------------------------------------\n');
% fprintf(1,'\n<strong>FIT</strong> (MODEL-%d)\n',glme.unitLearning.grasp.id);
% disp(glme.unitLearning.grasp.mdl.Rsquared);
% fprintf(1,'\n-------------------------------------------------------------\n');
% fprintf(1,'\n\n<strong>Retract</strong> (MODEL-%d)\n\n',glme.unitLearning.retract.id);
% disp(glme.unitLearning.retract.mdl);
% fprintf(1,'\n-------------------------------------------------------------\n');
% fprintf(1,'\n<strong>FIT</strong> (MODEL-%d)\n',glme.unitLearning.retract.id);
% disp(glme.unitLearning.retract.mdl.Rsquared);
% fprintf(1,'\n-------------------------------------------------------------\n');

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
% rSub = r((~r.Properties.UserData.Excluded) & r.Outcome=="Successful",:);
% rSub.Properties.UserData.Excluded = rSub.Properties.UserData.Excluded(~rSub.Properties.UserData.Excluded);
rSub = r;
rSub.Properties.UserData.Excluded = rSub.Properties.UserData.Excluded | rSub.Outcome=="Unsuccessful";

% Generate figures corresponding to each epoch %
% % Pre-Grasp Figures % %
% fig = analyze.behavior.epochSpikeTrends_Split(r,glme.unitLearning.pre.mdl,0.6);       
% saveas(fig,fullfile(outPath,'FigS4 - Observed Pre-Grasp Trends.png'));
% savefig(fig,fullfile(outPath,'FigS4 - Observed Pre-Grasp Trends.fig'));
% delete(fig);
% 
% fig = analyze.behavior.epochSpikeFits(r,'N_Pre_Grasp',0.6);       
% saveas(fig,fullfile(outPath,'FigS4 - Pre-Grasp Trends 95CB.png'));
% savefig(fig,fullfile(outPath,'FigS4 - Pre-Grasp Trends 95CB.fig'));
% delete(fig);
% 
% fig = analyze.behavior.epochSpikeFits_Animals(r,'N_Pre_Grasp',0.6);       
% saveas(fig,fullfile(outPath,'FigS4 - Pre-Grasp Trends 95CB - Animals.png'));
% savefig(fig,fullfile(outPath,'FigS4 - Pre-Grasp Trends 95CB - Animals.fig'));
% delete(fig);

[fig,mdl.pre.count,Data.pre.count] = analyze.behavior.per_animal_area_mean_trends(rSub,...
   'N_Pre_Grasp',...
   'YLabel','Spike Count',...
   'YLim',[0 60],...
   'Tag','Fig2a',...
   'Title','Activity: Pre-Grasp (successful + included)');
saveas(fig,fullfile(outPath,'Fig2 - Pre-Grasp Trends 95CB - Animal Mean Trends.png'));
savefig(fig,fullfile(outPath,'Fig2 - Pre-Grasp Trends 95CB - Animal Mean Trends.fig'));
delete(fig);

[fig,mdl.pre.rate,Data.pre.rate] = analyze.behavior.per_animal_area_mean_rates(rSub,...
   'N_Pre_Grasp',...
   'YLabel','Spike Rate',...
   'YLim',[5 25],...
   'ModelNumber',10,...
   'Title','Activity: Pre-Grasp Rates (successful + included)');
saveas(fig,fullfile(outPath,'Fig2 - Pre-Grasp Rates 95CB - Animal Mean Trends.png'));
savefig(fig,fullfile(outPath,'Fig2 - Pre-Grasp Rates 95CB - Animal Mean Trends.fig'));
delete(fig);

% % Reach Figures % %
% fig = analyze.behavior.epochSpikeTrends_Split(r,glme.unitLearning.reach.mdl,'Reach_Epoch_Duration');       
% saveas(fig,fullfile(outPath,'FigS4 - Observed Reach Trends.png'));
% savefig(fig,fullfile(outPath,'FigS4 - Observed Reach Trends.fig'));
% delete(fig);
% 
% fig = analyze.behavior.epochSpikeFits(r,'N_Reach','Reach_Epoch_Duration');       
% saveas(fig,fullfile(outPath,'FigS4 - Reach Trends 95CB.png'));
% savefig(fig,fullfile(outPath,'FigS4 - Reach Trends 95CB.fig'));
% delete(fig);
% 
% fig = analyze.behavior.epochSpikeFits_Animals(r,'N_Reach','Reach_Epoch_Duration');       
% saveas(fig,fullfile(outPath,'FigS4 - Reach Trends 95CB - Animals.png'));
% savefig(fig,fullfile(outPath,'FigS4 - Reach Trends 95CB - Animals.fig'));
% delete(fig);

[fig,mdl.reach.count,Data.reach.count] = analyze.behavior.per_animal_area_mean_trends(rSub,...
   'N_Reach',...
   'YLabel','Spike Count',...
   'YLim',[0 35],...
   'Tag','Fig2b',...
   'Title','Activity: Reach (successful + included)');
saveas(fig,fullfile(outPath,'Fig2 - Reach Trends 95CB - Animal Mean Trends.png'));
savefig(fig,fullfile(outPath,'Fig2 - Reach Trends 95CB - Animal Mean Trends.fig'));
delete(fig);

[fig,mdl.reach.rate,Data.reach.rate] = analyze.behavior.per_animal_area_mean_rates(rSub,...
   'N_Reach',...
   'DurationVar','Reach_Epoch_Duration',...
   'YLabel','Spike Rate',...
   'YLim',[5 25],...
   'ModelNumber',11,...
   'Title','Activity: Reach Rates (successful + included)');
saveas(fig,fullfile(outPath,'Fig2 - Reach Rates 95CB - Animal Mean Trends.png'));
savefig(fig,fullfile(outPath,'Fig2 - Reach Rates 95CB - Animal Mean Trends.fig'));
delete(fig);

% % Retract Figures % %
% fig = analyze.behavior.epochSpikeTrends_Split(r,glme.unitLearning.retract.mdl,'Retract_Epoch_Duration');       
% saveas(fig,fullfile(outPath,'FigS4 - Observed Retract Trends.png'));
% savefig(fig,fullfile(outPath,'FigS4 - Observed Retract Trends.fig'));
% delete(fig);
% 
% fig = analyze.behavior.epochSpikeFits(r,'N_Retract','Retract_Epoch_Duration');       
% saveas(fig,fullfile(outPath,'FigS4 - Retract Trends 95CB.png'));
% savefig(fig,fullfile(outPath,'FigS4 - Retract Trends 95CB.fig'));
% delete(fig);
% 
% fig = analyze.behavior.epochSpikeFits_Animals(r,'N_Retract','Retract_Epoch_Duration');       
% saveas(fig,fullfile(outPath,'FigS4 - Retract Trends 95CB - Animals.png'));
% savefig(fig,fullfile(outPath,'FigS4 - Retract Trends 95CB - Animals.fig'));
% delete(fig);

[fig,mdl.retract.count,Data.retract.count] = analyze.behavior.per_animal_area_mean_trends(rSub,...
   'N_Retract',...
   'YLabel','Spike Count',...
   'YLim',[0 35],...
   'Tag','Fig2c',...
   'Title','Activity: Retract (successful + included)');
saveas(fig,fullfile(outPath,'Fig2 - Retract Trends 95CB - Animal Mean Trends.png'));
savefig(fig,fullfile(outPath,'Fig2 - Retract Trends 95CB - Animal Mean Trends.fig'));
delete(fig);

[fig,mdl.retract.rate,Data.retract.rate] = analyze.behavior.per_animal_area_mean_rates(rSub,...
   'N_Retract',...
   'DurationVar','Retract_Epoch_Duration',...
   'YLabel','Spike Rate',...
   'YLim',[5 25],...
   'ModelNumber',12,...
   'Title','Activity: Retract Rates (successful + included)');
saveas(fig,fullfile(outPath,'Fig2 - Retract Rates 95CB - Animal Mean Trends.png'));
savefig(fig,fullfile(outPath,'Fig2 - Retract Rates 95CB - Animal Mean Trends.fig'));
delete(fig);


%% Display model outputs
% clc;
% fprintf(1,'\n-------------------------------------------------------------\n');
% fprintf(1,'<strong>Multi-Unit Rate Model Estimates</strong>\n');
% fprintf(1,'\n-------------------------------------------------------------\n');
% fprintf(1,'\n\n<strong>Pre-Grasp Rate</strong> (MODEL-%d: %s)\n\n',...
%    mdl.pre.rate.id,mdl.pre.rate.main.ResponseName);
% disp(mdl.pre.rate.fixedEffects);
% fprintf(1,'\n-------------------------------------------------------------\n');
% disp(anova(mdl.pre.rate.main));
% fprintf(1,'\n<strong>FIT</strong> (MODEL-%d: %s)\n',...
%    mdl.pre.rate.id,mdl.pre.rate.main.ResponseName);
% disp(mdl.pre.rate.main.Rsquared);
% fprintf(1,'\n-------------------------------------------------------------\n');
% fprintf(1,'\n\n<strong>Reach</strong> (MODEL-%d: %s)\n\n',...
%    mdl.reach.rate.id,mdl.reach.rate.main.ResponseName);
% disp(mdl.reach.rate.fixedEffects);
% fprintf(1,'\n-------------------------------------------------------------\n');
% disp(anova(mdl.reach.rate.main));
% fprintf(1,'\n<strong>FIT</strong> (MODEL-%d: %s)\n',...
%    mdl.reach.rate.id,mdl.reach.rate.main.ResponseName);
% disp(mdl.reach.rate.main.Rsquared);
% fprintf(1,'\n-------------------------------------------------------------\n');
% fprintf(1,'\n\n<strong>Retract</strong> (MODEL-%d: %s)\n\n',...
%    mdl.retract.rate.id,mdl.retract.rate.main.ResponseName);
% disp(mdl.retract.rate.fixedEffects);
% fprintf(1,'\n-------------------------------------------------------------\n');
% disp(anova(mdl.retract.rate.main));
% fprintf(1,'\n<strong>FIT</strong> (MODEL-%d: %s)\n',...
%    mdl.retract.rate.id,mdl.retract.rate.main.ResponseName);
% disp(mdl.retract.rate.main.Rsquared);
% fprintf(1,'\n-------------------------------------------------------------\n');
utils.displayModel(mdl.pre.count,0.05,'Poisson','Fig2a::MODEL-10a');
utils.displayModel(mdl.reach.count,0.05,'Poisson','Fig2b::MODEL-11a');
utils.displayModel(mdl.retract.count,0.05,'Poisson','Fig2c::MODEL-12a');
utils.displayModel(mdl.pre.rate.main,0.05,'GLME','Fig2d::MODEL-10b');
utils.displayModel(mdl.reach.rate.main,0.05,'GLME','Fig2e::MODEL-11b');
utils.displayModel(mdl.retract.rate.main,0.05,'GLME','Fig2f::MODEL-12b');

%% Save model outputs
tic; fprintf(1,'Saving Fig [2,S4] models...');
save(defaults.files('rate_models_pre_reach_retract_matfile'),'-struct','mdl');
fprintf(1,'complete\n'); 
fprintf(1,'\t->\t%6.2f seconds elapsed\n',toc);
utils.addHelperRepos();
sounds__.play('bell',0.8,-15);

% tic; fprintf(1,'Saving GLME models...');
% save(defaults.files('learning_rates_table_file'),...
%    'glme.unitLearning.pre.mdl','glme.unitLearning.grasp.mdl','glme.unitLearning.reach.mdl','glme.unitLearning.retract.mdl','-append');
% fprintf(1,'complete\n'); 
% fprintf(1,'%6.2f seconds elapsed\n',toc);
% utils.addHelperRepos();
% sounds__.play('bell',0.8,-15);