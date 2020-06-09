function varargout = jPCA(varargin)
%JPCA Default parameters for jPCA analyses
%
%  param = defaults.jPCA('paramName');
%  [p1,p2,...,pk] = defaults.jPCA('p1','p2','p3',...,'pk');
%
%  Common parameters
%  -> 'jpca_params'    - main parameters struct for analyze.jPCA function
%
%  -> 'movie_params'   - parameters struct for exporting rosette videos
%  -> 'rosette_params' - parameters struct for plotting rosettes
%  -> 'dt'      - Sample period to resample to (via interpolation) for jPCA
%  -> 't_lims'  - [pre post] (ms) relative to alignment (0 ms)
%  -> 'sg_ord'  - Order of savitzky-golay low-pass filter for smoothing
%  -> 'sg_wlen' - Window length of SG LPF for smoothing
%  -> 'interp_method' - Method for interpolating data prior to jPCA

% % Make parameters output % %
p = struct;

% Main parameters
p.dt = 5; % Sample period (ms) -- resample to this value prior to phase calculation
p.t_lims = [-750 500];      % Time limits under consideration
p.dt_short = 2;             % Sample period for "short" timescale analyses
p.t_lims_short = [-250 100];% Short time-bases for multi-plot on individual events 
p.sg_ord = 3;               % Order for Savitzky-Golay low-pass filter (smooth after interp)
p.sg_ord_short = 3;         % Order for short time-basis analyses
p.sg_wlen = 9;              % Length of SG LPF window
p.sg_wlen_short = 5;        % Window length for short time-basis analyses
p.interp_method = 'spline'; % Method for `interp1`
p.min_n_trials_def = 7;     % Minimum # of trials for a day to be included

% For phase difference
p.phase_wlen = 21; % Number of samples around alignment to look for "phase state"
p.phase_s = vertcat({'Reach','Grasp','Support','Complete'},... % Cell array for phase states & index name fields
               {'reachIndex','graspIndex','supportIndex','completeIndex'});
p.phase_pair = 3:-1:1;
            
% Make jPCA params struct
jpca_params = struct;
jpca_params.Alignment = '';
jpca_params.Animal = '';
jpca_params.Day = [];
jpca_params.numPCs = 12;
jpca_params.threshPC = 90; % Determines the number of PCs to use
jpca_params.plane2plot = p.phase_pair; % Can be vector (e.g. 2:-1:1)
jpca_params.wlen = p.phase_wlen;
jpca_params.S = p.phase_s;
jpca_params.rankType = 'eig'; % can be 'eig' or 'varCapt'
jpca_params.normalize = false; 
% About jpca_params.softenNorm
% -----------------------------
% We soften the normalization (so weak signals stay small-ish) numbers 
% larger than zero mean soften the norm. The default (10) means that 10 
% spikes per second gets mapped to 0.5,  infinity to 1, and zero to zero.
% Beware that if you are using data that isn't in terms of spikes/s: 
% -> 10 may be a terrible default value!
jpca_params.softenNorm           = 10;
jpca_params.histBins             = pi*(-1:0.066:1);
jpca_params.suppressPCstem       = false;   % Stem plot of cumulative variance
jpca_params.suppressRosettes     = false;   % Rosette plots of trajectories
jpca_params.suppressHistograms   = false;   % Histograms of binned phase angles
jpca_params.suppressText         = false;   % Suppress reported R^2 info printed to 
jpca_params.batchExportFigs      = false;
jpca_params.plotPlanEllipse      = false;
jpca_params.crossCondMean        = true;
jpca_params.analyzeTimes         = [];
jpca_params.minTimeSamplesToWarn = 5; % Minimum time samples required to 
                                      % throw warning about sample count

jpca_params.tReach  = nan; % (ms)
jpca_params.tGrasp = nan; % (ms)
jpca_params.tSupport = nan; % (ms)
jpca_params.tComplete = nan; % (ms)
jpca_params.planStateEvent = 'tComplete'; % Should be 'tReach' or 'tGrasp' or 'tComplete'
jpca_params.min_phase_axes_tick_spacing = 0.125; % (radians)
% Returned in order as rows via `cm = getColorMap(4,'event')`:
jpca_params.ReachStateColor =    [     0         0         0];
jpca_params.GraspStateColor =    [0.0523    0.3514    0.2456];
jpca_params.SupportStateColor =  [0.6977    0.3986    0.5044];
jpca_params.CompleteStateColor = [0.7500    0.7500    0.7500];
jpca_params.FigurePosition = [0.15+0.015*randn,0.25,0.4,0.4];
jpca_params.phaseSpaceAx = [];
jpca_params.markEachMetaEvent = true;

