%TRIAL_OUTCOME_STATS Run regressions for Fig. 1a to predict outcome using GLME with logistic link

close all force;
% clearvars -except UTrials;
clc;
if exist('UTrials','var')==0
   load(defaults.files('rate_unique_trials_matfile'),'UTrials'); % "Unique trials" from T (main rate table): For analyze.behavior
end

% % % Get save/helper repo stuff setup % % %
outPath = defaults.files('reach_extension_figure_dir');
if exist(outPath,'dir')==0
   mkdir(outPath);
end
utils.addHelperRepos();

% % % % Do Pre-vs-Post comparison using "standard" scored data % % % %
T = utils.readBehaviorTable(defaults.files('behavior_data_file'));

% % % Select relevant epochs of non-excluded recordings % % %
tSub = T(~isnan(T.nTotal),:);
pre_op = tSub.Day <= 0;
tPreOp = tSub(pre_op,:);
tPostOp = tSub(~pre_op,:);

% % % Generate graphics for supplementary figure S1a : Standard Scoring (All Days) % % %
fig = analyze.behavior.per_animal_trends(tSub,...
   'Title','Performance by Day (standard scoring)',...
   'LegendLocation','westoutside',...
   'LegendStyle','animals');
saveas(fig,fullfile(outPath,'FigS1 - Post-Op Success Rate - Standard Scoring - All.png'));
savefig(fig,fullfile(outPath,'FigS1 - Post-Op Success Rate - Standard Scoring - All.fig'));
delete(fig);

% % % Make Fig. 1a Graphics (Pre-Op Bar Plots) % % %
fig = analyze.behavior.bar_animal_counts(tPreOp,'nSuccess','nTotal',...
   'Title','Baseline Success Rate',...
   'YLim',[0 100],...
   'YLabel','% Successful');
saveas(fig,fullfile(outPath,'Fig1 - Pre-Op Success Rate - Standard Scoring.png'));
savefig(fig,fullfile(outPath,'Fig1 - Pre-Op Success Rate - Standard Scoring.fig'));
delete(fig);

% % % Make Fig. 1b Graphics (Post-Op Success Line + Confidence Trends)
[fig,mdl] = analyze.behavior.per_animal_trends(tSub,...
   'Title',"Performance by Day (standard scoring)",...
   'XLim',[0 31],...
   'LegendStyle','animals',...
   'LegendLocation','eastoutside');
saveas(fig,fullfile(outPath,'Fig1 - Post-Op Success Rate - Standard Scoring.png'));
savefig(fig,fullfile(outPath,'Fig1 - Post-Op Success Rate - Standard Scoring.fig'));
delete(fig);

% % Show descriptive statistics (mean, 95% CB) by grouping % %
[Group,TID] = findgroups(tSub(:,{'Group','PrePost'}));
TID.Mean = splitapply(@nanmean,tSub.pct,Group); % Return mean percent correct
TID.CB95 = splitapply(@analyze.stat.getCB95,tSub.pct,Group); % Return upper and lower 95%-confidence bounds
TID.CB95 = cell2mat(TID.CB95);
disp(TID);

%%
% % % Estimate statistics for behavioral outcome prior to surgery % % %
glme.trialOutcomes = struct;
% % % "MODEL-1" % % %
fprintf(1,'----------------------------------------------------------\n');
fprintf(1,'<strong>MODEL-1</strong> Fitting GLME for <strong>nSuccess</strong> (standard scoring)...');
glme.trialOutcomes.pre.mdl = fitglme(tPreOp,...
   "nSuccess~1+GroupID+(1|AnimalID)",...
   "FitMethod","REMPL",...
   "DummyVarCoding",'effects',...
   "Distribution","binomial",...
   "Link","logit",...
   "BinomialSize",tPreOp.nTotal);
