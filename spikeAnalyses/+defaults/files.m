function varargout = files(varargin)
%FILES  Subset of defaults that dealing with file names
%
%  p = defaults.files();
%  [var1,var2,...] = defaults.files('var1Name','var2Name',...);
%
%  # Parameters (`name` values) #
%  -> 'tank'            : (Remote) data tank location (folder)
%  -> 'local_tank'      : (Local) data tank location (folder)
%  -> 'group_data_name' : Name of "gData" file
%  -> 'icms_data_name'  : Name of icms excel spreadsheet

p = struct;
[tank,pname,ptableau] = local.defaults(...
   'CommunalDataTank','LocalDataTank','TableauFolder');
p.tank = tank;
p.local_tank = pname;
p.remote_tank = tank;
[tmp,~,~] = fileparts(mfilename('fullpath'));
[tmp,~,~] = fileparts(tmp);
[p.local_repo_name,~,~] = fileparts(tmp);
% p.group_data_name = fullfile(pname,'gData.mat');
p.group_data_file = '2020_gData.mat'; % This was used in most analyses, it has normalized rates in .Data instead of binned spike counts.
p.group_data_file_raw_binned_version = '2020_gData-60_ms_binnned_data.mat'; % This version has binned spike counts in .Data instead of normalized rates
p.group_data_name = fullfile(pname,p.group_data_file);
p.icms_data_file = 'icms_data.xlsx';
p.icms_data_name = fullfile(pname,p.icms_data_file);
p.behavior_data_file = fullfile(pname,'behavior_data.xlsx'); % For score type = 'BehaviorScore'
p.neurophys_behavior_data_file = fullfile(pname,'neurophys_behavior_data'); % For score type = 'NeurophysScore'

p.default_tables_to_load = 'counts'; % 'counts' | 'dynamics' | 'rates'

p.rate_table = fullfile(pname,'rate_data.mat');
p.rate_csv = fullfile(pname,'rate_data.csv');

% Rate table default:
p.rate_table_base_matfile = fullfile(pname,'T.mat');
p.rate_table_default_matfile = fullfile(pname,'T_default.mat');
p.rate_unique_trials_matfile = fullfile(pname,'T_unique_trials.mat');
p.raw_rates_table_file = fullfile(pname,'R_raw-rates.mat');
p.learning_rates_table_file = fullfile(pname,'r_unit-learning-rates.mat');
p.outcome_models_matfile = fullfile(pname,'MODELS_1-4.mat');
p.duration_models_matfile = fullfile(pname,'MODELS_5-9.mat');
p.rate_models_pre_reach_retract_matfile = fullfile(pname,'MODELS_10-12.mat');
p.pop_models_pre_reach_retract_matfile = fullfile(pname,'MODELS_13-18.mat');
p.cross_day_channel_trends_models_matfile = fullfile(pname,'MODELS_19-21.mat');

% For figure export
p.local_figure_export = fullfile(pname,'Figures');
p.reach_extension_figure_dir = fullfile(p.local_figure_export,'Reach-Retract-Figures');

% Population Dynamics ('multi_jPCA.m' exported table)
p.multi_jpca_default_matfile = fullfile(pname,'Multi_jPCA_Table.mat'); % Original "multi-jPCA" table
p.multi_jpca_long_timescale_matfile = fullfile(pname,'Multi_jPCA_Table_Long-Timescale.mat'); % "Multi-jPCA" table using longer time basis
p.exported_jpca_matfile = fullfile(pname,'jPCA_Export_Table_for-stats.mat');  % Table for population dynamics statistics
p.cell_array_of_projections = fullfile(pname,'jPCA_Projections_Cell_Array.mat'); % Projections used for exporting videos etc.

% Single-channel dynamics
p.default_gauspuls_table = fullfile(pname,'Fitted-GausPuls-Table.mat');
p.single_channel_stats_mlx_table = fullfile(pname,'Fitted_GausPuls-Table_Restricted-Subset.mat');

% For "Tableau" visualization:
p.rate_tableau_table = fullfile(ptableau,'All Rates.xlsx');
p.rate_tableau_table_matfile = fullfile(pname,'T.mat');
p.table_rows_file = fullfile(pname,'All Rates__RowNames.mat');
p.default_rowtimes_file = fullfile(ptableau,'All Times.xlsx');
p.default_rowmeta_matfile = fullfile(pname,'RowMetadata.mat');
p.tableau_spreadsheet_tag_struct = struct(...
   'Times','__Times',...
   'Locations','__Locations',...
   'Meta','__Meta',...
   'Events','__Events',...
   'Rates','__Data'...
   );

% For jPCA stuff:
p.jpca_fig_folder = fullfile(pname,'2020_JPCA');
p.jpca_movies_folder = 'Exported Movies';
p.jpca_rosettes_folder = 'Rosettes';
p.jpca_rosettes_fname_expr = '%s_%s_Day-%02d_Plane-%02d_Rosette';
p.jpca_phase_folder = 'Phase';
p.jpca_phase_fname_expr = '%s_%s_Day-%02d_Plane-%02d_Phase';

