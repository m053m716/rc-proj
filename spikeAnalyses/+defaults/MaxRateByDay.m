function p = MaxRateByDay(params)
%% MAXRATEBYDAY      Default parameters for getting max rate by day

p = struct;
p.KERNEL_W = 0.020;           % Kernel width (seconds)
p.F_ID = 'info.mat';          % info file ID
p.ANIMAL_ANALYSES_DIR = '_analyses';      % dir for output 
p.SPIKE_ANALYSIS_DIR = '_SpikeAnalyses';  % dir with spike analyses
p.RATE_ID = '%s_SpikeRate%03gms.mat';  % ID of file containing smooth rate

p.FIG_UNITS = 'Normalized';      % units for position of figure
p.FIG_POS = [0.1,0.1,0.8,0.8];   % position of figure
p.FIG_COL = 'w';                 % figure color

p.MARKER_SIZE = 7;               % Marker size
p.MARKER_FACE_ALPHA = 0.20;      % Marker face alpha (1 -> opaque; 0 -> transparent)
p.MARKER_EDGE_COL = 'none';      % Marker edge color

p.XLIM = [-0.5 0.50];      % time axis (relative to reach)
p.YLIM = [0 28];           % days axis
p.ZLIM = [-25 50];         % IFR (instaneous firing rate) axis; based on observed data

p.MASK_THRESH = 0.05;         % Percentile to plot (1 -> all); two-tailed

p.VIEW = [25 25];       % [azimuth elevation] for 3D scatter

p.AXES_COL = [0 0 0];   % axes color
p.XGRID = 'on';
p.YGRID = 'off';
p.ZGRID = 'off';

p.FONT = 'Arial';             % Font name
p.FONT_COL = 'k';             % Font color
p.AXES_FONT_SIZE = 14;        % Axes label font size
p.TITLE_FONT_SIZE = 16;       % Subplot title font size
p.XLABEL = 'Time (sec)';      % X-axis label string
p.YLABEL = 'Day';             % Y-axis label string
p.ZLABEL = 'Normalized IFR';  % Z-axis label string


p.SCATTER_TAG = 'Post-Op Day %g'; % Tag of scatter plots

p.FIG_TITLE_STR = '%s: Rates by Day';  % String for figure title
p.TITLE_STR = '%s: Ch-%03g';           % String for subplot titles

p.BATCH = false;              % Is it a batch run?

if nargin > 0
   f = fieldnames(p);
   if ~isstruct(params)
      return;
   elseif isempty(params)
      return;
   end
   
   ff = fieldnames(params);
   for iF = 1:numel(f)
      if ~ismember(f{iF},ff)
         params.(f{iF}) = p.(f{iF});
      elseif isempty(params.(f{iF}))
         params.(f{iF}) = p.(f{iF});
      end
   end
   p = params;
end

end