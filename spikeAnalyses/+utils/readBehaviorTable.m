function T = readBehaviorTable(fileName,addPerformance)
%READBEHAVIORTABLE Read in and format "Standard-Scoring" behavior table
%
%  T = utils.readBehaviorTable();
%     -> Uses value in defaults.files('behavior_data_file')
%  T = utils.readBehaviorTable(fileName);
%  T = utils.readBehaviorTable(fileName,addPerformanceTrends);
%
% Inputs
%  fileName - (Optional) Char array that is full filename of behavior data
%                 spreadsheet
%  addPerformanceTrends - (Optional) false (def) : If true, adds
%                             interpolated performance trend estimates
%                             using generalized linear mixed-effects model
%                             (logit link, binomial distribution) on a
%                             per-animal basis.
%
% Output
%  T        - Formatted table used in trial_outcome_stats
%
% See also: trial_outcome_stats, analyze.behavior,
%           analyze.behavior.per_animal_area_mean_rates

if nargin < 1
   fileName = defaults.files('behavior_data_file');
elseif isempty(fileName)
   fileName = defaults.files('behavior_data_file');
end

if nargin < 2
   addPerformance = false;
end

T = readtable(fileName);
% No M1-C rats %
T(strcmpi(T.Group,'M1-C'),:) = [];
T.GroupID = categorical(T.Group,{'ET-1','SHAM'},{'Ischemia','Intact'});
T.AnimalID = categorical(T.Name);

% Add variables to table, parsed from other variables %
T.PrePost = categorical(double(T.Day > 0),[0 1],{'Pre','Post'});
T.Properties.RowNames = strcat(...
   string(T.AnimalID),'::',...
   string(T.PrePost),'::',...
   string(strtrim(num2str(abs(T.Day),'%02d'))));
T.nTotal = round(T.nSuccess ./ T.pct);
T.Day_Cubed = T.Day.^3;
T.Percent_Successful = T.pct .* 100;
T.PostOpDay = T.Day;
T.PostOpDay_Cubed = T.Day_Cubed;
T.Performance_score = sqrt(asin(T.pct)./(pi/2));

if ~addPerformance
   return;
end

T.Performance_mu = tanh(2*pi*(T.pct-0.5));
T = T(T.Day > 0,:);
[~,TID] = findgroups(T(:,{'GroupID','AnimalID'}));
PostOpDay = (3:31)';
PostOpDay_Cubed = PostOpDay.^3;
n = numel(PostOpDay);

out = [];
for iG = 1:size(TID,1)
   AnimalID = TID.AnimalID(iG);
   tThis = T(T.AnimalID==AnimalID,:);
   mdl = fitglm(tThis,"Performance_mu~1+PostOpDay+PostOpDay_Cubed");
   
   AnimalID = repmat(AnimalID,n,1);
   GroupID = repmat(TID.GroupID(iG),n,1);
   tmp = table(AnimalID,GroupID,PostOpDay,PostOpDay_Cubed);
   [tmp.Performance_hat_mu,tmp.cb95] = predict(mdl,tmp);
   tmp = splitvars(tmp,'cb95');
   tmp.Properties.VariableNames{'cb95_1'} = 'Performance_hat_cb95_lb';
   tmp.Properties.VariableNames{'cb95_2'} = 'Performance_hat_cb95_ub';
   tmp.Performance_hat_cb95 = tmp.Performance_hat_cb95_ub - tmp.Performance_hat_cb95_lb;
   out = [out; tmp];  %#ok<AGROW>
end
T = outerjoin(T,out,...
      'Keys',{'GroupID','AnimalID','PostOpDay','PostOpDay_Cubed'},...
      'MergeKeys',true,...
      'LeftVariables',{'GroupID','AnimalID','nSuccess','nTotal','PostOpDay','PostOpDay_Cubed','Performance_mu'},...
      'RightVariables',{'GroupID','AnimalID','PostOpDay','PostOpDay_Cubed','Performance_hat_mu','Performance_hat_cb95','Performance_hat_cb95_lb','Performance_hat_cb95_ub'},...
      'Type','full');  
T.Performance_hat_mu = max(min(T.Performance_hat_mu,1),-1);

end