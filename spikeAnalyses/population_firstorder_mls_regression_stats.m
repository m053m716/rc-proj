%POPULATION_FIRSTORDER_MLS_REGRESSION_STATS Stats for dynamics (Fig. 4, Fig. S8)

%% Load table
clc; 
clearvars -except E D; % clear base workspace except for data struct/tables
if exist('D','var') == 0
   D = utils.loadTables('multi'); % Load "multi-jPCA" table.
   E = analyze.dynamics.exportTable(D); % Export statistics table.
end

% % % Get save/helper repo stuff setup % % %
outPath = defaults.files('reach_extension_figure_dir');
if exist(outPath,'dir')==0
   mkdir(outPath);
end
utils.addHelperRepos();

%% Fig. S7a - Distribution of Performance Scores for Population Stats
fig = analyze.dynamics.inputDistribution(E,'Performance_hat_mu');

saveas(fig,fullfile(outPath,'FigS7a - Transformed Population Dynamics Performance Covariate.png'));
savefig(fig,fullfile(outPath,'FigS7a - Transformed Population Dynamics Performance Covariate.fig'));
delete(fig);

%% Fig. S7b - Check distribution of input PDF: Top-2 Planes (eig) for Grasp
% Only use top two planes, Grasp-aligned
fig = analyze.behavior.per_animal_mean_trends(...
   E(ismember(E.PlaneIndex,E.PlaneIndex(1:2)) & E.Alignment=="Grasp",:),...
   'R2_Best',...
   'DoExclusions',false,...
   'YLabel','R^2_{MLS}',...
   'YLim',[0 1],...
   'LegendLocation','eastoutside',...
   'Title',['Top-2 Grasp Planes by Eigenvalue' newline '(By Animal)']);
saveas(fig,fullfile(outPath,'FigS7b - R2_best - Top-2 Planes by Eig - Grasp - By Animal.png'));
savefig(fig,fullfile(outPath,'FigS7b - R2_best - Top-2 Planes by Eig - Grasp - By Animal.fig'));
delete(fig);

%% Fig. S7c - Check distribution of input PDF: Top-2 Planes (eig) for Reach
% Only use top two planes, Reach-aligned
fig = analyze.behavior.per_animal_mean_trends(...
   E(ismember(E.PlaneIndex,E.PlaneIndex(1:2)) & E.Alignment=="Reach",:),...
   'R2_Best',...
   'DoExclusions',false,...
   'YLabel','R^2_{MLS}',...
   'YLim',[0 1],...
   'LegendLocation','eastoutside',...
   'Title',['Top-2 Reach Planes by Eigenvalue' newline '(By Animal)']);
saveas(fig,fullfile(outPath,'FigS7c - R2_best - Top-2 Planes by Eig - Reach - By Animal.png'));
savefig(fig,fullfile(outPath,'FigS7c - R2_best - Top-2 Planes by Eig - Reach - By Animal.fig'));
delete(fig);

%% Fig. S7d - Check distribution of input PDF: EXPLAINED in Top-2 Planes (eig) for Grasp
% Only use top two planes, Grasp-aligned
fig = analyze.behavior.per_animal_mean_trends(...
   E(ismember(E.PlaneIndex,E.PlaneIndex(1:2)) & E.Alignment=="Grasp",:),...
   'Explained_Best',...
   'DoExclusions',false,...
   'YLabel','% Explained',...
   'YLim',[0 100],...
   'Scale',100,...
   'LegendLocation','eastoutside',...
   'Title',['Top-2 Grasp Planes by Eigenvalue' newline '(By Animal)']);
saveas(fig,fullfile(outPath,'FigS7d - Explained_Best - Top-2 Planes by Eig - Grasp - By Animal.png'));
savefig(fig,fullfile(outPath,'FigS7d - Explained_Best - Top-2 Planes by Eig - Grasp - By Animal.fig'));
delete(fig);