jpca_params.PCStem.Axes = [];
jpca_params.PCStem.AxesTitleExpr = 'Top %g PCs (%3.2f%% Variance)';
jpca_params.PCStem.Figure = [];
jpca_params.PCStem.FigureColor = [ 1 1 1];
jpca_params.PCStem.FigureTitle = 'jPCA Pre-Processing: PC Variance';
jpca_params.PCStem.FontName = 'Arial';
jpca_params.PCStem.IconDisplayStyle = 'on';
jpca_params.PCStem.LineWidth = 1.5;
jpca_params.PCStem.Marker = 'o';
jpca_params.PCStem.MarkerSize = 10; % point
jpca_params.PCStem.MarkerColor = [ 0.2 0.2 1]; % blue (lighter)
jpca_params.PCStem.StemColor = [   0   0   0]; % black (lines)
jpca_params.PCStem.ThresholdColor = [ 0.1 0.1 0.7]; % blue (darker)
jpca_params.PCStem.FigurePosition = ...
   jpca_params.FigurePosition - [0.05 0.05 0 0];

% Make movie params struct
movie_params = jpca_params; % Copy over, then modify (if needed)
movie_params.arrowGain = 8;
movie_params.arrowAlpha = 0.35;
movie_params.arrowEdgeColor = 'none';
movie_params.arrowSize = 5;
movie_params.arrowGain = 1;
movie_params.arrowMinVel = 0;
movie_params.axLimScale = 1.05;
movie_params.axisSeparation = 0.20;
movie_params.axLim = [-3 3 -3 3];
movie_params.export = false;        % Set true to export movie
movie_params.filename = '';         % If exporting, specifies non-default name for output file
movie_params.fontWeight = 'bold';
movie_params.fontName = 'Arial';
movie_params.fontSize = 16;
movie_params.fs = 30; % Output frames-per-second
movie_params.htmp = [];
movie_params.lineWidth = 2.5;
movie_params.meanColor = [1 0.3 0.3; 0.3 0.3 1]; % For condition-mean traj
movie_params.minTimeSamplesToWarn = 5;
movie_params.pixelSize = [150 150 650 650];
movie_params.pixelsToGet = [25 25 600 600];
movie_params.plane2plot = 1;
movie_params.plotIndividualTrajs = true;
movie_params.plotMeanTrajs = true;
movie_params.plotPlanEllipse = false;
movie_params.stationaryPadStart = 4;
movie_params.stationaryPadEnd = 4;
movie_params.substRawPCs = false;
movie_params.tailAlpha = 0.65;
movie_params.tail = 50; % ms
movie_params.time_match_tol = 0.025; % See `ismembertol` for details
movie_params.times = []; % Force to use Projection(1).times
movie_params.timeIndicator    = []; % Holds text object showing current time
movie_params.titleText_plane  = []; % Holds text object indicating jPC plane
movie_params.titleText_var    = []; % Holds text object indicating % varcapt
movie_params.titleText_score  = []; % Holds text object indicating score
movie_params.trials2plot = 'all';
movie_params.usePads = true;
movie_params.useRot = false;
movie_params.zeroStarts = false;
movie_params.Figure = [];
movie_params.Axes = [];
movie_params.haxP = []; % AxisMMC for horizontal axes
movie_params.vaxP = []; % AxisMMC for vertical axes

