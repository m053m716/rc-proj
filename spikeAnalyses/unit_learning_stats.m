clc;
clearvars -except r
if exist('r','var')==0
   fprintf(1,'Loading raw rates table...');
   r = getfield(load(defaults.files('learning_rates_table_file'),'r'),'r');
   fprintf(1,'complete\n');
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

% % DEFINE CONSTANTS % %
PRE_GRASP = [-1350 -750]; % ms
GRASP = [-150 150]; % ms

tic;
% Get variable with total number of spikes over entire trial as "Size" %
BinomialSize = r.N_Total;
BinomialSize(r.Properties.UserData.Excluded) = 1;
% % Define "fixed-epoch" models % %
mdl_fixed = "%s~1+Area*Group+(1|AnimalID)+(1+PostOpDay+Duration|ChannelID)";
fprintf(1,'\n\n<strong>Fixed model</strong>:\n\t%s\n\n',mdl_fixed);
fprintf(1,'Fitting <strong>Pre</strong> epoch...');
glme_pre = fitglme(r,sprintf(mdl_fixed,"N_Pre_Grasp"),...
   "Exclude",r.Properties.UserData.Excluded,...
   "BinomialSize",BinomialSize,...
   "FitMethod","Laplace",...
   "Distribution","Binomial",...
   "Link","logit");
fprintf(1,'complete\n');
fprintf(1,'Fitting <strong>Grasp</strong> epoch...');
glme_grasp = fitglme(r,sprintf(mdl_fixed,"N_Grasp"),...
   "Exclude",r.Properties.UserData.Excluded,...
   "BinomialSize",BinomialSize,...
   "FitMethod","Laplace",...
   "Distribution","Binomial",...
   "Link","logit");
fprintf(1,'complete\n');
% % Define "variable-epoch" models % %
mdl_variable = "%s~1+Area*Group+(1|AnimalID)+(1+PostOpDay+%s|ChannelID)";
fprintf(1,'\n\n<strong>Variable model</strong>:\n\t%s\n\n',mdl_fixed);
fprintf(1,'Fitting <strong>Reach</strong> epoch...');
glme_reach = fitglme(r,sprintf(mdl_variable,"N_Reach","Reach_Epoch_Duration"),...
   "Exclude",r.Properties.UserData.Excluded,...
   "BinomialSize",BinomialSize,...
   "FitMethod","Laplace",...
   "Distribution","Binomial",...
   "Link","logit");
fprintf(1,'complete\n');
fprintf(1,'Fitting <strong>Retract</strong> epoch...');
glme_retract = fitglme(r,sprintf(mdl_variable,"N_Retract","Retract_Epoch_Duration"),...
   "Exclude",r.Properties.UserData.Excluded,...
   "BinomialSize",BinomialSize,...
   "FitMethod","Laplace",...
   "Distribution","Binomial",...
   "Link","logit");
fprintf(1,'complete\n');
fprintf(1,'%6.2f seconds elapsed\n',toc);
tic; fprintf(1,'Saving GLME models...');
save(defaults.files('learning_rates_table_file'),...
   'glme_pre','glme_grasp','glme_reach','glme_retract','-append');
fprintf(1,'complete\n'); 
fprintf(1,'%6.2f seconds elapsed\n',toc);

% Display model outputs
disp(glme_pre);
disp(glme_pre.Rsquared);
disp(glme_grasp);
disp(glme_grasp.Rsquared);
disp(glme_reach);
disp(glme_reach.Rsquared);
disp(glme_retract);
disp(glme_retract.Rsquared);


% Create corresponding figures.
outPath = defaults.files('reach_extension_figure_dir');
if exist(outPath,'dir')==0
   mkdir(outPath);
end

% Generate figures corresponding to each epoch %
fig = analyze.behavior.epochSpikeTrends_Split(r,glme_pre,diff(PRE_GRASP)*1e-3);       
saveas(fig,fullfile(outPath,'Fig2 - Observed Pre-Grasp Trends.png'));
savefig(fig,fullfile(outPath,'Fig2 - Observed Pre-Grasp Trends.fig'));
delete(fig);

fig = analyze.behavior.epochSpikeTrends_Split(r,glme_grasp,diff(GRASP)*1e-3);       
saveas(fig,fullfile(outPath,'Fig2 - Observed Grasp Trends.png'));
savefig(fig,fullfile(outPath,'Fig2 - Observed Grasp Trends.fig'));
delete(fig);

fig = analyze.behavior.epochSpikeTrends_Split(r,glme_reach,'Reach_Epoch_Duration');       
saveas(fig,fullfile(outPath,'Fig2 - Observed Reach Trends.png'));
savefig(fig,fullfile(outPath,'Fig2 - Observed Reach Trends.fig'));
delete(fig);

fig = analyze.behavior.epochSpikeTrends_Split(r,glme_retract,'Retract_Epoch_Duration');       
saveas(fig,fullfile(outPath,'Fig2 - Observed Retract Trends.png'));
savefig(fig,fullfile(outPath,'Fig2 - Observed Retract Trends.fig'));
delete(fig);