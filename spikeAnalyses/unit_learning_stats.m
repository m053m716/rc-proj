%UNIT_LEARNING_STATS Create Figure 2 (individual channel rates)
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
r.Properties.UserData.Excluded = ...
   (r.Alignment~="Grasp") | ...
   (r.N_Total./2.4 >= 300) | ...
   (r.N_Total./2.4 <= 2.5) | ...
   (r.Duration <= 0.100) |  ...
   (r.Duration >= 0.750);

tic;
% % Define "fixed-epoch" models % %
fprintf(1,'Fitting <strong>Pre</strong> epoch...');
glme_pre = fitglme(r,"N_Pre_Grasp~1+Area*Group*PostOpDay+(1|AnimalID)+(1+PostOpDay+Reach_Epoch_Duration|ChannelID)",...
   "Exclude",r.Properties.UserData.Excluded,...
   "FitMethod","REMPL",...
   "Distribution","Poisson",...
   "Link","log");
fprintf(1,'complete\n');
fprintf(1,'Fitting <strong>Grasp</strong> epoch...');
N = r.N_Total;
N(r.Properties.UserData.Excluded | r.Outcome=="Unsuccessful") = 1;
glme_grasp = fitglme(r,"N_Grasp~1+Area*Group*PostOpDay+(1|AnimalID)+(1+PostOpDay+Duration+N_Pre_Grasp|ChannelID)",...
   "Exclude",r.Properties.UserData.Excluded | r.Outcome=="Unsuccessful",...
   "FitMethod","REMPL",...
   "BinomialSize",N,...
   "Distribution","Binomial",...
   "Link","logit");
fprintf(1,'complete\n');
% % Define "variable-epoch" models % %
fprintf(1,'Fitting <strong>Reach</strong> epoch...');
glme_reach = fitglme(r,"N_Reach~1+Area*Group*PostOpDay+(1|AnimalID)+(1+PostOpDay+Reach_Epoch_Duration+N_Pre_Grasp|ChannelID)",...
   "Exclude",r.Properties.UserData.Excluded | r.Outcome=="Unsuccessful",...
   "FitMethod","REMPL",...
   "Distribution","Poisson",...
   "Link","log");
fprintf(1,'complete\n');
fprintf(1,'Fitting <strong>Retract</strong> epoch...');
glme_retract = fitglme(r,"N_Retract~1+Area*Group*PostOpDay+(1|AnimalID)+(1+PostOpDay+Retract_Epoch_Duration+N_Pre_Grasp|ChannelID)",...
   "Exclude",r.Properties.UserData.Excluded | r.Outcome=="Unsuccessful",...
   "FitMethod","REMPL",...
   "Distribution","Poisson",...
   "Link","log");
fprintf(1,'complete\n');
fprintf(1,'%6.2f seconds elapsed\n',toc);

% Display model outputs
fprintf(1,'\n-------------------------------------------------------------\n');
fprintf(1,'<strong>Pre-Model-Based-Exclusion Estimates</strong>\n');
fprintf(1,'\n-------------------------------------------------------------\n');
fprintf(1,'\n\n<strong>Pre-Grasp</strong>\n\n');
disp(glme_pre);
fprintf(1,'\n<strong>FIT</strong>\n');
disp(glme_pre.Rsquared);
fprintf(1,'\n\n<strong>Reach</strong>\n\n');
disp(glme_reach);
fprintf(1,'\n<strong>FIT</strong>\n');
disp(glme_reach.Rsquared);
fprintf(1,'\n\n<strong>Grasp</strong>\n\n');
disp(glme_grasp);
fprintf(1,'\n<strong>FIT</strong>\n');
disp(glme_grasp.Rsquared);
fprintf(1,'\n\n<strong>Retract</strong>\n\n');
disp(glme_retract);
fprintf(1,'\n<strong>FIT</strong>\n');
disp(glme_retract.Rsquared);
fprintf(1,'\n-------------------------------------------------------------\n');

% Get outliers based on fitted response
% Values of > 150 predicted spikes are extrema and tend to be outliers when
% looking at the original model fits. Exclude these and refit
r.Properties.UserData.Excluded = r.Properties.UserData.Excluded | ...
   (glme_pre.fitted ./ 0.6 > 150) | ...
   (glme_pre.response ./ 0.6 > 150) | ...
   (glme_retract.fitted ./ r.Retract_Epoch_Duration > 150) | ...
   (glme_retract.response ./ r.Retract_Epoch_Duration > 150) | ...
   (glme_reach.fitted ./ r.Reach_Epoch_Duration > 150) | ...
   (glme_reach.response ./ r.Reach_Epoch_Duration > 150);

% % Define "fixed-epoch" models % %
fprintf(1,'Fitting <strong>Pre</strong> epoch...');
glme_pre = fitglme(r,"N_Pre_Grasp~1+Area*Group*PostOpDay+(1|AnimalID)+(1+PostOpDay+Reach_Epoch_Duration|ChannelID)",...
   "Exclude",r.Properties.UserData.Excluded,...
   "FitMethod","REMPL",...
   "Distribution","Poisson",...
   "Link","log");