%% Fig. S7e - Check distribution of input PDF: EXPLAINED in Top-2 Planes (eig) for Reach
% Only use top two planes, Reach-aligned
fig = analyze.behavior.per_animal_mean_trends(...
   E(ismember(E.PlaneIndex,E.PlaneIndex(1:2)) & E.Alignment=="Reach",:),...
   'Explained_Best',...
   'DoExclusions',false,...
   'YLabel','% Explained',...
   'YLim',[0 100],...
   'Scale',100,...
   'LegendLocation','eastoutside',...
   'Title',['Top-2 Reach Planes by Eigenvalue' newline '(By Animal)']);
saveas(fig,fullfile(outPath,'FigS7e - Explained_Best - Top-2 Planes by Eig - Reach - By Animal.png'));
savefig(fig,fullfile(outPath,'FigS7e - Explained_Best - Top-2 Planes by Eig - Reach - By Animal.fig'));
delete(fig);

%% Fig. S7f - Joint Distributions of all Plane %-Explained combos
fig = analyze.dynamics.makeJointDistViz(E);
saveas(fig,fullfile(outPath,'FigS7f - Joint Distribution Plane-Percent-Explained.png'));
savefig(fig,fullfile(outPath,'FigS7f - Joint Distribution Plane-Percent-Explained.fig'));
delete(fig);

%% Export (reduced) table that does whole-model fit without considering "planes"
E2 = analyze.dynamics.exportSubTable(D);

%% Fig. 4b - Check that results are similar
fig = analyze.dynamics.makeJointDistViz(E2,'scatter');
set(fig,'Position',[0.59 0.33 0.15 0.4]);
set(fig.Children(1),'Position',[0.36 0.49 0.29 0.075]);
saveas(fig,fullfile(outPath,'Fig4b - Joint Distribution Plane-Percent-Explained.png'));
savefig(fig,fullfile(outPath,'Fig4b - Joint Distribution Plane-Percent-Explained.fig'));
delete(fig);

%% Fig. 4a - Check distribution on R^2 MLS (adjusted) for ALL fit
% Use REACH and GRASP together
fig = analyze.behavior.per_animal_mean_trends(...
   E2,'R2_Best',...
   'DoExclusions',false,...
   'YLabel','R^2_{MLS}',...
   'YLim',[0 1],...
   'Scale',1,...
   'LegendLocation','eastoutside',...
   'LegendStyle','Animals',...
   'Title','R^2_{MLS} (By Animal)');
saveas(fig,fullfile(outPath,'Fig4a - R2_Best - All - By Animal.png'));
savefig(fig,fullfile(outPath,'Fig4a - R2_Best - All - By Animal.fig'));
delete(fig);

%% Fig. 4c - Check distribution of Explained values for ALL fit
fig = analyze.behavior.per_animal_mean_trends(...
   E2,'Explained',...
   'DoExclusions',false,...
   'YLabel','% Explained (PCA)',...
   'YLim',[75 100],...
   'Scale',1,...
   'LegendLocation','eastoutside',...
   'LegendStyle','Animals',...
   'Title','Total Data Explained by PCA (By Animal)');
saveas(fig,fullfile(outPath,'Fig4c - Explained - All - By Animal.png'));
savefig(fig,fullfile(outPath,'Fig4c - Explained - All - By Animal.fig'));
delete(fig);

%% Fig. S8d - Check R2_Skew also
% Use REACH and GRASP together
fig = analyze.behavior.per_animal_mean_trends(...
   E2,'R2_Skew',...
   'DoExclusions',false,...
   'YLabel','R^2_{skew}',...
   'YLim',[0 1],...
   'Scale',1,...
   'LegendLocation','eastoutside',...
   'Title','R^2_{skew} (By Animal)');
saveas(fig,fullfile(outPath,'FigS8d - R2_Skew - All - By Animal.png'));
savefig(fig,fullfile(outPath,'FigS8d - R2_Skew - All - By Animal.fig'));
delete(fig);