glme.trialOutcomes.pre.id = 1;
fprintf(1,'complete\n');
fprintf(1,'----------------------------------------------------------\n');
disp(glme.trialOutcomes.pre.mdl);
fprintf(1,'----------------------------------------------------------\n');
fprintf(1,'<strong>Fit (MODEL-%d):</strong>\n',glme.trialOutcomes.pre.id);
disp(glme.trialOutcomes.pre.mdl.Rsquared);
fprintf(1,'----------------------------------------------------------\n');

% % % Estimate statistics for behavioral outcomes: Pre-vs-Post, by Group % % %
% % % "MODEL-2" % % %
fprintf(1,'----------------------------------------------------------\n');
fprintf(1,'\t<strong>MODEL-2</strong> Fitting GLME for <strong>Pre-vs-Post Implant Success</strong>...');
glme.trialOutcomes.prepost.mdl = fitglme(tSub,"nSuccess~1+PrePost*GroupID+(1|AnimalID)",...
   "BinomialSize",tSub.nTotal,...
   "Link","logit",...
   "DummyVarCoding",'effects',...
   "Distribution","Binomial",...
   "FitMethod","REMPL");
glme.trialOutcomes.prepost.id = 2;
fprintf(1,'complete\n');
fprintf(1,'----------------------------------------------------------\n');
disp(glme.trialOutcomes.prepost.mdl);
fprintf(1,'----------------------------------------------------------\n');
fprintf(1,'<strong>Fit (MODEL-%d):</strong>\n',glme.trialOutcomes.prepost.id);
disp(glme.trialOutcomes.prepost.mdl.Rsquared);
fprintf(1,'----------------------------------------------------------\n');

% % % Estimate statistics for behavioral outcomes using standard scoring % % %
% % % "MODEL-3" % % %
fprintf(1,'----------------------------------------------------------\n');
fprintf(1,'<strong>MODEL-3</strong> Fitting GLME for <strong>nSuccess</strong> (standard scoring)...');
glme.trialOutcomes.post.mdl = fitglme(tPostOp,...
   "nSuccess~1+GroupID*Day+(1+Day+Day_Cubed|AnimalID)",...
   "FitMethod","REMPL",...
   "DummyVarCoding",'effects',...
   "Distribution","binomial",...
   "Link","logit",...
   "BinomialSize",tPostOp.nTotal);
glme.trialOutcomes.post.id = 3;
fprintf(1,'complete\n');
fprintf(1,'----------------------------------------------------------\n');
disp(glme.trialOutcomes.post.mdl);
fprintf(1,'----------------------------------------------------------\n');
fprintf(1,'<strong>Fit (MODEL-%d):</strong>\n',glme.trialOutcomes.post.id);
disp(glme.trialOutcomes.post.mdl.Rsquared);
fprintf(1,'----------------------------------------------------------\n');

%%

% % % Make Fig. 1b graphics % % %
%  -> 'Grasp' aligned only
%  -> Min trial duration: 100-ms
%  -> Max trial duration: 750-ms

% u ~ temporary (for groupings)
% u = UTrials;
% UTrials already has unique trials so allow all Alignments
u = analyze.get_subset(UTrials,'align',{'Complete','Support','Grasp','Reach'});
% % % Get save/helper repo stuff setup % % %
outPath = defaults.files('reach_extension_figure_dir');
if exist(outPath,'dir')==0
   mkdir(outPath);
end
utils.addHelperRepos();
% u.Outcome((u.Duration <= 0.100) | (u.Duration >= 0.750),:) = "Unsuccessful";
[Gtr,U] = findgroups(u(:,{'GroupID','AnimalID','PostOpDay'}));
U.Duration = splitapply(@nanmean,u.Duration,Gtr);
U.nTotal = splitapply(@numel,u.Outcome,Gtr);
U.nSuccess = splitapply(@(x)sum(x=="Successful"),u.Outcome,Gtr);
U.Percent_Successful = (U.nSuccess ./ U.nTotal) .* 100; 
U.Day = U.PostOpDay;
U.Day_Cubed = U.PostOpDay.^3;

