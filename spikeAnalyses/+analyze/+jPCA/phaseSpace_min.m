function params = phaseSpace_min(Projection,varargin)
%PHASESPACE_MIN  "Minimized" version of phaseSpace
%
%  analyze.jPCA.phaseSpace_min(Projection)
%  params = analyze.jPCA.phaseSpace_min(Projection,params)
%  params = analyze.jPCA.phaseSpace_min(Projection,'Name',val,...)
%  params = analyze.jPCA.phaseSpace_min(__,params,'Name',val,...)
%
% Inputs
%  Projection - Struct array of projections and metadata
%                 -> Returned by `analyze.jPCA.jPCA`
%  params     - Parameters struct with the following fields:
%       .times 
%        -> These override the default times. 
%        -> If empty, the defaults are used.
%           * This is nice for movies as the scaling won't change as a 
%              function of the times you plot.
%       .plane2plot   
%        -> list of the jPC planes you want plotted.  
%        -> Default is [1].  [1,2] would also be reasonable.
%       .arrowSize        
%        -> The default is 5
%       .arrowGain        
%        -> FOR MOVIES: sets velocity dependence of arrow size 
%        -> (0 to not grow when faster).
%       .plotPlanEllipse  
%        -> Controls whether the ellipse is plotted.  The default is 'true'
%       .useAxes          
%        -> whether axes should be plotted.  Default is 'true'
%       .lineWidth        
%        -> width of the trajectories.  Default is 0.85.
%       .arrowMinVel      
%        -> minimum velocity for plotting an arrow.
%       .rankType         
%        -> default is 'eig', but you can override with 'varCapt'
%       .conds2plot       
%        -> which conditions to plot 
%        --> (scalings will still be based on conds in 'Projection')
%       .substRawPCs      
%        -> If true, use PC projections rather than jPC projections
%       .crossCondMean    
%        -> if true, plot the cross condition mean in cyan.
%       .Axes
%        -> If non-empty, sets the axes to plot on
%
% Output
%  params - Same as input `params` struct, but updated to reflect
%           parameters that were estimated from the data during
%           `analyze.jPCA.phaseSpace`
%
%  See Also:   analyze.jPCA, analyze.jPCA.jPCA, analyze.jPCA.multi_jPCA,
%              analyze.jPCA.phaseSpace, make.exportSkullPlotMovie

% Check input arguments:
if nargin < 2
   params = defaults.jPCA('movie_params');
else
   if isstruct(varargin{1})
      params = varargin{1};
      varargin(1) = [];
   else
      params = defaults.jPCA('movie_params');
   end
end

% Parse any optional parameter 'Name',value pairs:
fn = fieldnames(params);
for iV = 1:2:numel(varargin)
   iField = ismember(lower(fn),lower(varargin{iV}));
   if sum(iField)==1
      params.(fn{iField}) = varargin{iV+1};
   end
end

% Iterate for multiple planes if needed:
if numel(params.plane2plot) > 1
   pSub = params;
   for ii = 1:numel(params.plane2plot)
      pSub.plane2plot = params.plane2plot(ii);
      analyze.jPCA.phaseSpace_min(Projection,pSub);
   end
   return;
end

% If no figure was explicitly given, create a new figure:
if isempty(params.Figure) 
   if isempty(params.Axes)
      [params.Figure,params.Axes] = ...
         analyze.jPCA.blankFigure(...
            params.axLim,...
            'Units','Pixels',...
            'Position',params.pixelSize);
   else
      params.Figure = get(params.Axes,'Parent');
   end
end

% Define parameters for retrieval array function:
pars = getSubParameters(Projection(1),params);

% Define retrieval function that can be extended using `arrayfun`:
fcn = @(Proj)getTrajectory(Proj,pars);

% Remove existing graphics from axes:
clearExistingTrajectories(params.Axes); 

% Return formatted X,Y and color data for plotting individual trial trajs:
[X,Y,C] = arrayfun(@(P)fcn(P),Projection);

% Add trajectories to axes:
addTrajectories(params.Axes,X,Y,C,pars);

% Add central "scaling" cross to axes:
addCentralCross(params.Axes);

