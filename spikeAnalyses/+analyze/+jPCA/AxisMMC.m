function p = AxisMMC(start, fin, varargin)
%AXISMMC Plots an axis / calibration (modified to remove extra code)
%
% p = analyze.jPCA.AxisMMC(start, fin, axParams)
%
% Inputs
%  start    - Starting value of the axis
%  fin      - Ending value of the axis
%  axParams - Optional structure with one or more of the following fields
%         tickLocations    default =  [start fin]
%            tickLabels    default = {'start',  'fin'}
%    tickLabelLocations    default is the numerical values of the labels themselves
%             longTicks    default is ticks with labels are long
%           extraLength    default = 0.5500  long ticks are this proportion longer
%             axisLabel    default = '' (no label)
%            axisOffset    default = 0
%       axisOrientation    default = 'h' ('h' = horizontal, 'v' = vertical)
%                invert    default = 0 (not inverted)
%            tickLength    default is 1/100 of total figure span
%              -> tickLengthFactor = 1/100
%       tickLabelOffset    default based on tickLength
%       axisLabelOffset    default based on tickLength
%         lineThickness    default = 1.25
%             lineStyle    default = '-'
%          borderMarker    default = 'none'
%   borderMarkerIndices    default = [1,2,3,4]
%                 color    default = 'k'
%              fontSize    default = 11
%               curAxes    default = []  (default is current axes handle)
%             curBorder    default = []  (handle to hggroup for "border")
%              curTicks    default = []  (handle to hggroup for tickmarks)
%         curTickLabels    default = []  (handle to hggroup for ticklabs)
%             curLabels    default = []  (handle to hggroup for ax labels)
%
% Output
%  p        - Struct of parameters to use (mix of supplied & default)
%
%  Note: you can specify all, some, or none of the, struct parameter
%        fields, in any order

% ********* PARSE INPUTS  *******************
axParams_def = defaults.jPCA('axes_params');
if nargin < 3
   axParams = axParams_def;
else
   if isstruct(varargin{1})
      axParams = varargin{1};
      varargin(1) = [];
   else
      axParams = defaults.jPCA('axes_params');
   end
   
   fn = fieldnames(axParams);
   for iArg = 1:2:numel(varargin)
      iField = ismember(lower(fn),lower(varargin{iArg}));
      if sum(iField)==1
         axParams.(fn{iField}) = varargin{iArg+1};
      end
   end
   
   % No error parsing for incorrect input fieldnames 
   %  (just uses default if fields not supplied correctly)
   for iField = 1:numel(fn)
      axParams_def.(fn{iField}) = axParams.(fn{iField});
   end
   axParams = axParams_def;
end
if (nargin < 2) || isempty(fin)
   fin = axParams.fin;
end
if (nargin < 1) || isempty(start)
   start = axParams.start;
end
p = parse_axes_parameters(start,fin,axParams);
% ********** DONE PARSING INPUTS ***************

% DETERMINE APPOPRIATE ALIGNMENT FOR TEXT (based on axis orientation)
p.axesLabelHorizontalAlignment = 'center';  % axis label alignment
if strcmp(p.axisOrientation,'h')  % for horizontal axis
   p.tickLabelHorizontalAlignment = 'center';          % numerical labels alignment
   if p.invert==0                 % For inverted case
      p.axesLabelVerticalAlignment = 'top';
      p.tickLabelVerticalAlignment = 'top';
   else
      p.axesLabelVerticalAlignment = 'bottom';
      p.tickLabelVerticalAlignment = 'bottom';
   end
else                         % for vertical axis
   p.tickLabelVerticalAlignment = 'middle';     % numerical labels alignment
   if p.invert==0
      p.axesLabelVerticalAlignment   = 'bottom';  % axis label alignment
      p.tickLabelHorizontalAlignment = 'right';
   else
      p.axesLabelVerticalAlignment   = 'top';
      p.tickLabelHorizontalAlignment = 'left';
   end
end

% PLOT AXIS LINE
% plot main line with any ending ticks as part of the same line
% (looks better in illustrator that way)
p.axisX = [start, fin];
p.axisY = p.axisOffset * [1, 1];
p = fix_label_tick_offsets(p,start,fin);

if isempty(p.curBorder)
   p.curBorder = hggroup(p.curAxes,...
      'Tag','Axis',...
      'PickableParts','none',...
      'HitTest','off');