%% Conduct population-dynamics model level statistics
% First: are there are differences in included channel statistics? %
mdl_cfa = "N_CFA~R2_Best*ExplainedLogit+(1+PostOpDay+Duration|AnimalID)";
E2.ExplainedLogit = -log(100./E2.Explained - 1);
modelTic = tic;
fprintf(1,'Estimating Binomial GLME model for # of CFA channels...');
glme.populationDynamics.ncfa_channels.id = 14;
glme.populationDynamics.ncfa_channels.mdl = fitglme(E2,mdl_cfa,...
   "FitMethod","REMPL",...
   "Distribution","Binomial",...
   "BinomialSize",E2.N_Channels,...
   "Link","logit");
modelToc = toc(modelTic);
model_minutes = floor(modelToc/60);
model_seconds = modelToc - (model_minutes*60);
fprintf(1,'complete (%5.2f minutes, %4.1f sec)\n',...
   model_minutes,model_seconds);
fprintf(1,'\n-------------------------------------------\n');
fprintf(1,'\t<strong>Model:%s</strong>\n',mdl_cfa);
fprintf(1,'\n-------------------------------------------\n');
disp(glme.populationDynamics.ncfa_channels.mdl);
fprintf(1,'\n-------------------------------------------\n');
fprintf(1,'\t<strong>Fit</strong>\n');
disp(glme.populationDynamics.ncfa_channels.mdl.Rsquared);
fprintf(1,'-------------------------------------------\n');

% Second: are there differences based on proportion of included distal forelimb channels? %
mdl_df = "N_Distal_Forelimb~R2_Best*ExplainedLogit+(1+PostOpDay+Duration|AnimalID)";

modelTic = tic;
fprintf(1,'Estimating Binomial GLME model for # of CFA channels...');
glme.populationDynamics.ndf_channels.id = 15;
glme.populationDynamics.ndf_channels.mdl = fitglme(E2,mdl_df,...
   "FitMethod","REMPL",...
   "Distribution","Binomial",...
   "DummyVarCoding",'effects',...
   "BinomialSize",E2.N_Forelimb,...
   "Link","logit");
modelToc = toc(modelTic);
model_minutes = floor(modelToc/60);
model_seconds = modelToc - (model_minutes*60);
fprintf(1,'complete (%5.2f minutes, %4.1f sec)\n',...
   model_minutes,model_seconds);
fprintf(1,'\n-------------------------------------------\n');
fprintf(1,'\t<strong>Model:%s</strong>\n',mdl_df);
fprintf(1,'\n-------------------------------------------\n');
disp(glme.populationDynamics.ndf_channels.mdl);
fprintf(1,'\n-------------------------------------------\n');
fprintf(1,'\t<strong>Fit</strong>\n');
disp(glme.populationDynamics.ndf_channels.mdl.Rsquared);
fprintf(1,'-------------------------------------------\n');

% Last: is there a Group*PostOpDay interaction for dynamics signature? %

mdl_dynamics = "R2_Best~Performance*ExplainedLogit*GroupID+(1+Duration+PostOpDay|AnimalID)";
% Inverse Hyperbolic Tangent link (for optimizing probabilities)
S = struct(...
   'Link',@(mu)2.*atanh(2.*mu - 1), ...
   'Derivative',@(mu)1./(mu - mu.^2), ...
   'SecondDerivative',@(mu)(2.*mu - 1)./(((mu - 1).^2).*(mu.^2)), ...
   'Inverse',@(y)1./(1+exp(-y))...
   );
modelTic = tic;
fprintf(1,'Estimating GLME model for Linearized Dynamics Fit...');
glme.populationDynamics.r2_best.id = 16;
glme.populationDynamics.r2_best.mdl = fitglme(E2,mdl_dynamics,...
   "FitMethod","REMPL",...
   "DummyVarCoding",'effects',...
   "Distribution","Normal",...
   "Link",S);
modelToc = toc(modelTic);
model_minutes = floor(modelToc/60);
model_seconds = modelToc - (model_minutes*60);
fprintf(1,'complete (%5.2f minutes, %4.1f sec)\n',...
   model_minutes,model_seconds);
