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
T = readtable(defaults.files('behavior_data_file'));
% No M1-C rats %
T(strcmpi(T.Group,'M1-C'),:) = [];
T.GroupID = categorical(T.Group,{'ET-1','SHAM'},{'Ischemia','Intact'});
T.AnimalID = categorical(T.Name);

% Add variables to table, parsed from other variables %
T.PrePost = categorical(double(T.Day > 0),[0 1],{'Pre','Post'});
T.Properties.RowNames = strcat(string(T.AnimalID),'::',...
   string(T.PrePost),'::',...
   string(strtrim(num2str(abs(T.Day),'%02d'))));
T.nTotal = round(T.nSuccess ./ T.pct);
T.Day_Cubed = T.Day.^3;
T.Percent_Successful = T.pct .* 100;

% % % Select relevant epochs of non-excluded recordings % % %
tSub = T(~isnan(T.nTotal),:);
pre_op = tSub.Day <= 0;
tPreOp = tSub(pre_op,:);
tPostOp = tSub(~pre_op,:);

% % % Generate graphics for supplementary figure S1a : Standard Scoring (All Days) % % %
fig = analyze.behavior.per_animal_trends(tSub,...
   'Title','Performance by Day (standard scoring)',...
   'LegendLocation','southwest');
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
   'XLim',[0 31]);
saveas(fig,fullfile(outPath,'Fig1 - Post-Op Success Rate - Standard Scoring.png'));
savefig(fig,fullfile(outPath,'Fig1 - Post-Op Success Rate - Standard Scoring.fig'));
delete(fig);

% % Show descriptive statistics (mean, 95% CB) by grouping % %
[Group,TID] = findgroups(tSub(:,{'Group','PrePost'}));
TID.Mean = splitapply(@nanmean,tSub.pct,Group); % Return mean percent correct
TID.CB95 = splitapply(@analyze.stat.getCB95,tSub.pct,Group); % Return upper and lower 95%-confidence bounds
TID.CB95 = cell2mat(TID.CB95);
disp(TID);

% % % Estimate statistics for behavioral outcome prior to surgery % % %
% % % "MODEL-1" % % %
fprintf(1,'----------------------------------------------------------\n');
fprintf(1,'<strong>MODEL-1</strong> Fitting GLME for <strong>nSuccess</strong> (standard scoring)...');
glme_outcome_pre = fitglme(tPreOp,...
   "nSuccess~1+GroupID+(1|AnimalID)",...
   "FitMethod","REMPL",...
   "Distribution","binomial",...
   "Link","logit",...
   "BinomialSize",tPreOp.nTotal);
fprintf(1,'complete\n');
fprintf(1,'----------------------------------------------------------\n');
disp(glme_outcome_pre);
fprintf(1,'----------------------------------------------------------\n');
fprintf(1,'<strong>Fit (MODEL-1):</strong>\n');
disp(glme_outcome_pre.Rsquared);
fprintf(1,'----------------------------------------------------------\n');

% % % Estimate statistics for behavioral outcomes: Pre-vs-Post, by Group % % %
% % % "MODEL-2" % % %
fprintf(1,'----------------------------------------------------------\n');
fprintf(1,'\t<strong>MODEL-2</strong> Fitting GLME for <strong>Pre-vs-Post Implant Success</strong>...');
glme_prepost = fitglme(tSub,"nSuccess~1+PrePost*GroupID+(1|AnimalID)",...
   "BinomialSize",tSub.nTotal,...
   "Link","logit",...
   "Distribution","Binomial",...
   "FitMethod","REMPL");
fprintf(1,'complete\n');
fprintf(1,'----------------------------------------------------------\n');
disp(glme_prepost);
fprintf(1,'----------------------------------------------------------\n');
fprintf(1,'<strong>Fit (MODEL-2):</strong>\n');
disp(glme_prepost.Rsquared);
fprintf(1,'----------------------------------------------------------\n');