end

if p.axisOrientation == 'h'
   h = line(p.curBorder,p.axisX, p.axisY,...
      'Tag','X-Axis',...
      'Color', p.borderColor, ...
      'LineWidth', p.lineThickness,...
      'Marker',p.borderMarker,...
      'LineStyle',p.lineStyle...
      );
else
   h = line(p.curBorder,p.axisY, p.axisX,...
      'Tag','Y-Axis',...
      'Color', p.borderColor, ...
      'LineWidth', p.lineThickness,...
      'Marker',p.borderMarker,...
      'LineStyle',p.lineStyle...
      );
end
% Do not want "border" box to show up in Legend (if present)
h.Annotation.LegendInformation.IconDisplayStyle = 'off'; 
p.curBorder.Annotation.LegendInformation.IconDisplayStyle = 'off';

% PLOT TICKS
if isempty(p.curTicks)
   p.curTicks = hggroup(p.curAxes,...
      'Tag','Ticks',...
      'PickableParts','none',...
      'HitTest','off');
end

% Get all X- and Y- pairings, with Nan inserts to delimit tick marks
% Note: [start, fin] markers already plotted
smallTickLocs = setdiff(p.tickLocations,[start,fin]);
nSmall = numel(smallTickLocs);
smallTickLocs = reshape(smallTickLocs,1,nSmall);
p.tickX = [smallTickLocs; smallTickLocs; nan(1,nSmall)];
len = p.tickLength + ones(1,nSmall) .* (p.tickLength * p.extraLength);
p.tickY = [zeros(1,nSmall); -len; nan(1,nSmall)];
p = fix_tick_marker_indices(p,nSmall);
if strcmp(p.axisOrientation,'h')
   h = line(p.curTicks,p.tickX(:),p.tickY(:),...
      'Color',p.color,...
      'LineWidth',p.lineThickness,...
      'Marker',p.tickMarker,...
      'MarkerIndices',p.tickMarkerIndices(:)); 
else
   h = line(p.curTicks,p.tickY(:),p.tickX(:),...
      'Color',p.color,...
      'LineWidth',p.lineThickness,...
      'Marker',p.tickMarker,...
      'MarkerIndices',p.tickMarkerIndices(:)); 
end
if ~isempty(h)
   h.Annotation.LegendInformation.IconDisplayStyle = 'off';
end
p.curTicks.Annotation.LegendInformation.IconDisplayStyle = 'off';

% ADD TICK LABELS (presumably on the ticks)
if isempty(p.curTickLabels)
   p.curTickLabels = hggroup(p.curAxes,...
      'Tag','TickLabels',...
      'PickableParts','none',...
      'HitTest','off');
end

p.longTickLen = (~isempty(p.longTicks)) * (p.tickLength * p.extraLength);
p.tickLim = p.tickLength + p.longTickLen; % longest tick length
hg = hggroup(p.curTickLabels,'Tag',sprintf('%sTickLabels',p.axisOrientation));
if strcmp(p.axisOrientation,'h')
   X = p.tickLabelLocations;
   Y = ones(1,numel(X)) .* (p.axisOffset - p.tickLim - p.tickLabelOffset);
else
   Y = p.tickLabelLocations;
   X = ones(1,numel(Y)) .* (p.axisOffset - p.tickLim - p.tickLabelOffset);
end

for i = 1:length(p.tickLabelLocations)
   text(p.curTickLabels,X(i),Y(i), p.tickLabels{i}, ...
         'HorizontalAlignment', p.tickLabelHorizontalAlignment, ...
         'VerticalAlignment', p.tickLabelVerticalAlignment, ...
         'FontSize', p.fontSize-1, ...
         'Color', p.color);
end
hg.Annotation.LegendInformation.IconDisplayStyle = 'off';
p.curTickLabels.Annotation.LegendInformation.IconDisplayStyle = 'off';

% PLOT AXIS LABEL
if isempty(p.curLabels)
   p.curLabels = hggroup(p.curAxes,...
      'Tag','Labels',...
      'PickableParts','none',...
      'HitTest','off');
end

x = (start+fin)/2;
y = p.axisOffset - p.tickLim - p.axisLabelOffset;
if strcmp(p.axisOrientation,'h')
   text(p.curLabels,x, y, p.axisLabel,...
      'HorizontalAlignment', p.axesLabelHorizontalAlignment, ...
      'VerticalAlignment', p.axesLabelVerticalAlignment,...
      'FontSize', p.fontSize, ...
      'Color', p.color ...
      ); 
