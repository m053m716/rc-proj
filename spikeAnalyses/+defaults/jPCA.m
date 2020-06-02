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

% % Parse input % %
if nargin < 2
   useConditionLabels = false;
   outcomes = nan;
else
   useConditionLabels = true;
end

if nargin < 3
   score = nan;
end

% % Make parameters output % %
p = struct;

% Main parameters
p.dt = 5; % Sample period (ms) -- resample to this value prior to phase calculation
p.t_lims = [-750 500]; % Time limits under consideration

% For phase difference
p.phase_wlen = 21; % Number of samples around alignment to look for "phase state"
p.phase_s = vertcat({'Reach','Grasp','Support','Complete'},... % Cell array for phase states & index name fields
               {'reachIndex','graspIndex','supportIndex','completeIndex'});
p.phase_pair = 3:-1:1;
            
% Make jPCA params struct
jpca_params = struct;
jpca_params.numPCs = 10;
jpca_params.plane2plot = p.phase_pair; % Can be vector (e.g. 2:-1:1)
jpca_params.wlen = p.phase_wlen;
jpca_params.S = p.phase_s;
jpca_params.rankType = 'varCapt'; % can be 'eig' or 'varCapt'
jpca_params.normalize = false; 
% About jpca_params.softenNorm
% -----------------------------
% We soften the normalization (so weak signals stay small-ish) numbers 
% larger than zero mean soften the norm. The default (10) means that 10 
% spikes per second gets mapped to 0.5,  infinity to 1, and zero to zero.
% Beware that if you are using data that isn't in terms of spikes/s: 
% -> 10 may be a terrible default value!
jpca_params.softenNorm = 10;
jpca_params.histBins = pi*(-1:0.066:1);
jpca_params.meanSubtract = true; 
jpca_params.use_orth = false;
jpca_params.suppressBWrosettes = false;
jpca_params.suppressHistograms = false;
jpca_params.suppressText = false;
jpca_params.plotPlanEllipse = true;
jpca_params.crossCondMean = true;
jpca_params.analyzeTimes = [];
jpca_params.minTimeSamplesToWarn = 5; % Minimum time samples required to 
                                      % throw warning about sample count
jpca_params.tReach  = nan; % (ms)
jpca_params.tGrasp = nan; % (ms)
jpca_params.tSupport = nan; % (ms)
jpca_params.tComplete = nan; % (ms)
jpca_params.useConditionLabels = useConditionLabels;
jpca_params.conditionLabels = outcomes;
jpca_params.score = score;
jpca_params.min_phase_axes_tick_spacing = 0.125; % (radians)
% Returned in order as rows via `cm = getColorMap(4,'event')`:
jpca_params.ReachStateColor =    [     0         0         0];
jpca_params.GraspStateColor =    [0.0523    0.3514    0.2456];
jpca_params.SupportStateColor =  [0.6977    0.3986    0.5044];
jpca_params.CompleteStateColor = [0.7500    0.7500    0.7500];
jpca_params.FigurePosition = [0.15+0.015*randn,0.25,0.3,0.3];
jpca_params.phaseSpaceAx = [];

% Make movie params struct
movie_params = struct;
movie_params.analyzeTimes = [];
movie_params.plane2plot = 1:2;
movie_params.minAvgDP = 0;
movie_params.rankType = 'varCapt'; % can be 'varCapt' or 'eig'
movie_params.trials2plot = 'all';
movie_params.use_pads = true;
movie_params.histBins = pi*(-1:0.1:1);
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
movie_params.minTimeSamplesToWarn = 5;
movie_params.htmp = [];
movie_params.useConditionLabels = useConditionLabels;
movie_params.conditionLabels = outcomes;

