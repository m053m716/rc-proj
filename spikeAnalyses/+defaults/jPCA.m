function param = jPCA(name,outcomes,score)
%JPCA Default parameters for jPCA analyses
%
%  param = DEFAULTS.JPCA(name);
%  param = DEFAULTS.JPCA(name,outcomes,score);
%
%  -> 'jpca_params'
%  -> 'movie_params'
%  -> 'analyze_times'
%  -> 'jpca_align'

%MAKE PARAMS OUTPUT
p = struct;

% Make jPCA params struct
jpca_params = struct;


% jpca_params.optimization_options = defaults.block('optimization_options');
jpca_params.numPCs = 6;
jpca_params.rankType = 'varCapt'; % can be 'eig' or 'varCapt'
jpca_params.normalize = false; 
jpca_params.softenNorm = 10;
jpca_params.meanSubtract = false; 
jpca_params.use_orth = false;
jpca_params.suppressBWrosettes = true;
jpca_params.suppressHistograms = true;
jpca_params.suppressText = false;
jpca_params.plotPlanEllipse = false;
jpca_params.zeroCenters = false;
jpca_params.zeroTime = 0;
jpca_params.crossCondMean = true;
if nargin < 2
   jpca_params.useConditionLabels = false;
   jpca_params.outcomes = nan;
else
   jpca_params.useConditionLabels = true;
   jpca_params.conditionLabels = outcomes;
   jpca_params.outcomes = outcomes;
end
if nargin < 3
   jpca_params.score = nan;
else
   jpca_params.score = score;
end

% Make movie params struct
movie_params = struct;
movie_params.plane2plot = 1:2;
% movie_params.plane2plot = 1;
movie_params.minAvgDP = 0;
movie_params.rankType = 'varCapt'; % can be 'varCapt' or 'eig'
movie_params.trials2plot = 'all';
movie_params.use_pads = true;
% movie_params.arrowGain = 25;
movie_params.arrowGain = 8;
movie_params.arrowAlpha = nan;
movie_params.use_orth = false;
movie_params.arrowEdgeColor = 'k';
movie_params.tailAlpha = nan;
movie_params.tail = 100; % ms
movie_params.lineWidth = 2.5;
movie_params.plotPlanEllipse = false;
movie_params.planMarkerSize = 0;
movie_params.arrowSize = 3.3;
movie_params.crossCondMean = false;
movie_params.zeroStarts = false;
movie_params.htmp = [];
if nargin < 2
   movie_params.useConditionLabels = false;
   movie_params.outcomes = nan;
else
   movie_params.useConditionLabels = true;
   movie_params.conditionLabels = outcomes;
   movie_params.outcomes = outcomes;
end
if nargin < 3
   movie_params.score = nan;
else
   movie_params.score = score;
end

p.jpca_params = jpca_params;
p.movie_params = movie_params;
p.analyze_times = [];
% p.analyze_times = -750:500; % ms
% p.analyze_times = -200:200; % ms
% p.analyze_times = -1200:500; % ms
p.preview_folder = 'jpca-previews-new';
p.video_export_base = 'jpca-vids-new';
p.jpca_align = 'Grasp';                % 'Grasp' or 'Reach'
p.jpca_decimation_factor = nan;
% p.jpca_decimation_factor = 10;         % how much to down-sample
p.jpca_start_stop_times = [-750 500]; % ms
% p.jpca_start_stop_times = [-200 200]; % ms
% p.jpca_start_stop_times = [-1200 500]; % ms
% p.run_jpca_on_construction = true;
p.run_jpca_on_construction = false;

p.ord = 4;
p.fc =  nan; % Hz
p.fs = (1/(defaults.block('spike_bin_w')*1e-3))/defaults.block('r_ds');
if ~isnan(p.fc)
   [p.b,p.a] = butter(p.ord,p.fc/(p.fs/2),'low'); % lowpass filter
else
   p.b = nan;
   p.a = nan;
end

p.rosette_xlim = [-40 40];
p.rosette_ylim = [-40 40];
p.rosette_fontname = 'Arial';
p.rosette_fontsize = 16;
p.rosette_fontweight = 'bold';

% PARSE OUTPUT
if nargin > 0
   if ismember(lower(name),fieldnames(p))
      param = p.(lower(name));
   else
      error('%s is not a valid parameter. Check spelling?',lower(name));
   end
else
   param = p;
end


end