fprintf(1,'\n-------------------------------------------\n');
fprintf(1,'\t<strong>Model:%s</strong>\n',mdl_dynamics);
fprintf(1,'\n-------------------------------------------\n');
disp(glme.populationDynamics.r2_best.mdl);
fprintf(1,'\n-------------------------------------------\n');
fprintf(1,'\t<strong>Fit</strong>\n');
disp(glme.populationDynamics.r2_best.mdl.Rsquared);
fprintf(1,'-------------------------------------------\n');
fprintf(1,'\t<strong>Custom Link:</strong>\n');
disp(S);
fprintf(1,'-------------------------------------------\n');

mdl_dynamics_skew = "R2_Skew~Performance*ExplainedLogit*GroupID+(1+Duration+PostOpDay|AnimalID)";
modelTic = tic;
fprintf(1,'Estimating GLME model for Linearized Dynamics Fit...');
glme.populationDynamics.r2_skew.id = 17;
glme.populationDynamics.r2_skew.mdl = fitglme(E2,mdl_dynamics_skew,...
   "FitMethod","REMPL",...
   "DummyVarCoding",'effects',...
   "Distribution","Normal",...
   "Link",S);
modelToc = toc(modelTic);
model_minutes = floor(modelToc/60);
model_seconds = modelToc - (model_minutes*60);
fprintf(1,'complete (%5.2f minutes, %4.1f sec)\n',...
   model_minutes,model_seconds);
fprintf(1,'\n-------------------------------------------\n');
fprintf(1,'\t<strong>Model:%s</strong>\n',mdl_dynamics_skew);
fprintf(1,'\n-------------------------------------------\n');
disp(glme.populationDynamics.r2_skew.mdl);
fprintf(1,'\n-------------------------------------------\n');
fprintf(1,'\t<strong>Fit</strong>\n');
disp(glme.populationDynamics.r2_skew.mdl.Rsquared);
fprintf(1,'-------------------------------------------\n');
fprintf(1,'\t<strong>Custom Link:</strong>\n');
disp(S);
fprintf(1,'-------------------------------------------\n');

%% Fit models relating Performance
clc;
mdl_dynamics_best_perf = "Performance~R2_Best*R2_Skew*ExplainedLogit*GroupID+(1+PostOpDay+Duration|AnimalID)";
modelTic = tic;
fprintf(1,'Estimating GLME model for Linearized Dynamics Fit...');
glme.populationDynamics.performance_best.id = 18;
glme.populationDynamics.performance_best.mdl = fitglme(E2,mdl_dynamics_best_perf,...
   "FitMethod",'REMPL',...
   "DummyVarCoding",'effects',...
   "Distribution",'Normal',...
   "Link",'identity');
modelToc = toc(modelTic);
model_minutes = floor(modelToc/60);
model_seconds = modelToc - (model_minutes*60);
fprintf(1,'complete (%5.2f minutes, %4.1f sec)\n',...
   model_minutes,model_seconds);
utils.displayModel(glme.populationDynamics.performance_best);

%% Make partial dependence plot for model with respect to Explained,R2,Performance
fig = figure('Name','PDP: R2_Best + R2_Skew + Performance',...
   'Units','Normalized','Color','w','Position',[1.16 0.10 0.21 0.52],...
   'NumberTitle','off');
ax = axes(fig,'XColor','k','YColor','k','ZColor','k','LineWidth',1.5,...
   'XGrid','on','YGrid','on','ZGrid','on',...
   'NextPlot','add','FontName','Arial','View',[-15.9 47.5]);
plotPartialDependence(glme.populationDynamics.performance_best.mdl,...
   {'R2_Best','R2_Skew'},'parentAxisHandle',ax);
set(get(ax,'XLabel'),'FontName','Arial','Color','k','String','\bfR^2_{MLS}');
set(get(ax,'YLabel'),'FontName','Arial','Color','k','String','\bfR^2_{Skew}');
set(get(ax,'ZLabel'),'FontName','Arial','Color','k','String','\bfPerformance');
set(ax,'ZLim',[-1 1],'CLim',[-1 1]);
colormap('jet');
set(get(ax,'Children'),'EdgeColor','none','FaceAlpha',0.5);
colorbar(ax);
set(fig.Children(1).Label,'FontName','Arial','Color',[0 0 0],'String','Performance');