% % % Estimate statistics for behavioral outcomes using standard scoring % % %
% % % "MODEL-3" % % %
fprintf(1,'----------------------------------------------------------\n');
fprintf(1,'<strong>MODEL-3</strong> Fitting GLME for <strong>nSuccess</strong> (standard scoring)...');
glme_outcome_all = fitglme(tPostOp,...
   "nSuccess~1+GroupID*Day_Cubed+(1+Day+Day_Cubed|AnimalID)",...
   "FitMethod","REMPL",...
   "Distribution","binomial",...
   "Link","logit",...
   "BinomialSize",tPostOp.nTotal);
fprintf(1,'complete\n');
fprintf(1,'----------------------------------------------------------\n');
disp(glme_outcome_all);
fprintf(1,'----------------------------------------------------------\n');
fprintf(1,'<strong>Fit (MODEL-3):</strong>\n');
disp(glme_outcome_all.Rsquared);
fprintf(1,'----------------------------------------------------------\n');

% % % Make Fig. 1b graphics % % %
%  -> 'Grasp' aligned only
%  -> Min trial duration: 100-ms
%  -> Max trial duration: 750-ms

% u ~ temporary (for groupings)
u = UTrials;
u.Outcome((u.Duration <= 0.100) | (u.Duration >= 0.750),:) = "Unsuccessful";
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
   'LegendLocation','northeast');
saveas(fig,fullfile(outPath,'FigS1 - Post-Op Success Rate - Neural Scoring.png'));
savefig(fig,fullfile(outPath,'FigS1 - Post-Op Success Rate - Neural Scoring.fig'));
delete(fig);

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

% % % Estimate statistics for behavioral outcomes using neural scoring % % %
% % % "MODEL-4" % % %
fprintf(1,'----------------------------------------------------------\n');
fprintf(1,'<strong>MODEL-4</strong> Fitting GLME for <strong>nSuccess (comparison of Standard vs Neural)</strong>...');
glme_methods = fitglme(tMethod,...
   "nSuccess~1+Method*GroupID*Day_Cubed+(1+Day+Day_Cubed|AnimalID)",...
   "FitMethod","REMPL",...
   "Distribution","binomial",...
   "Link","logit",...
   "BinomialSize",tMethod.nTotal);
fprintf(1,'complete\n');
fprintf(1,'----------------------------------------------------------\n');
disp(glme_methods);
fprintf(1,'----------------------------------------------------------\n');
fprintf(1,'\t<strong>Fit (MODEL-4):</strong>\n');
disp(glme_methods.Rsquared);
fprintf(1,'----------------------------------------------------------\n');

% % % % Estimate statistics for behavioral outcomes using neural scoring % % %
% % % % "MODEL-5" % % %
% fprintf(1,'----------------------------------------------------------\n');
% fprintf(1,'<strong>MODEL-5</strong> Fitting GLME for <strong>nSuccess</strong> (neural data trial exclusions applied)...');
% glme_outcome_neu = fitglme(U,...
%    "nSuccess~1+GroupID*Day_Cubed+(1+Day+Day_Cubed|AnimalID)",...
%    "FitMethod","REMPL",...
%    "Distribution","binomial",...
%    "Link","logit",...
%    "BinomialSize",U.nTotal);
% fprintf(1,'complete\n');
% fprintf(1,'----------------------------------------------------------\n');
% disp(glme_outcome_neu);
% fprintf(1,'----------------------------------------------------------\n');
% fprintf(1,'\t<strong>Fit (MODEL-5):</strong>\n');
% disp(glme_outcome_neu.Rsquared);
% fprintf(1,'----------------------------------------------------------\n');
% fprintf(1,'\t<strong>Random Effects (MODEL-5):</strong>\n');
% [~,~,re_stats] = randomEffects(glme_outcome_neu);
% disp(re_stats(1:4:size(re_stats,1),[2:4,8]));
% disp(re_stats(2:4:size(re_stats,1),[2:4,8]));
% disp(re_stats(3:4:size(re_stats,1),[2:4,8]));
% disp(re_stats(4:4:size(re_stats,1),[2:4,8]));
% fprintf(1,'----------------------------------------------------------\n');
