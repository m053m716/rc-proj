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
[tank,pname] = local.defaults('CommunalDataTank','LocalDataTank');
p.tank = tank;
p.local_tank = pname;
[tmp,~,~] = fileparts(mfilename('fullpath'));
[tmp,~,~] = fileparts(tmp);
[p.local_repo_name,~,~] = fileparts(tmp);
p.group_data_name = fullfile(pname,'gData.mat');
p.icms_data_name = fullfile(pname,'icms_data.xlsx');
p.behavior_data_file = fullfile(pname,'behavior_data.xlsx');
p.rate_table = fullfile(pname,'rate_data.mat');
p.rate_csv = fullfile(pname,'rate_data.csv');

% From analyses
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
p.movie_loc = 'channel-plot-movies';
p.movie_fname_str = '%s_%s_power-v-time.avi';

% From `block`
p.elec_info_xlsx = fullfile(p.tank,'electrode_stereotaxic_centers.xlsx');
p.behavior_vid_loc = 'K:\Rat\Video\BilateralReach\RC';
p.frame_snaps_loc = 'behavior-snapshots';
p.spike_analyses_folder = '_SpikeAnalyses';
p.fname_orig_rate = '%s%s%s_%s.mat';
p.fname_ds_rate = '%s%s%s_%s_ds-%gx.mat';
p.spike_rate_expr = '%s_SpikeRate%03gms_%s_%s.mat';
p.binned_spike_expr = '%s_BinnedSpikes%03gms_%s_%s.mat';

% From `group`
p.session_export_spreadsheet = 'Stats-By-Session.xlsx';
p.channel_export_spreadsheet = 'Stats-By-Channel.xlsx';
p.rat_export_spreadsheet = 'Stats-By-Rat.xlsx';
p.trial_export_spreadsheet = 'Stats-By-Trial.xlsx';
p.marg_fig_loc = 'marginal-rate-average-figs_ds-50x';
p.marg_fig_name = '%s-%s_%s__X__%s%s';

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