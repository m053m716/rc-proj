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
p.icms_file = 'P:\Extracted_Data_To_Move\Rat\TDTRat\icms_data.xlsx';
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

%% PARSE OUTPUT
if ismember(lower(name),fieldnames(p))
   param = p.(lower(name));
else
   error('%s is not a valid parameter. Check spelling?',lower(name));
end


end

