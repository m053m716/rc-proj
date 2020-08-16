%POPULATION_FIRSTORDER_MLS_REGRESSION_STATS Stats for dynamics (Fig. 4)

clc; 
clearvars -except E D; % clear base workspace except for data struct/tables
if exist('D','var') == 0
   D = utils.loadTables('multi'); % Load "multi-jPCA" table.
   E = analyze.dynamics.exportTable(D); % Export statistics table.
end

% First: are there are differences in included channel statistics? %
mdl_cfa = "N_CFA~R2_Best+(1+Explained_Best+PostOpDay+Duration+Alignment|AnimalID)";

modelTic = tic;
fprintf(1,'Estimating Binomial GLME model for # of CFA channels...');
glme_cfa = fitglme(E,mdl_cfa,...
   "FitMethod","REMPL",...
   "Distribution","Binomial",...
   "BinomialSize",E.N_Channels,...
   "Link","logit");
modelToc = toc(modelTic);
model_minutes = floor(modelToc/60);
model_seconds = modelToc - (model_minutes*60);
fprintf(1,'complete (%5.2f minutes, %4.1f sec)\n',...
   model_minutes,model_seconds);
fprintf(1,'\n-------------------------------------------\n');
fprintf(1,'\t<strong>Model:%s</strong>\n',mdl_cfa);
fprintf(1,'\n-------------------------------------------\n');
disp(glme_cfa);
fprintf(1,'\n-------------------------------------------\n');
fprintf(1,'\t<strong>Fit</strong>\n');
disp(glme_cfa.Rsquared);
fprintf(1,'-------------------------------------------\n');

% Second: are there differences based on proportion of included distal forelimb channels? %
mdl_df = "N_Distal_Forelimb~R2_Best+(1+Explained_Best+PostOpDay+Duration+Alignment|AnimalID)";

modelTic = tic;
fprintf(1,'Estimating Binomial GLME model for # of CFA channels...');
glme_df = fitglme(E,mdl_df,...
   "FitMethod","REMPL",...
   "Distribution","Binomial",...
   "BinomialSize",E.N_Forelimb,...
   "Link","logit");
modelToc = toc(modelTic);
model_minutes = floor(modelToc/60);
model_seconds = modelToc - (model_minutes*60);
fprintf(1,'complete (%5.2f minutes, %4.1f sec)\n',...
   model_minutes,model_seconds);
fprintf(1,'\n-------------------------------------------\n');
fprintf(1,'\t<strong>Model:%s</strong>\n',mdl_df);
fprintf(1,'\n-------------------------------------------\n');
disp(glme_df);
fprintf(1,'\n-------------------------------------------\n');
fprintf(1,'\t<strong>Fit</strong>\n');
disp(glme_df.Rsquared);
fprintf(1,'-------------------------------------------\n');

% Last: is there a Group*PostOpDay interaction for dynamics signature? %

% "Rotatory Dynamics" model (supplementary):
% "R2_Skew~GroupID*PostOpDay+(1+R2_Best*Explained_Skew*AverageDuration|GroupID:AnimalID)"

mdl_dynamics = "R2_Best~GroupID*Alignment*PostOpDay+(1+Duration+PostOpDay+Explained_Best+N_Trials+Pct_DF+Pct_RFA|AnimalID)";
% Inverse Hyperbolic Tangent link (for optimizing probabilities)
S = struct(...
   'Link',@(mu)2.*atanh(2.*mu - 1), ...
   'Derivative',@(mu)1./(mu - mu.^2), ...
   'SecondDerivative',@(mu)(2.*mu - 1)./(((mu - 1).^2).*(mu.^2)), ...
   'Inverse',@(y)1./(1+exp(-y))...
   );
modelTic = tic;
fprintf(1,'Estimating GLME model for Linearized Dynamics Fit...');
glme_best = fitglme(E,mdl_dynamics,...
   "FitMethod","REMPL",...
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
disp(glme_best);
fprintf(1,'\n-------------------------------------------\n');
fprintf(1,'\t<strong>Fit</strong>\n');
disp(glme_best.Rsquared);
fprintf(1,'-------------------------------------------\n');
fprintf(1,'\t<strong>Custom Link:</strong>\n');
disp(S);
fprintf(1,'-------------------------------------------\n');

fig = figure('Name','Partial Dependence: Group and Day',...
   'Color','w','Units','Normalized','Position',[0.35 0.52 0.35 0.39]);
plotPartialDependence(glme_best,{'PostOpDay','GroupID'});
c = colorbar('FontName','Arial',...
   'Ticks',[0.0 0.25 0.5 0.75 1.0],'TickDirection','out');
set(c.Label,'String','R^2_{MLS}','FontName','Arial','Color',[0 0 0]);
set(gca,'CLim',[0 1]);
set(gca,'ZLim',[0 1]);
zlabel('R^2_{MLS}','FontName','Arial','Color','k','FontWeight','bold');
xlabel('Post-Op Day','FontName','Arial','Color','k');
ylabel('');
title('Linearized Dynamics Fit','FontName','Arial','Color','k');
set(get(gca,'Children'),...
   'FaceAlpha',0.7,'EdgeAlpha',0.25,'LineWidth',1,'EdgeColor','k');

% Create corresponding figures.
outPath = defaults.files('reach_extension_figure_dir');
if exist(outPath,'dir')==0
   mkdir(outPath);
end

saveas(fig,fullfile(outPath,'Fig4 - Group by Day PDP.png'));
savefig(fig,fullfile(outPath,'Fig4 - Group by Day PDP.fig'));
delete(fig);

fig = analyze.dynamics.plotSliceSampleTrends(glme_best);

saveas(fig,fullfile(outPath,'Fig4 - Smoothed R2 Dynamics Fit by Day.png'));
savefig(fig,fullfile(outPath,'Fig4 - Smoothed R2 Dynamics Fit by Day.fig'));
delete(fig);