fprintf(1,'complete\n');
fprintf(1,'Fitting <strong>Grasp</strong> epoch...');
N = r.N_Total;
N(r.Properties.UserData.Excluded | r.Outcome=="Unsuccessful") = 1;
glme_grasp = fitglme(r,"N_Grasp~1+Area*Group*PostOpDay+(1|AnimalID)+(1+PostOpDay+Duration+N_Pre_Grasp|ChannelID)",...
   "Exclude",r.Properties.UserData.Excluded | r.Outcome=="Unsuccessful",...
   "FitMethod","REMPL",...
   "BinomialSize",N,...
   "Distribution","Binomial",...
   "Link","logit");
fprintf(1,'complete\n');
% % Define "variable-epoch" models % %
fprintf(1,'Fitting <strong>Reach</strong> epoch...');
glme_reach = fitglme(r,"N_Reach~1+Area*Group*PostOpDay+(1|AnimalID)+(1+PostOpDay+Reach_Epoch_Duration+N_Pre_Grasp|ChannelID)",...
   "Exclude",r.Properties.UserData.Excluded | r.Outcome=="Unsuccessful",...
   "FitMethod","REMPL",...
   "Distribution","Poisson",...
   "Link","log");
fprintf(1,'complete\n');
fprintf(1,'Fitting <strong>Retract</strong> epoch...');
glme_retract = fitglme(r,"N_Retract~1+Area*Group*PostOpDay+(1|AnimalID)+(1+PostOpDay+Retract_Epoch_Duration+N_Pre_Grasp|ChannelID)",...
   "Exclude",r.Properties.UserData.Excluded | r.Outcome=="Unsuccessful",...
   "FitMethod","REMPL",...
   "Distribution","Poisson",...
   "Link","log");
fprintf(1,'complete\n');
fprintf(1,'%6.2f seconds elapsed\n',toc);

% Display model outputs
fprintf(1,'\n-------------------------------------------------------------\n');
fprintf(1,'<strong>Final-Model Estimates</strong>\n');
fprintf(1,'\n-------------------------------------------------------------\n');
fprintf(1,'\n\n<strong>Pre-Grasp</strong>\n\n');
disp(glme_pre);
fprintf(1,'\n<strong>FIT</strong>\n');
disp(glme_pre.Rsquared);
fprintf(1,'\n\n<strong>Reach</strong>\n\n');
disp(glme_reach);
fprintf(1,'\n<strong>FIT</strong>\n');
disp(glme_reach.Rsquared);
fprintf(1,'\n\n<strong>Grasp</strong>\n\n');
disp(glme_grasp);
fprintf(1,'\n<strong>FIT</strong>\n');
disp(glme_grasp.Rsquared);
fprintf(1,'\n\n<strong>Retract</strong>\n\n');
disp(glme_retract);
fprintf(1,'\n<strong>FIT</strong>\n');
disp(glme_retract.Rsquared);
fprintf(1,'\n-------------------------------------------------------------\n');


% Create corresponding figures.
outPath = defaults.files('reach_extension_figure_dir');
if exist(outPath,'dir')==0
   mkdir(outPath);
end

% Generate figures corresponding to each epoch %
fig = analyze.behavior.epochSpikeTrends_Split(r,glme_pre,0.6);       
saveas(fig,fullfile(outPath,'Fig2 - Observed Pre-Grasp Trends.png'));
savefig(fig,fullfile(outPath,'Fig2 - Observed Pre-Grasp Trends.fig'));
delete(fig);

fig = analyze.behavior.epochSpikeFits(r,glme_pre,0.6);       
saveas(fig,fullfile(outPath,'Fig2 - Pre-Grasp Trends 95CB.png'));
savefig(fig,fullfile(outPath,'Fig2 - Pre-Grasp Trends 95CB.fig'));
delete(fig);

fig = analyze.behavior.epochSpikeTrends_Split(r,glme_reach,'Reach_Epoch_Duration');       
saveas(fig,fullfile(outPath,'Fig2 - Observed Reach Trends.png'));
savefig(fig,fullfile(outPath,'Fig2 - Observed Reach Trends.fig'));
delete(fig);

fig = analyze.behavior.epochSpikeFits(r,glme_reach,'Reach_Epoch_Duration');       
saveas(fig,fullfile(outPath,'Fig2 - Reach Trends 95CB.png'));
savefig(fig,fullfile(outPath,'Fig2 - Reach Trends 95CB.fig'));
delete(fig);

fig = analyze.behavior.epochSpikeTrends_Split(r,glme_retract,'Retract_Epoch_Duration');       
saveas(fig,fullfile(outPath,'Fig2 - Observed Retract Trends.png'));
savefig(fig,fullfile(outPath,'Fig2 - Observed Retract Trends.fig'));
delete(fig);

fig = analyze.behavior.epochSpikeFits(r,glme_retract,'Retract_Epoch_Duration');       
saveas(fig,fullfile(outPath,'Fig2 - Retract Trends 95CB.png'));
savefig(fig,fullfile(outPath,'Fig2 - Retract Trends 95CB.fig'));
delete(fig);

tic; fprintf(1,'Saving GLME models...');
save(defaults.files('learning_rates_table_file'),...
   'glme_pre','glme_grasp','glme_reach','glme_retract','-append');
fprintf(1,'complete\n'); 
fprintf(1,'%6.2f seconds elapsed\n',toc);
utils.addHelperRepos();
sounds__.play('bell',0.8,-15);