function param = block(name)
%% DEFAULTS.BLOCK  Return default parameter for GROUP class object
%
%  param = DEFAULTS.BLOCK(name);
%
%           -> 'lpf_order'
%           -> 'lpf_fc'
%           -> 'fs'
%           -> 'jpca_decimation_factor'
%           -> 'jpca_start_stop_times'
%           -> 'optimization_options'
%           -> 'behavior_data_file'
%           -> 'spike_analyses_folder'
%           -> 'spike_rate_smoother'
%           -> 'alignment'
%           -> 'channel-masks'
%
% By: Max Murphy  v1.0  2019-06-06  Original version (R2017a)

%% CHANGE THESE
p = struct;          % All field names should be lower-case
p.lpf_order = 4;     % Rate lowpass filter (butterworth) order
p.lpf_fc = nan;      % Rate lowpass filter cutoff frequency
p.fs = 24414.0625;   % Sampling frequency for acquisition

% Name of excel file with behavior data scored by Andrea
p.behavior_data_file = fullfile(defaults.experiment('tank'),'behavior_data.xlsx');
p.channel_mask_loc = 'channel-masks';

% Optimizer for fitting the "rebase" projection matrix
p.optimization_options = optimoptions(... 
   @fminunc,...
   'Display','off',...
   'MaxIterations',1e4,...
   'SpecifyObjectiveGradient',true,...
   'MaxFunctionEvaluations',1e5,...
   'StepTolerance',1e-9);

% Spike analyses data variables
p.spike_analyses_folder = '_SpikeAnalyses';
p.start_stop_bin = [-2000 1000]; % ms
p.spike_bin_w = 1; % ms
p.spike_smoother_w = 30; % ms
p.n_ds_bin_edges = 100; % From [-2000 1000] this yields bin size of 30 ms
% Factor to decimate spike rate by:
p.r_ds = round((p.start_stop_bin(2) - p.start_stop_bin(1))/p.spike_bin_w/p.n_ds_bin_edges); 
p.spike_rate_smoother = sprintf('_SpikeRate%03gms_',p.spike_smoother_w);
p.norm_spike_rate_tag = sprintf('_NormSpikeRate%03gms_',p.spike_smoother_w);
p.fname_orig_rate = '%s%s%s_%s.mat';
p.fname_ds_rate = '%s%s%s_%s_ds-%gx.mat';
p.alignment = 'Grasp';
p.align = 'Grasp'; % same as "alignment" but just to make it compatible keep both
p.include = utils.makeIncludeStruct({'Reach','Grasp','Outcome'},[]);
p.all_alignments = {'Successful',1;...
                    'Unsuccessful',0;...
                    'All',[0,1]};
p.all_events = {'Reach','Grasp','Support','Complete'};
p.event_color = {[0.1 0.1 0.7],[0 0 0],[0.8 0.1 0.8],[0.7 0.8 0.1]};
p.all_outcomes = {'Successful','Unsuccessful','All'};
p.outcome = 'Successful';
p.do_spike_rate_extraction = false;
p.overwrite_old_spike_data = false;
p.run_jpca_on_construction = false;

% % worthless "warp rates" parameters... deprecated
% p.warp.pre_reach = 350;  % ms
% p.warp.post_grasp = 500; % ms
% p.warp.nPoints = 850;
% p.warp.trim = 50; % samples to trim from ends

% samples to use for normalizing individual trial rates per channel
p.pre_trial_norm = 1:500; % sample indices
p.pre_trial_norm_ds = p.pre_trial_norm(1):round(p.pre_trial_norm(end)/p.r_ds);

% location of behavioral videos on lab server
p.behavior_vid_loc = 'K:\Rat\Video\BilateralReach\RC';

p.frame_snaps_loc = 'behavior-snapshots';

p.area_opts = {'RFA','CFA'};
p.area_color = {'b','r'};
p.x_lim = [-1250 750];
p.y_lim = [-3.0 3.0];

% For exporting concatenated tables
p.trial_stats_var_descriptions = { ...
   'recording "block" name'; ...
   'day relative to surgery'; ...
   'date of trial'; ...
   'estimated trial onset'; ...
   'reach frame onset (toe off; inf = start reach from outside box)'; ...
   'grasp frame onset (digit flexion; inf = reach without any flexion)'; ...
   'support frame onset (movement of ipsilateral limb; inf = no movement of ipsilateral limb)'; ...
   'complete frame onset (bring paw fully back into box and reset for next trial; inf = left paw out or flailed again)'; ...
   'number of pellets observed on platform'; ...
   'is there a pellet in the correct spot in front of him?'; ...
   '0 - unsuccessful; 1 - successful'; ...
   'which forelimb was used for reaching'};

% For parsing electrode orientation/location
p.elec_grid_x = repmat(linspace(-0.875,0.875,8),2,1); % mm; rostro-caudal axis
p.elec_grid_y = repmat([0.25; -0.25],1,8); % mm; medio-lasteral axis
p.elec_grid_ord = [ 1, 2, 3, 4, 5, 6, 7, 8; ...
                   16,15,14,13,12,11,10, 9]; % Channel indices/arrangement
p.elec_info_xlsx = fullfile(defaults.experiment('tank'),...
                            'electrode_stereotaxic_centers.xlsx');
                
%% PARSE OUTPUT
if ismember(lower(name),fieldnames(p))
   param = p.(lower(name));
else
   error('%s is not a valid parameter. Check spelling?',lower(name));
end


end