else
   text(p.curLabels,y, x, p.axisLabel,...
      'HorizontalAlignment', p.axesLabelHorizontalAlignment, ...
      'VerticalAlignment', p.axesLabelVerticalAlignment,...
      'FontSize', p.fontSize, ...
      'Color', p.color,...
      'Rotation',90 ...
   );
end
p.curLabels.Annotation.LegendInformation.IconDisplayStyle = 'off';
% % % % End function (helper functions below) % % % %

   % Parse default parameters
   function p = parse_axes_parameters(start,fin,axParams)
      %PARSE_AXES_PARAMETERS Parse input `axParams` struct based on scale
      %
      %  p = parse_axes_parameters(start,fin,axParams);
      %
      %  Inputs
      %   start    - Start of axis
      %   fin      - End of axis
      %   axParams - Struct based on combination of inputs and defaults
      %
      %  Output
      %   p        - Parsed output parameter struct
      
      p = axParams;
      
      % Set tickLocations from "start" and "fin" args
      p.tickLocations = [start, fin];
      
      % Numerical labels for the ticks
      if isfield(axParams, 'tickLabels')
         p.tickLabels = axParams.tickLabels;
      else
         p.tickLabels = cell(size(p.tickLocations));
         for iTick = 1:length(tickLocations)
            % defaults to values based on the tick locations
            p.tickLabels{iTick} = sprintf('%g', p.tickLocations(iTick));
         end
      end
      
      % Get current axes, if not passed as input field
      if isempty(axParams.curAxes)
         axParams.curAxes = gca;
      end
      p.curAxes = axParams.curAxes;
      p.curAxes.NextPlot = 'add';
      
      % Assign "curBorder" (hggroup of lines for axes lines)
      if isempty(axParams.curBorder)
         p.curBorder = findobj(p.curAxes,'Tag','Axis');
      else
         p.curBorder = axParams.curBorder;
      end
      
      % Assign "curTicks" (hggroup of tick markers)
      if isempty(axParams.curTicks)
         p.curTicks = findobj(p.curAxes,'Tag','Ticks');
      else
         p.curTicks = axParams.curTicks;
      end
      
      % Assign "curTickLabels" (hggroup of tick label texts)
      if isempty(axParams.curTickLabels)
         p.curTickLabels = findobj(p.curAxes,'Tag','TickLabels');
      else
         p.curTickLabels = axParams.curTickLabels;
      end
      
      % Assign "curLabels" (hggroup of axes label texts)
      if isempty(axParams.curLabels)
         p.curLabels = findobj(p.curAxes,'Tag','Labels');
      else
         p.curLabels = axParams.curLabels;
      end
      
      % Locations of the numerical labels
      if isfield(axParams, 'tickLabelLocations')
         p.tickLabelLocations = axParams.tickLabelLocations;
      else
         p.tickLabelLocations = nan(size(p.tickLabels));
         for iTick = 1:length(p.tickLabels)
            % defaults to the values specified by the labels themselves
            p.tickLabelLocations(iTick) = p.tickLocations(iTick);
         end
      end
      
      % Any long ticks
      if isfield(axParams, 'longTicks')
         p.longTicks = axParams.longTicks;  % these are the locations (must be a subset of the above)
