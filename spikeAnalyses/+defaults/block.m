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
p.lpf_fc = 60;       % Rate lowpass filter cutoff frequency
% p.lpf_fc = nan;
p.fs = 24414.0625;   % Sampling frequency for acquisition

% Name of excel file with behavior data scored by Andrea
p.behavior_data_file = 'P:\Extracted_Data_To_Move\Rat\TDTRat\behavior_data.xlsx';
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
p.spike_rate_smoother = sprintf('_SpikeRate%03gms_',p.spike_smoother_w);
p.alignment = defaults.jPCA('jpca_align');
p.all_alignments = {'Successful',1;...
                    'Unsuccessful',0;...
                    'All',[0,1]};
p.all_events = {'Reach','Grasp','Support','Complete'};
p.event_color = {[0.1 0.1 0.7],[0 0 0],[0.8 0.1 0.8],[0.7 0.8 0.1]};
p.all_outcomes = {'Successful','Unsuccessful','All'};
p.outcome = 'Successful';
% p.do_spike_rate_extraction = false;
p.do_spike_rate_extraction = true;
p.overwrite_old_spike_data = false;
p.run_jpca_on_construction = defaults.jPCA('run_jpca_on_construction');

% % worthless "warp rates" parameters... deprecated
% p.warp.pre_reach = 350;  % ms
% p.warp.post_grasp = 500; % ms
% p.warp.nPoints = 850;
% p.warp.trim = 50; % samples to trim from ends

% samples to use for normalizing individual trial rates per channel
p.pre_trial_norm = 1:500; % sample indices

% location of behavioral videos on lab server
p.behavior_vid_loc = 'K:\Rat\Video\BilateralReach\RC';

p.frame_snaps_loc = 'behavior-snapshots';

p.area_opts = {'RFA','CFA'};
p.area_color = {'b','r'};
p.x_lim = [-1250 750];
p.y_lim = [-3.0 3.0];

%% PARSE OUTPUT
if ismember(lower(name),fieldnames(p))
   param = p.(lower(name));
else
   error('%s is not a valid parameter. Check spelling?',lower(name));
end


end

