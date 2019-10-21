function param = group(name)
%% DEFAULTS.GROUP    Return default parameter for GROUP class object
%
%  param = DEFAULTS.GROUP(name);
%
%           -> 'decimation_factor'
%           -> 'min_pca_var'
%           -> 'output_score'
%           -> 'rat_marker'
%           -> 'rat_color'
%           -> 'somatotopy_pca_behavior_fig_dir'
%           -> 'icms_opts'
%           -> 'area_opts'
%
% By: Max Murphy  v1.0  2019-06-06  Original version (R2017a)

%% CHANGE THESE
p = struct; % All field names should be lower-case
p.decimation_factor = 10;  % Amount to decimate time-series for PCA
p.min_pca_var = 90;        % Minimum % of variance for PCs to explain
% p.output_score = 'NeurophysScore'; % options are 'BehaviorScore' or 'NeurophysScore'
p.output_score = 'TrueScore';
p.rat_marker = {'o','*','square','x','v','hexagram'};
p.rat_color = struct(...
   'All',[...
      0.65  0.00  0.00;    % RC-02
      0.70  0.05  0.05;    % RC-04
      0.75  0.10  0.10;    % RC-05
      0.80  0.15  0.15;    % RC-08
      0.00  0.00  0.65;    % RC-14
      0.05  0.05  0.70;    % RC-18
      0.10  0.10  0.75;    % RC-21
      0.85  0.20  0.20;    % RC-26
      0.90  0.25  0.25;    % RC-30
      0.15  0.15  0.80],...% RC-43
   'Ischemia',[...
      0.65  0.00  0.00;    % RC-02
      0.70  0.05  0.05;    % RC-04
      0.75  0.10  0.10;    % RC-05
      0.80  0.15  0.15;    % RC-08
      0.85  0.20  0.20;    % RC-26
      0.90  0.25  0.25],...% RC-30
   'Intact',[...
      0.00  0.00  0.65;    % RC-14
      0.05  0.05  0.70;    % RC-18
      0.10  0.10  0.75;    % RC-21
      0.15  0.15  0.80]);  % RC-43
      
p.somatotopy_pca_behavior_fig_dir = 'somatotopy-pca-behavior-scatters-new';
p.icms_opts = {'PF','DF'};
p.area_opts = defaults.block('area_opts');
p.area_color = defaults.block('area_color');

% p.w_avg_dp_thresh = 0.90; % threshold for weighted-average trials
p.w_avg_dp_thresh = 0;

% Export filenames
p.session_export_spreadsheet = 'Stats-By-Session.xlsx';
p.channel_export_spreadsheet = 'Stats-By-Channel.xlsx';
p.rat_export_spreadsheet = 'Stats-By-Rat.xlsx';
p.trial_export_spreadsheet = 'Stats-By-Trial.xlsx';

% Figure name and location
p.marg_fig_loc = 'marginal-rate-average-figs';
p.marg_fig_name = '%s-%s_%s__X__%s%s';

% Cross-condition info
p.xc_fields = {'Outcome','PelletPresent','Reach','Grasp','Support','Complete'};

%% PARSE OUTPUT
if ismember(lower(name),fieldnames(p))
   param = p.(lower(name));
else
   error('%s is not a valid parameter. Check spelling?',lower(name));
end


end