% Make axes_params struct
axes_params = struct;
axes_params.axisLabel = '';
axes_params.axisOffset = 0;
axes_params.axisOrientation = 'h';
axes_params.borderColor = [0.0 0.0 0.0]; % Black
axes_params.borderMarker = 'none';
axes_params.borderMarkerIndices = [1, 2, 3, 4];
axes_params.color = [0.0 0.0 0.0]; % Black
axes_params.curAxes = [];
axes_params.curBorder = [];
axes_params.curTicks = [];
axes_params.curLabels = [];
axes_params.curTickLabels = [];
axes_params.extraLength = 0.55;
axes_params.fin = 1;
axes_params.fontSize = 11; % (numerical labels are 1-pt smaller)
axes_params.hAxisLabelOffsetFactor = 4;
axes_params.invert = 0;
axes_params.lineThickness = 1.25;
axes_params.lineStyle = '-';
axes_params.start = -1;
axes_params.tickLabels = {'',''};
axes_params.tickLengthFactor = 0.01;
axes_params.tickMarker = 'none';
axes_params.tickMarkerIndices = [1,2];
axes_params.vAxisLabelOffsetFactor = 4.5;

% Parameters for `rosette` plots
rosette_params = struct;
rosette_params.Animal = '';
rosette_params.Alignment = '';
rosette_params.Axes = [];
rosette_params.AxesLineWidth = 1.5;
rosette_params.AxesTitleExpr = 'jPCA plane %d';
rosette_params.batchExportFigs = false;
rosette_params.Day = [];
rosette_params.Figure = [];
rosette_params.FigureColor = 'w';
rosette_params.FigurePosition =[0.15+0.015*randn,0.25+0.075*randn,0.2,0.3];
rosette_params.FigureUnits = 'Normalized';
rosette_params.FigureNameExpr = 'Rosette: jPCA plane %d';
rosette_params.FontName = 'Arial';
rosette_params.FontSize = 16;
rosette_params.FontWeight = 'bold';
rosette_params.iSource = '';
rosette_params.LineWidth = 1.75;
rosette_params.markEachMetaEvent = true;
rosette_params.tLims = [];
rosette_params.VarCapt = 0;
rosette_params.WhichPair = 1;
rosette_params.XLim = [-3 3];
rosette_params.XColor = 'k';
rosette_params.YLim = [-3 3];
rosette_params.YColor = 'k';
rosette_params.zeroCenters = false;
rosette_params.zeroTime = nan;
rosette_params.zeroTimeOffset = 30;

rosette_params.ReachStateColor = jpca_params.ReachStateColor;
rosette_params.GraspStateColor = jpca_params.GraspStateColor;
rosette_params.SupportStateColor = jpca_params.SupportStateColor;
rosette_params.CompleteStateColor = jpca_params.CompleteStateColor;

% Parameters for `arrowMMC` changes
rosette_params.Arrow = struct;
rosette_params.Arrow.Axes = [];
rosette_params.Arrow.BaseSize = 6;
rosette_params.Arrow.EdgeColor = 'none';
rosette_params.Arrow.FaceColor = [0 0 0];
rosette_params.Arrow.FaceAlpha = 0.75;
rosette_params.Arrow.RoughScale = 0.004; % Empirically determined
rosette_params.Arrow.Size = 5;
rosette_params.Arrow.XLim = rosette_params.XLim;
rosette_params.Arrow.YLim = rosette_params.YLim;
rosette_params.Arrow.XVals = [0 -1.5 4.5 -1.5 0];
rosette_params.Arrow.YVals = [0 2 0 -2 0];
rosette_params.Arrow.Group = [];

% Parameters for `circle` changes
rosette_params.Circle = struct;
rosette_params.Circle.Annotation = 'off'; % 'on' or 'off' (show up in Legend?)
rosette_params.Circle.Axes = rosette_params.Axes;
rosette_params.Circle.Center = [0,0];
rosette_params.Circle.Color = [0.6 0.6 0.6];
rosette_params.Circle.DisplayName = 'Reach State';
rosette_params.Circle.LineWidth = 1.5;
rosette_params.Circle.NumPoint = 361;
rosette_params.Circle.Radius = 1;
rosette_params.Circle.Tag = 'Ellipse';
rosette_params.Circle.Theta = 0; % Rotation (degrees)

% Assign output structs
p.jpca_params = jpca_params;
p.movie_params = movie_params;
p.axes_params = axes_params;
p.rosette_params = rosette_params;
p.rotation_params = rosette_params;
p.rotation_params.totalSteps = 60;

% % Parse Input/Output % %
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