% From analyses
p.stat_fit_fig_folder = fullfile(pname,'2020_FMINCON_FIT');
p.spike_folder_tag = '_wav-sneo_CAR_Spikes';
p.condition_response_corr_loc = 'cross-day-correlations';
p.fname_corr = '%s-%s__%s__corr';
p.fname_coh = '%s_%s__%s__coherence_';

% From `rat`
p.rate_avg_fig_dir = 'rate-averages-new';
% p.norm_avg_fig_dir = 'norm-rate-averages-new';
p.norm_avg_fig_dir = 'norm-rate-averages_2020_ds-50x';
p.norm_includestruct_fig_dir = 'includeStruct';
p.channel_mask_loc = 'channel-masks';
p.channel_mask_tag = '_ChannelMask.mat';
p.coh_fig_str = '%s_%s__%s__';

% From `block`
p.elec_info_xlsx = fullfile(p.tank,'electrode_stereotaxic_centers.xlsx');
p.behavior_vid_loc = 'K:\Rat\Video\BilateralReach\RC';
p.frame_snaps_loc = 'behavior-snapshots';
p.spike_analyses_folder = '_SpikeAnalyses';
p.fname_orig_rate = '%s%s%s_%s.mat';
p.fname_ds_rate = '%s%s%s_%s_ds-%gx.mat';
p.spike_rate_expr = '%s_SpikeRate%03gms_%s_%s.mat';
p.binned_spike_expr = '%s_BinnedSpikes%03gms_%s_%s.mat';

% From @group
p.session_export_spreadsheet = 'Stats-By-Session.xlsx';
p.channel_export_spreadsheet = 'Stats-By-Channel.xlsx';
p.rat_export_spreadsheet = 'Stats-By-Rat.xlsx';
p.trial_export_spreadsheet = 'Stats-By-Trial.xlsx';
p.marg_fig_loc = 'marginal-rate-average-figs_ds-50x';
p.marg_fig_name = '%s-%s_%s__X__%s%s';

% For +analyze/+nnm
p.nnmf_dir = fullfile(pname,'2020_NNMF');
p.nnmf_h0 = 'NNMF_h0.mat';
p.nnmf_tableau = 'RC-NNMF.xlsx';
p.nnmf_tableau_blocked = 'RC-NNMF_Blocked.xlsx';
p.nnmf_jmp = 'RC-JMP.xlsx';
p.nnmf_jmp_blocked = 'RC-JMP_Blocked.xlsx';
p.nnmf_mat_fig = fullfile(pname,'scratchwork\\NNMF\\NNMF Factor Correlations %s vs %s');
p.nnmf_overlay_fig = fullfile(pname,'scratchwork\\NNMF\\NNMF Factor Overlay %s vs %s');
p.nnmf_summary_fig = fullfile(pname,'scratchwork','NNMF','NNMF Factors Summary');

% From PCA analysis
p.pca_dir = fullfile(pname,'2020_PCA');
p.pca_fig_dir = fullfile(pname,'scratchwork','PCA');
p.pca_view_figs = '%s -- Top %g PCs';
p.pca_tableau = 'RC-Tableau_PCs.xlsx';
p.pca_jmp = 'RC-JMP_PCs.xlsx';

% From +analyze/+fails
p.fails_dir = fullfile(pname,'2020_FAILS');
p.fails_fig_dir = fullfile(pname,'scratchwork','FAILS');
p.fails_view_figs = '%s -- Top %g Fails-PCs';
p.fails_tableau = 'RC-Tableau_Fails-PCs.xlsx';
p.fails_jmp = 'RC-JMP_Fails-PCs.xlsx';

% From +analyze/+complete
p.complete_dir = fullfile(pname,'2020_COMPLETE');
p.complete_fig_dir = fullfile(pname,'scratchwork','COMPLETE');
p.complete_view_figs = '%s -- Top %g Complete-PCs';
p.complete_tableau = 'RC-Tableau_Complete-PCs.xlsx';
p.complete_jmp = 'RC-JMP_Complete-PCs.xlsx';

% From +analyze/+rec
p.rec_analyses_dir = fullfile(pname,'2020_BY-BLOCK');
p.rec_analyses_fig_dir = fullfile(pname,'scratchwork','BY-BLOCK');

% From +analyze/+dynamics
p.area_dynamics_fig_dir = fullfile(pname,'2020_AREA-DYNAMICS');

% For html exports
p.html_result_dir = 'D:/MyRepos/GitHub Pages/RC-Data/Results';

% Parse output
if nargin < 1
   varargout = {p};   
else
   F = fieldnames(p);   
   if (nargout == 1) && (numel(varargin) > 1)
      varargout{1} = struct;
      for iV = 1:numel(varargin)
         idx = strcmpi(F,varargin{iV});
         if sum(idx)==1
            varargout{1}.(F{idx}) = p.(F{idx});
         end
      end
   elseif nargout > 0
      varargout = cell(1,nargout);
      for iV = 1:nargout
         idx = strcmpi(F,varargin{iV});
         if sum(idx)==1
            varargout{iV} = p.(F{idx});
         end
      end
   else
      for iV = 1:nargin
         idx = strcmpi(F,varargin{iV});
         if sum(idx) == 1
            fprintf('<strong>%s</strong>:',F{idx});
            disp(p.(F{idx}));
         end
      end
   end
end

end