% % % Generate graphics for supplementary figure S1b : Neural Scoring % % %
fig = analyze.behavior.per_animal_trends(U,...
   'Title','Performance by Day (neural exclusions)',...
   'LegendLocation','eastoutside',...
   'LegendStyle','animals');
utils.expAI(fig,'figures/R01-Renewal_FigS1b - Post-Op Success Rate - Neural Scoring.ai');
utils.expAI(fig,'figures/R01-Renewal_FigS1b - Post-Op Success Rate - Neural Scoring.eps');
saveas(fig,'figures/R01-Renewal_FigS1b - Post-Op Success Rate - Neural Scoring.png');
% saveas(fig,fullfile(outPath,'FigS1 - Post-Op Success Rate - Neural Scoring.png'));
savefig(fig,fullfile(outPath,'FigS1 - Post-Op Success Rate - Neural Scoring.fig'));
delete(fig);

%%
% % Make (formal) statistical comparison between results by method % %
methodGroups = categorical(1:2,1:2,{'Standard','Neural'});
tStandard = tPostOp(:,{'GroupID','AnimalID','Day','Day_Cubed','nSuccess','nTotal','Percent_Successful'});
tStandard.Method = repmat(methodGroups(1),size(tStandard,1),1);
tStandard.Properties.RowNames = strcat("Standard::",...
   string(tStandard.AnimalID),'::',...
   string(strtrim(num2str(abs(tStandard.Day),'%02d'))));
tNeural = U(:,{'GroupID','AnimalID','Day','Day_Cubed','nSuccess','nTotal','Percent_Successful'});
tNeural.Method = repmat(methodGroups(2),size(tNeural,1),1);
tNeural.Properties.RowNames = strcat("Neural::",...
   string(tNeural.AnimalID),'::',...
   string(strtrim(num2str(tNeural.Day,'%02d'))));
tMethod = [tStandard;tNeural];

%%
% % % % Estimate statistics for behavioral outcomes using neural scoring % % %
% % % "MODEL-4" % % %
fprintf(1,'----------------------------------------------------------\n');
fprintf(1,'<strong>MODEL-4</strong> Fitting GLME for <strong>nSuccess (comparison of Standard vs Neural)</strong>...');
glme.trialOutcomes.methods.mdl = fitglme(tMethod,...
   "nSuccess~1+Method*GroupID*Day_Cubed+(1+Day+Day_Cubed|AnimalID)",...
   "FitMethod","REMPL",...
   "DummyVarCoding",'effects',...
   "Distribution","binomial",...
   "Link","logit",...
   "BinomialSize",tMethod.nTotal);
glme.trialOutcomes.methods.id = 4;
fprintf(1,'complete\n');
fprintf(1,'----------------------------------------------------------\n');
disp(glme.trialOutcomes.methods.mdl);
fprintf(1,'----------------------------------------------------------\n');
fprintf(1,'\t<strong>Fit (MODEL-%d):</strong>\n',glme.trialOutcomes.methods.id);
disp(glme.trialOutcomes.methods.mdl.Rsquared);
fprintf(1,'----------------------------------------------------------\n');

%% Display models
clc;
utils.displayModel(glme.trialOutcomes.pre,0.05,'Fig.1a');
utils.displayModel(glme.trialOutcomes.prepost,0.05,'Fig.S1a');
utils.displayModel(glme.trialOutcomes.post,0.05,'Fig.1b');
utils.displayModel(glme.trialOutcomes.methods,0.05,'Fig.S1b');

%%
% Save models %
tic; fprintf(1,'Saving Fig [1,S1] models...');
tmp = glme.trialOutcomes;
save(defaults.files('outcome_models_matfile'),'-struct','tmp');
clear tmp;
fprintf(1,'complete\n'); 
fprintf(1,'\t->\t%6.2f seconds elapsed\n',toc);
utils.addHelperRepos();
sounds__.play('bell',0.8,-15);