function param = rat(name)
%% DEFAULTS.RAT    Return default parameter for GROUP class object
%
%  param = DEFAULTS.RAT(name);
%
%           -> 'icms_file'
%           -> 'x_lim_screening'
%           -> 'y_lim_screening'
%           -> 'lpf_order'
%           -> 'lpf_fc'
%           -> 'fs'
%           -> 't_var_interest'
%           -> 'rate_avg_fig_dir'
%
% By: Max Murphy  v1.0  2019-06-06  Original version (R2017a)

%% CHANGE THESE
p = struct; % All field names should be lower-case
p.icms_file = fullfile(defaults.experiment('tank'),defaults.experiment('icms_data_name'));
p.x_lim_screening = [-1750, 750];   % x-limits for screening plots
p.y_lim_screening = [-15 15];       % y-limits for screening plots
p.x_lim_norm = [-1250, 750];
p.y_lim_norm = [-3 3];
p.lpf_order = 4;
% p.lpf_fc = 50;
p.lpf_fc = nan;
p.fs = 24414.0625;
p.t_var_interest = [-0.5 0.5];
p.rate_avg_fig_dir = 'rate-averages-new';
p.norm_avg_fig_dir = 'norm-rate-averages-new';
p.norm_includestruct_fig_dir = 'includeStruct';
p.total_rate_avg_subplots = 35; % Total number of subplots to create
p.rate_avg_leg_subplot = 35; % Index of the "daily average rate" subplot to contain a legend
p.suppress_data_curation = true; % should set to false if haven't curated data yet
% p.suppress_data_curation = false; 
p.batch_align = defaults.jPCA('jpca_align');
p.align = 'Grasp';
p.include = utils.makeIncludeStruct({'Reach','Grasp','Outcome'},[]);
p.batch_outcome = 'All';
p.batch_area = 'Unified';
p.channel_mask_loc = defaults.block('channel_mask_loc');
p.run_jpca_on_construction = defaults.block('run_jpca_on_construction');
p.do_spike_rate_extraction = defaults.block('do_spike_rate_extraction');

% For plotting marginalizations
p.includeStructPlot = utils.makeIncludeStruct({'Reach','Grasp','PelletPresent','Outcome'},[]);
p.includeStructMarg = p.includeStructPlot; % Same, but the marginalization occurs across days

% For "channel modulation" epoch identification
p.ch_mod_epoch_start_stop = [-750 500]; % [onset,offset] of interest (ms)
p.ch_mod_legopts = struct('yLim',[-2 3.75],... % for plotting "legend" axes
                          'scoreScale',2,...
                          'scoreOffset',1.5,...
                          'barScale',1,...
                          'textOffset',[0.75,-0.85],...
                          'minTrials',10,...
                          'cfaTextY',0.5,...
                          'rfaTextY',-0.5,...
                          'axYLabel','Relative Modulation',...
                          'scatterMarkerSize',30); 

% For making figures in general
e = 0.015*randn;
p.big_fig_pos = [0.1+e 0.1+e 0.8 0.8]; % "Big"
p.bl_fig_pos = [0.1+e 0.1+e 0.3 0.3]; % Bottom-Left
p.ul_fig_pos = [0.1+e 0.5+e 0.3 0.3]; % Upper-Left
p.br_fig_pos = [0.5+e 0.1+e 0.3 0.3]; % Bottom-Right
p.ur_fig_pos = [0.5+e 0.5+e 0.3 0.3]; % Upper-Right

% For plotting channels by day
p.ch_by_day_xlim = [0 31];
p.ch_by_day_ylim = [-0.1 1];
p.ch_by_day_xaxisloc = 'origin';
p.ch_by_day_legopts = struct('yLim',[-2 3.75],... % for plotting "legend" axes
                          'scoreScale',2,...
                          'scoreOffset',1.5,...
                          'barScale',1,...
                          'textOffset',[0.75,-0.85],...
                          'minTrials',10,...
                          'cfaTextY',0.5,...
                          'rfaTextY',-0.5,...
                          'axYLabel','Relative Modulation',...
                          'scatterMarkerSize',30); 

% For PLOTMEANCOHERENCE method
p.ch_by_day_coh_xloc = 'bottom';
p.ch_by_day_coh_xlim = [0 12];
p.ch_by_day_coh_ylim = [0 31];
p.ch_by_day_coh_zlim = [0 1];
p.coh_plot_type = 'heatmap'; % can be: 'ribbon', 'waterfall', 'surface', or 'heatmap'
p.coh_ax_angle = [10 45]; % azimuth, elevation
p.coh_x_lab = 'Freq (Hz)';
p.coh_y_lab = 'PO-Day';
p.cm_name = 'hotcold';
p.coh_fig_fname = ['%s_%s__%s__' p.coh_plot_type];

% For EXPORTSKULLPLOTMOVIE method
p.movie_n_frames = 900; % Total number of frames in movie
p.movie_fs = 30; % Frames per second
p.movie_loc = 'channel-plot-movies';
p.movie_fname_str = '%s_%s_power-v-time.avi';

%% PARSE OUTPUT
if ismember(lower(name),fieldnames(p))
   param = p.(lower(name));
else
   error('%s is not a valid parameter. Check spelling?',lower(name));
end


end