% Make axes_params struct
axes_params = struct;
axes_params.start = -1;
axes_params.fin = 1;
axes_params.tickLabels = {'start','fin'};
axes_params.extraLength = 0.55;
axes_params.axisLabel = '';
axes_params.axisOffset = 0;
axes_params.axisOrientation = 'h';
axes_params.invert = 0;
axes_params.tickLengthFactor = 0.01;
axes_params.hAxisLabelOffsetFactor = 4;
axes_params.vAxisLabelOffsetFactor = 4.5;
axes_params.lineThickness = 1.25;
axes_params.lineStyle = '-';
axes_params.borderMarker = 'none';
axes_params.borderMarkerIndices = [1, 2, 3, 4];
axes_params.tickMarker = 'none';
axes_params.tickMarkerIndices = [1,2];
axes_params.color = [0.0 0.0 0.0]; % Black
axes_params.fontSize = 11; % (numerical labels are 1-pt smaller)
axes_params.curAxes = [];
axes_params.curBorder = [];
axes_params.curTicks = [];
axes_params.curLabels = [];
axes_params.curTickLabels = [];

p.jpca_params = jpca_params;
p.movie_params = movie_params;
p.axes_params = axes_params;
p.preview_folder = 'jpca-previews-new';
p.video_export_base = 'jpca-vids-new';
p.jpca_align = 'Grasp';                % 'Grasp' or 'Reach'

% Parameters for `rosette` plots
rosette_params = struct;
rosette_params.XLim = [-3 3];
rosette_params.XColor = 'k';
rosette_params.YLim = [-3 3];
rosette_params.YColor = 'k';
rosette_params.FontName = 'Arial';
rosette_params.FontSize = 16;
rosette_params.FontWeight = 'bold';
rosette_params.AxesLineWidth = 1.5;
rosette_params.LineWidth = 1.75;
rosette_params.WhichPair = 1;
rosette_params.VarCapt = 0;
rosette_params.Figure = [];
rosette_params.FigureColor = 'w';
rosette_params.ReachStateColor = jpca_params.ReachStateColor;
rosette_params.GraspStateColor = jpca_params.GraspStateColor;
rosette_params.SupportStateColor = jpca_params.SupportStateColor;
rosette_params.CompleteStateColor = jpca_params.CompleteStateColor;
rosette_params.FigureNameExpr = 'Rosette: jPCA plane %d';
rosette_params.AxesTitleExpr = 'jPCA plane %d';
rosette_params.FigurePosition =[0.15+0.015*randn,0.25+0.075*randn,0.2,0.3];
rosette_params.FigureUnits = 'Normalized';
rosette_params.zeroCenters = true;
rosette_params.zeroTime = 'Reach';
rosette_params.zeroTimeOffset = 30;
rosette_params.Axes = [];

% Parameters for `arrowMMC` changes
rosette_params.Arrow = struct;
rosette_params.Arrow.BaseSize = 2;
rosette_params.Arrow.Size = 5;
rosette_params.Arrow.FaceColor = [0 0 0];
rosette_params.Arrow.EdgeColor = 'none';
rosette_params.Arrow.FaceAlpha = 0.75;
rosette_params.Arrow.Axes = [];
rosette_params.Arrow.XLim = rosette_params.XLim;
rosette_params.Arrow.YLim = rosette_params.YLim;
rosette_params.Arrow.RoughScale = 0.004; % Empirically determined
rosette_params.Arrow.XVals = [0 -1.5 4.5 -1.5 0];
rosette_params.Arrow.YVals = [0 2 0 -2 0];
rosette_params.Arrow.Group = [];

% Parameters for `circle` changes
rosette_params.Circle = struct;
rosette_params.Circle.Radius = 1;
rosette_params.Circle.Theta = 0; % Rotation (degrees)
rosette_params.Circle.Center = [0,0];
rosette_params.Circle.LineWidth = 1.5;
rosette_params.Circle.Color = [0.6 0.6 0.6];
rosette_params.Circle.NumPoint = 361;
rosette_params.Circle.DisplayName = 'Reach State';
rosette_params.Circle.Tag = 'Ellipse';
rosette_params.Circle.Annotation = 'off'; % 'on' or 'off' (show up in Legend?)
rosette_params.Circle.Axes = rosette_params.Axes;

p.rosette_params = rosette_params;

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