% Add labels (if needed), and return updated parameters struct:
params = addLabels(params);

   % Helper: add central "scale" cross to axes
   function addCentralCross(ax)
      %ADDCENTRALCROSS Add central "cross" indicator to axes
      %
      %  addCentralCross(ax);
      %
      % Inputs
      %  ax - Axes to add the "cross" indicator to
      %
      % Output
      %  -- none -- Just adds the indicator "cross" to the axes.
      
      xC = [0;0.25;0;0   ;0;-0.25;0;0    ;0];
      yC = [0;   0;0;0.25;0;    0;0;-0.25;0];
      cC = [-40;0;40;0;-40;0;40;0;-40];
      patch(ax,xC,yC,cC,...
         'EdgeColor','interp',...
         'LineWidth',1.5,...
         'FaceColor','interp',...
         'Tag','Marker');  % plot a central cross
   end

   % Helper: add labels to axes
   function params = addLabels(params)
      %ADDLABELS Add labels (titles) to axes, if needed
      %
      %  params = addLabels(params);
      %
      % Inputs
      %  params - Parameters struct
      %
      % Output
      %  params - Parameters struct with updated `titleText_plane` field
      
      if strcmpi(params.rankType,'eig')
         strRank = '(by Eigenvalue)';
      else
         strRank = '(by R^2)';
      end
      titleText = sprintf(...
         'jPCA plane %d %s\n %s - %s - Day-%02d (%s) ', ...
         params.plane2plot,strRank,...
         params.Animal,params.Alignment,params.Day,params.Area);
      if isempty(params.titleText_plane)
         params.titleText_plane = ...
            text(params.Axes,0,0.99*params.axLim(4),titleText, ...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom',...
            'Color','w',...
            'FontSize',16,...
            'FontWeight','bold',...
            'FontName',params.fontName);
      end
   end

   % Helper: plot the recovered trajectories
   function addTrajectories(ax,X,Y,C,pars)
      %ADDTRAJECTORIES Add the actual trajectories to phase space
      %
      %  addTrajectories(ax,X,Y,C,pars);
      %     Note: X,Y,C are matching number of rows, columns are matched
      %           trajectories. The trajectories include the "arrow"
      %           coordinates as well. Each trajectory is its own cell.
      %
      % Inputs
      %  ax        - Axes to add trajectories to
      %  X         - Cells with X-coordinates of trajectories (column vecs)
      %  Y         - Cells with Y-coordinates of trajectories (column vecs)
      %  C         - Cells with Color value mappings (column vectors)
      %  tailAlpha - Alpha value for trajectory tails
      %
      % Output
      %  -- none -- Adds the formatted trajectory patches
      
      X = cell2mat(X);
      Y = cell2mat(Y);
      C = cell2mat(C);
      if ~isempty(pars.hl)
         offset = zeros(1,size(C,2));
         offset(pars.hl) = pars.hl_o;
         C = C + offset;
      end
      patch(ax,X,Y,C,...
         'FaceColor','interp',...
         'FaceAlpha',pars.tailAlpha*0.8,...
         'EdgeColor','interp',...
         'EdgeAlpha',pars.tailAlpha,...
         'LineStyle','-',...
         'LineWidth',0.5,...
         'Tag','Trajectory');
      
   end
   
   % Helper: remove old trajectories from axes
   function clearExistingTrajectories(ax)
      %CLEAREXISTINGTRAJECTORIES  Remove trajectory graphics from axes
      %
      %  clearExistingTrajectories(ax);
      %
      % Inputs
      %  ax - Axes to add new trajectories to (and old ones removed)
      %
      % Output
      %  -- none -- Simply removes the unwanted existing graphics
      
      allTraj = findobj(ax,'Tag','Trajectory');
      allMarker = findobj(ax,'Tag','Marker');
      delete(allTraj);
      delete(allMarker);
   end

   % Helper: get trajectory coordinates from data struct array
   function [X,Y,C] = getTrajectory(Proj,pars)
      %GETTRAJECTORY Return trajectory segment from struct array
      %
      % [X,Y,C] = getTrajectory(Proj,pars);
      %
      % Inputs
      %  Proj   - Element of struct array that is main input to 
      %                 `phaseSpace` with fields `.proj` and `.times`
      %  pars   - Parameters struct that contains:
      %           -> ts     : Times (ms) to save
      %           -> d1     : Index of "X" trajectory dimension
      %           -> d2     : Index of "Y" trajectory dimension
      %           -> pField : Field name to actually plot
      %           -> hl     : Trial(s) to highlight (or empty array)
      %           -> hl_o   : Offset to add to color mapping of "highlight"
      %
      % Output
      %  X         - Cell containing column vector of X-coordinates to plot
      %  Y         - Cell containing column vector of Y-coordinates to plot
      %  C         - Cell containing time vector for shading from colormap
      
      iKeep = ismember(Proj.(pars.tField),pars.ts);

      x = Proj.(pars.pField)(iKeep,pars.d1);
      y = Proj.(pars.pField)(iKeep,pars.d2);

      cdata = (1:sum(iKeep));
      cdata = (cdata .* (Proj.Outcome-1.5) .* 2).';
      
      penultimatePoint = [x(end-1), y(end-1)];
      lastPoint = [x(end), y(end)];
      [xA,yA] = analyze.jPCA.getArrowXY(penultimatePoint,lastPoint,[]);
      X = {[x+pars.trajWidth; xA; flipud(x-pars.trajWidth)]};
      Y = {[y; yA; flipud(y)]};
      C = {[cdata; ones(numel(xA),1).*cdata(end).*1.1; flipud(cdata)]};
      
   end

   % Helper: get reduced (relevant) parameters struct
   function pars = getSubParameters(p,params)
      %GETSUBPARAMETERS Get reduced (relevant) parameters struct
      %
      %  pars = getSubParameters(p,params);
      %
      % Inputs
      %  p      - Single element from main struct array input `Proj`
      %  params - Full parameters struct
      %
      % Output
      %  pars   - Reduced parameters struct for arrayfun function
      
      if ~isfield(params,'pIdx')
         pIdx = p.misc.(params.projType).explained.sort.plane.(lower(params.rankType))(params.plane2plot);
      else
         pIdx = params.pIdx;
      end
      pars = struct('ts',params.times,...
              'tField',params.timeField,...
              'pField',params.projField,...
              'd1',2*(pIdx-1)+1,... % jPC-1
              'd2',2*pIdx,...       % jPC-2
              'hl',params.highlight_trial,...
              'hl_o',params.highlight_offset,...
              'tailAlpha',params.tailAlpha,...
              'trajWidth',params.trajWidth);
   end
end 