%          if any(~ismember(p.longTicks,p.tickLocations))
%             warning(['JPCA:' mfilename ':InvalidParameter'],...
%                ['\n\t->\t<strong>[JPCA AXES DEFAULTS]:</strong> ' ...
%                'One or more elements of axParams.<strong>longTicks</strong> '...
%                'does not exist. This probably does not matter.\n']);
%          end
      else
         % default is labels get long ticks
         p.longTicks = p.tickLabelLocations;
      end
      
      % Length of the long ticks
      p.extraLength = axParams.extraLength;
      
      % axis label (e.g. 'spikes/s')
      p.axisLabel = axParams.axisLabel;
      
      % Axis offset (vertical for a horizontal axis, and vice versa)
      p.axisOffset = axParams.axisOffset;
      
      % choose horizontal or vertical axis
      if isempty(axParams.axisOrientation)
         p.axisOrientation = 'v';
      else
         p.axisOrientation = lower(axParams.axisOrientation(1));
         if p.axisOrientation ~= 'h'
            p.axisOrientation = 'v';
         end
      end
      
      % normal or inverted axis (inverted = top for horizontal, rhs for vertical)
      p.invert = axParams.invert;
      
      % length of ticks
      if isfield(axParams, 'tickLength')
         p.tickLength = axParams.tickLength;
      else
         % default values based on 'actual' axis size of figure
         axLim = axis(axParams.curAxes);
         if p.axisOrientation == 'h'
            % Horizontal axes: scale tick length by "height" (y-limits)
            p.tickLength = abs(axLim(4)-axLim(3)) * axParams.tickLengthFactor;
         else
            % Vertical axes: scale tick length by "width" (x-limits)
            p.tickLength = abs(axLim(2)-axLim(1)) * axParams.tickLengthFactor;
         end
      end
      
      % make negative if axis is inverted
      if p.invert == 1
         p.tickLength = -tickLength;
      end
      
      % offset of numerical tick labels from the ticks
      % (vertical offset if using a horizontal axis)
      if isfield(axParams, 'tickLabelOffset')
         p.tickLabelOffset = axParams.tickLabelOffset;
      else
         p.tickLabelOffset = p.tickLength/2;
      end
      
      % offset of axis label
      if isfield(axParams, 'axisLabelOffset')
         p.axisLabelOffset = axParams.axisLabelOffset;
      else
         if strcmp(p.axisOrientation,'h')
            p.axisLabelOffset = p.tickLength * axParams.hAxisLabelOffsetFactor;
         else
            p.axisLabelOffset = p.tickLength * axParams.vAxisLabelOffsetFactor;
         end
      end
      
      % line thickness (default: 1.25)
      p.lineThickness = axParams.lineThickness;
      
      % line style (default: '-')
      p.lineStyle = axParams.lineStyle;
      
      % "border marker" (default: 'none')
      p.borderMarker = axParams.borderMarker;
      
      % "border marker" indices (default: [1,2,3,4])
      p.borderMarkerIndices = axParams.borderMarkerIndices;
      
      % color (default: black)
      p.color = axParams.color;
      
      % font size (11-pt; numerical labels are 1-pt smaller)
      p.fontSize = axParams.fontSize;
   end

   % Fix label tick size offsets
   function p = fix_label_tick_offsets(p,varargin)
      %FIX_LABEL_TICK_OFFSETS Fix axis limits based on tick mark lengths
      %
      %  p = fix_label_tick_OFFSETS(p,arg1,arg2,...);
      %  
      %  Inputs
      %     p        -  Parameters struct for axes parameters (`outParams`)
      %     varargin -  e.g. `start` and `fin` or other labels
      %
      %  Output
      %     p        -  Same as input, but with updated fields:
      %                 * `p.axisX`
      %                 * `p.axisY`
      %  They are fixed so that the limits don't "collide" and data doesn't
      %  overlap with tick marks
      
      for iV = 1:numel(varargin)
         thisLab = varargin{iV};
         if ismember(thisLab, p.tickLocations)
            longTickPresent = ismember(thisLab, p.longTicks);
            extra = p.tickLength * p.extraLength * longTickPresent;
            l = p.tickLength + extra;
            p.axisX = [thisLab, p.axisX];
            if iV == 1
               p.axisY = [p.axisY(1)-l,p.axisY];
            else
               p.axisY = [p.axisY,p.axisY(end)-l];
            end
         end
      end
   end

   % Fix tick marker locations
   function p = fix_tick_marker_indices(axP,nSmall)
      %FIX_TICK_MARKER_INDICES Fixes tick marker indexing parameter
      %
      %  p = fix_tick_marker_indices(axP,nSmall);
      %
      %  Inputs
      %     axP    - Original parameters struct
      %     nSmall - Number of small tick marks
      %
      %  Output
      %     p      - Updated parameters struct with correct Marker Indices
      
      p = axP;
      p.tickMarkerIndices = ...
         reshape(axP.tickMarkerIndices,numel(axP.tickMarkerIndices),1);
      offset = (0:3:(3*(nSmall-1)))';
      if size(offset,1)==size(p.tickMarkerIndices,1)
         p.tickMarkerIndices = p.tickMarkerIndices + offset;
      end
      p.tickMarkerIndices = p.tickMarkerIndices(:);
   end

end

