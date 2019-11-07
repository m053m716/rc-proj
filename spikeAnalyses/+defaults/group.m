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
p.local_repo_name = 'C:\MyRepos\shared\rc-proj\spikeAnalyses'; % specific to your computer
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
      0.45  0.00  0.00;    % RC-02
      0.50  0.05  0.05;    % RC-04
      0.60  0.10  0.10;    % RC-05
      0.70  0.15  0.15;    % RC-08
      0.85  0.20  0.20;    % RC-26
      0.90  0.35  0.35],...% RC-30
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

% Recent-Alignment defaults
p.align = 'Grasp';
p.include = utils.makeIncludeStruct({'Reach','Grasp','Outcome'},[]);

% Rat skull plots
p.skull_lf_lb = 1.5; % Hz (lower-bound on frequency band for sum)
p.skull_lf_ub = 5; % Hz (upper-bound on frequency band for sum)
p.skull_poday_lb = 1; % Default to include all post-op days
p.skull_poday_ub = 31; % Default to include all post-op days
p.skull_et1_x = repmat(-0.5:1:1.5,1,2);
p.skull_et1_y = [ones(1,3)*-2.5,ones(1,3)*-3.5];
p.skull_icms_key = struct(... % Field is representation acronym; value is color
   'DF','b',... % distal forelimb
   'PF','g',... % proximal forelimb
   'DFPF','c',... % distal-forelimb/proximal-forelimb boundaries = mix of blue & green
   'NR','k',... % no response
   'O','m'); % "other" (trunk, face, vibrissae, mouth)
p.skull_min_size = 5;
p.skull_max_size = 150;
p.skull_n_size_levels = 20;
p.skull_cmu_size = 20;
p.skull_cstd_size = 3.5;
p.skull_mu_size = 40;
p.skull_std_size = 20;

% Generic figures
e = 0.01 * randn;
p.big_fig_pos = [0.1 + e, 0.1 + e, 0.8 0.8];


%% PARSE OUTPUT
if ismember(lower(name),fieldnames(p))
   param = p.(lower(name));
else
   error('%s is not a valid parameter. Check spelling?',lower(name));
end


end