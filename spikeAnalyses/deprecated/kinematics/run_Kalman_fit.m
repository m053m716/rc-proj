%% RUN_KALMAN_FIT Batch script for doing Kalman Filtering estimates
%
% By: Max Murph   v1.0  08/01/2018  Original version (R2017b)

fprintf(1,'\nBeginning step 6: rate-kinematic correlations\n');

%% DEFAULTS
FIG_DIR = fullfile(pwd,'fit_Fig');
DAT_DIR = fullfile(pwd,'fit_Data');
MODEL_ORDER = 5;

%% LOAD INPUTS
% load('J:\Rat\BilateralReach\Data\info.mat','block');
% load('..\02_do-linear-smoothing\linear_rates_20ms_pg.mat','T'); % long to load

F = dir('..\04_DeepLabCut\Pose_Data\*_pose.mat');
bname = {block.name}.';

%% LOOP THROUGH AND FIT KALMAN MODEL / GET PLOTS
for iF = 1:numel(F)
   Name = F(iF).name(1:16);
   blockIdx = contains(bname,Name);
   load(fullfile(F(iF).folder,F(iF).name),'data');
   
   % Obtain filter coefficients from trial average rate/kinematics
   trialData_mu = rlm_getMultiTrialInOutData(T,data,...
      Name(1:5),block(blockIdx).day);
   
   sys = cell(3,1);
   for ii = 1:numel(sys)
      sys{ii} = n4sid(trialData_mu{ii},MODEL_ORDER,...
         'Form','canonical',...
         'Name',trialData_mu{ii}.Name);
   end
   [y_mu,fit_mu] = compare(trialData_mu{1},sys{1},sys{2},sys{3});
   
   % Plot means
   figure('Name',trialData_mu{1}.Name(1:14),...
      'Units','Normalized',...
      'Position',[0.1 0.1 0.8 0.8],...
      'Color','w');
   compare(trialData_mu{1},sys{1},sys{2},sys{3});
   
   if exist(FIG_DIR,'dir')==0
      mkdir(FIG_DIR);
   end
   savefig(gcf,fullfile(FIG_DIR,[block(blockIdx).name '_fit.fig']));
   saveas(gcf,fullfile(FIG_DIR,[block(blockIdx).name '_fit.jpeg']));
   delete(gcf);
   
   y = cell(3,numel(data));
   fit = cell(3,numel(data));
   trialData = cell(3,numel(data));
   outcome = zeros(numel(data),1);
   use_trial = true(numel(data),1);
   for k = 1:numel(data)
      trialData(:,k) = rlm_getSingleTrialInOutData(T,data,...
         Name(1:5),block(blockIdx).day,k);
      try
         
         [y(:,k),fit(:,k)] = compare(trialData{1,k},sys{1},sys{2},sys{3},inf);
         outcome(k) = trialData{1,k}.UserData;
      catch
         use_trial(k) = false;
         warning('%s: trial %d skipped due to error.', block(blockIdx).name,k);
      end
   end
   
   if exist(DAT_DIR,'dir')==0
      mkdir(DAT_DIR);
   end
   
   save(fullfile(DAT_DIR,[block(blockIdx).name '_fit.mat']),...
      'trialData','trialData_mu',...
      'y_mu','fit_mu','y','fit',...
      'outcome','use_trial','-v7.3');
end

%% LOOP THROUGH SAVED DATA AND COMPUTE RMSE/ACCURACY CONTRIBUTIONS
F = dir('fit_Data/RC*_fit.mat');

A_CFA = [];
A_RFA = [];
Outcome = [];
Name = [];
Day = [];
Group = [];

for iF = 1:numel(F)
   load(fullfile(F(iF).folder,F(iF).name),'y','trialData','outcome','use_trial');
   y(:,~use_trial) = [];
   outcome(~use_trial) = [];
   trialData(:,~use_trial) = [];
   
   str = trialData{1}.Notes{2};
   
   group = str((regexp(str,': ')+2):end);
   name = F(iF).name(1:5);
   
   blockIdx = ismember(bname,F(iF).name(1:16));
   day = block(blockIdx).day;
   
   [a_cfa,a_rfa] = rlm_getAccuracyContribution(trialData,y,...
                     'PLOT_DIST',true,...
                     'AUTO_SAVE_FIG',true,...
                     'AUTO_SAVE_DATA',true);
   
                  
   A_CFA = [A_CFA; a_cfa]; %#ok<*AGROW>
   A_RFA = [A_RFA; a_rfa];
   Outcome = [Outcome; outcome];
   Name = [Name; repmat({name},numel(outcome),1)];
   Day = [Day; ones(numel(outcome),1).*day];
   Group = [Group; repmat({group},numel(outcome),1)];
   
end

A = table(Name,Day,Group,Outcome,A_CFA,A_RFA);
writetable(A,'RC-Data_Accuracy.xlsx');