saveas(fig,fullfile(outPath,'Fig4d - PDP - R2_Best-Skew_Performance.png'));
savefig(fig,fullfile(outPath,'Fig4d - PDP - R2_Best-Skew_Performance.fig'));
delete(fig);

fig = figure('Name','PDP: R2_Skew + Explained + Performance',...
   'Units','Normalized','Color','w','Position',[1.16 0.10 0.21 0.52],...
   'NumberTitle','off');
ax = axes(fig,'XColor','k','YColor','k','ZColor','k','LineWidth',1.5,...
   'XGrid','on','YGrid','on','ZGrid','on',...
   'NextPlot','add','FontName','Arial','View',[-15.9 47.5]);
plotPartialDependence(glme.populationDynamics.performance_best.mdl,...
   {'R2_Skew','ExplainedLogit'},'parentAxisHandle',ax);

set(get(ax,'XLabel'),'FontName','Arial','Color','k','String','\bfR^2_{Skew}');
set(get(ax,'YLabel'),'FontName','Arial','Color','k','String','\itlogit\rm(\bfExplained\rm)');
set(get(ax,'ZLabel'),'FontName','Arial','Color','k','String','\bfPerformance');
set(ax,'ZLim',[-1 1],'CLim',[-1 1]);
colormap('jet');
set(get(ax,'Children'),'EdgeColor','none','FaceAlpha',0.5);
colorbar(ax);
set(fig.Children(1).Label,'FontName','Arial','Color',[0 0 0],'String','Performance');

saveas(fig,fullfile(outPath,'Fig4e - PDP - R2_Skew-Explained_Performance.png'));
savefig(fig,fullfile(outPath,'Fig4e - PDP - R2_Skew-Explained_Performance.fig'));
delete(fig);
%% Save models
clc;
utils.displayModel(glme.populationDynamics,0.05); % Display all models
tic; fprintf(1,'Saving Fig [4,S7] models...');
tmp = glme.populationDynamics;
save(defaults.files('pop_models_pre_reach_retract_matfile'),'-struct','tmp');
clear tmp;
fprintf(1,'complete\n'); 
fprintf(1,'\t->\t%6.2f seconds elapsed\n',toc);
utils.addHelperRepos();
sounds__.play('bell',0.8,-15);

%% Make figures

% fig = analyze.dynamics.plotSliceSampleTrends(glme.populationDynamics.r2_best.mdl);
% saveas(fig,fullfile(outPath,'Fig4a - Smoothed R2 Dynamics Fit by Day.png'));
% savefig(fig,fullfile(outPath,'Fig4a - Smoothed R2 Dynamics Fit by Day.fig'));
% delete(fig);

fig = analyze.dynamics.scatterR2ByDayAndExplained(E);
saveas(fig,fullfile(outPath,'FigS8b - R2 Dynamics Fit by Day and Explained - Planes.png'));
savefig(fig,fullfile(outPath,'FigS8b - R2 Dynamics Fit by Day and Explained - Planes.fig'));
delete(fig);

fig = analyze.dynamics.scatterR2ByDayAndExplained(E2);
saveas(fig,fullfile(outPath,'FigS8c - R2 Dynamics Fit by Day and Explained.png'));
savefig(fig,fullfile(outPath,'FigS8c - R2 Dynamics Fit by Day and Explained.fig'));
delete(fig);

%% 
fig = analyze.dynamics.scatterR2andPerf(E2);
saveas(fig,fullfile(outPath,'FigS9a - R2 Dynamics Fit and Performance.png'));
savefig(fig,fullfile(outPath,'FigS9a - R2 Dynamics Fit and Performance.fig'));
delete(fig);

fig = analyze.dynamics.scatterR2andPerf(E2,3);
saveas(fig,fullfile(outPath,'FigS9b - R2 Dynamics Fit and Performance and PostOpDay.png'));
savefig(fig,fullfile(outPath,'FigS9b - R2 Dynamics Fit and Performance and PostOpDay.fig'));
delete(fig);

