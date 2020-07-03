classdef ratskull_plot < handle
   %RATSKULL_PLOT  Skull plot image for spatial map overlay
   % 
   % obj = ratskull_plot;        % Goes onto current axes
   % obj = ratskull_plot(ax);     
      
   properties(GetAccess = public, SetAccess = public)
      Name        % Name of plot
      Children    % "Child" graphics of plot
   end
   
   properties (GetAccess = public, SetAccess = private)
      Figure         % Figure handle ("Parent" figure to Axes)
      Axes           % Axes handle ("Parent" axes)
      Covariate      % Covariate associated with plot
      Image          % Graphics image object
      Bregma         % Graphics group representing Bregma, stereotaxic 0
      Scale_Compass  % Compass graphics group for showing size scale
   end
   
   properties (GetAccess = public, Hidden = true)
      XLim  % X-axis limits (determines scaling)
      YLim  % Y-axis limits (determines scaling)
   end
   
   properties (Access = private)
      CData % Image data for actual rat skull image
   end
   
   methods (Access = public)
      % Class constructor
      function obj = ratskull_plot(ax)
         %RATSKULL_PLOT Skull plot image for spatial map overlay
         %
         %  obj = ratskull_plot();
         %  obj = ratskull_plot(ax);
         %
         % Inputs
         %  ax  - Axes object
         %
         % Output
         %  obj - ratskull_plot class object
         
         if nargin == 0
            ax = gca;
            fig = ax.Parent;
         elseif isa(ax,'matlab.ui.Figure')
            fig = ax;
            ax = gca;
         else
            fig = ax.Parent;
         end
         
         obj.Image = matlab.graphics.primitive.Image(ax);
         obj.CData = defaults.ratskull_plot('CData');
         obj.Image.CData = obj.CData;
         obj.Image.XData = defaults.ratskull_plot('XData');
         obj.Image.YData = defaults.ratskull_plot('YData');
         
         % Add listener to axes and set axes properties
         addlistener(ax,'XLim','PostSet',@obj.handleAxesLimChange);
         addlistener(ax,'YLim','PostSet',@obj.handleAxesLimChange);
         ax = ratskull_plot.setAxProperties(ax);
         obj.Image.Parent = ax;
         obj.Axes = ax;
         
%          % Set figure properties
%          fig = ratskull_plot.setFigProperties(fig);
%          obj.Figure = fig;
         
         % Make "Bregma" marker
         obj.Bregma = ratskull_plot.buildBregma(ax);
         
         % Make Scale bar/compass
         obj.Scale_Compass = ratskull_plot.buildScale_Compass(ax);
      end
      
      % Add a scatter plot group to the skull layout plot
      function hgg = addScatterGroup(obj,x,y,sz,ICMS)
         %ADDSCATTERGROUP Add a scatter plot group to the skull layout plot
         %
         %  hgg = addScatterGroup(obj,x,y,sz,ICMS);
         %
         % Inputs
         %  obj  - ratskull_plot object
         %  x    - X-coordinates of scatter plot objects
         %  y    - Y-coordinates of scatter plot objects
         %  sz   - Size data of scatter plot objects
         %  ICMS - ICMS representation of scatter plot objects
         %
         % Output
         %  hgg  - Graphics hgroup object
         %
         % See also: ratskull_plot
         
         if nargin < 5
            ICMS = categorical(repmat({'O'},numel(x),1));
         end
         
         if nargin < 4
            sz = ones(size(x)) * 30;
         else
            if (numel(sz) == 1) && (numel(sz)~=numel(x))
               sz = ones(size(x)) * sz;
            end
         end
         icms_key = defaults.group('skull_icms_key');
         hgg = hggroup(obj.Axes);
         for ii = 1:numel(x)
            icms = strrep(char(ICMS(ii)),'-','');
            col = icms_key.(icms);
            scatter(obj,x(ii),y(ii),icms,...
                  'MarkerFaceColor',col,...
                  'MarkerEdgeColor','none',...
                  'SizeData',sz(ii),...
                  'Parent',hgg);
         end
         obj.Children = [obj.Children; hgg];
         
      end
      
      % Make the movie frame sequence as a tensor that can then be exported
      % one frame at a time. MV is a nRows x nColumns x 3 (RGB) x nFrames
      % tensor of class uint8.
      function MV = buildMovieFrameSequence(obj,t,sz,covAx,cY)
         %BUILDMOVIEFRAMESEQUENCE Make movie frame sequence as tensor
         %
         %  MV = buildMovieFrameSequence(obj,t,sz,covAx,cY);
         %  
         % Inputs
         %  obj   - ratskull_plot object
         %  t     - Time-array corresponding to elements of covariate
         %  sz    - Array of point sizes for spatial data indicator
         %           -> Should be nChannels x nDataPoints
         %  covAx - Axes to put time-series covariate on
         %  cY    - Array of covariate that progresses with time
         %
         % Output
         %  MV    - Tensor that contains all movie frame images to write
         
         
         set(obj.Figure,'Position',[0.3 0.3 0.2 0.5]);
         set(obj.Figure,'MenuBar','none');
         set(obj.Figure,'Toolbar','none');
         tmp = utils.screencapture(obj.Figure);
         MV = zeros(size(tmp,1),size(tmp,2),size(tmp,3),size(sz,2),...
               class(tmp));
         
         if nargin > 4
            obj.Covariate = struct;
            obj.Covariate.Axes = covAx;
            obj.Covariate.Axes.NextPlot = 'add';
            ylim(obj.Covariate.Axes,[0 100]);
            xlim(obj.Covariate.Axes,[1 31]);
            obj.Covariate.t = t_o;
            obj.Covariate.Trace = repmat(...
               line(obj.Covariate.Axes,...
               t,nan(size(t)),...
               'Color','b',...
               'LineWidth',3,...
               'LineStyle','-'),size(cY,1),1);
         end     

         for ii = 1:size(sz,2)
            if nargin > 3
               for iTr = 1:numel(obj.Covariate.Trace)
                  obj.Covariate.Trace(iTr).YData(ii) = cY(iTr,ii);
               end
            end
            obj.changeScatterGroupSizeData(sz(:,ii));
            MV(:,:,:,ii) = utils.screencapture(obj.Figure);
         end
      end
      
      % Change the sizes for data on an existing scatter group of electrode channels
      function changeScatterGroupSizeData(obj,sz,g)
         %CHANGESCATTERGROUPSIZEDATA Change sizes for data on an existing scatter group of electrode channels
         %
         %  changeScatterGroupSizeData(obj,sizeData,groupIdx);
         %
         % Inputs
         %  obj - ratskull_plot object
         %  sz  - Size data to update
         %  g   - Group index
         %
         % Output
         %  -- none -- Simply updates the correct scatter point sizes
         
         if nargin < 3
            g = 1;
         end
         for ii = 1:numel(sz)
            obj.Children(g).Children(ii).SizeData = sz(ii);
         end
         drawnow;
      end
      
      % MV(:,:,:,fi) = getMovieFrame(obj);
      function MV = getMovieFrame(obj)
         %GETMOVIEFRAME Returns a single movie frame capture
         %
         %  MV = getMovieFrame(obj);
         %
         % Inputs
         %  obj - ratskull_plot scalar object
         %
         % Output
         %  MV  - Tensor for image of a single frame capture
         
         MV = utils.screencapture(obj.Axes);
      end
      
      % Overloads SCATTER method
      function hgg = scatter(obj,x,y,scattername,varargin)
         %SCATTER Overloads `scatter` built-in method
         %
         %  hgg = scatter(obj,x,y);
         %  hgg = scatter(obj,x,y,scattername);
         %  hgg = scatter(obj,x,y,scattername,'name',value,...);
         %
         % Inputs
         %  obj         - ratskull_plot class object
         %  x           - X-coordinates for scatter points
         %  y           - Y-coordinates for scatter points
         %  scattername - char or string array of name of scatter group
         %  varargin    - (Optional 'name',value input argument pairs)
         %
         % Output
         %  hgg         - Graphics hgroup object for scatter points
         %
         % See also: ratskull_plot, make.fig, make.fig.skullPlot
         
         if nargin < 4
            scattername = defaults.ratskull_plot('Scatter_GroupName');
         end
         
         if numel(obj) > 1
            if iscell(x)
               for ii = 1:numel(obj)
                  scatter(obj(ii),x{ii},y{ii},scattername,varargin{:});
               end
            else
               for ii = 1:numel(obj)
                  scatter(obj(ii),x,y,scattername,varargin{:});
               end
            end
            return;
         end
         
         % Parse variable 'Name' value pairs
         p = defaults.ratskull_plot('Scatter');         
         if isempty(p.Parent)
            hgg = hggroup(obj.Axes,'DisplayName',scattername);
            scatter(obj.Axes,x,y,...
               'SizeData',p.MarkerSize,...
               'MarkerEdgeColor',p.MarkerEdgeColor,...
               'Marker',p.Marker,...
               'MarkerFaceColor',p.MarkerFaceColor,...
               'MarkerFaceAlpha',p.MarkerFaceAlpha,...
               'Parent',hgg,...
               varargin{:});
         else
            scatter(obj.Axes,x,y,...
               'SizeData',p.MarkerSize,...
               'MarkerEdgeColor',p.MarkerEdgeColor,...
               'Marker',p.Marker,...
               'MarkerFaceColor',p.MarkerFaceColor,...
               'MarkerFaceAlpha',p.MarkerFaceAlpha,...
               'Parent',p.Parent,...
               varargin{:});
         end
      end
      
      % Set properties
      function setProp(obj,propName,propVal)
         %SETPROP Set properties
         %
         %  setProp(obj,propName,propVal);
         %
         % Inputs
         %  obj      - Scalar ratskull_plot object
         %  propName - Cell array or char array of property name to set
         %  propVal  - Values match elements of propName to update
         %
         % Output
         %  -- none -- Updates corresponding properties
         
         % Parse input arrays
         if numel(obj) > 1
            if (numel(propName) > 1) 
               for ii = 1:numel(obj)
                  for iP = 1:numel(propName)
                     setProp(obj(ii),propName{iP},propVal{iP});
                  end
               end
            else
               if numel(propVal)==numel(obj)
                  for ii = 1:numel(obj)
                     setProp(obj(ii),propName,propVal(ii));
                  end
               else
                  for ii = 1:numel(obj)
                     setProp(obj(ii),propName,propVal);
                  end
               end
            end
            return;
         end
         
         % Find the correct property and set it
         if isprop(obj,propName)
            obj.(propName) = propVal;
         else
            p = properties(obj);
            idx = find(ismember(lower(p),lower(propName)),1,'first');
            if isempty(idx)
               return;
            else
               obj.(p{idx}) = propVal;
            end
         end
      end
   end
   
   methods (Access = private)
      % Listener function that handles changes in axes limits
      function handleAxesLimChange(obj,src,evt)
         %HANDLEAXESLIMCHANGE Listener that fires if axes limits change
         %
         %  handleAxesLimChange(obj,src,evt);
         %
         % Inputs
         %  obj - ratskull_plot object
         %  src - Event source object
         %  evt - Event object
         %
         % Output
         %  -- none -- Handles changes in axes limits
         
         setProp(obj,src.Name,evt.AffectedObject.(src.Name));
      end
      
   end
   
   methods (Access = private, Static = true)
      % Make property struct with graphics object and graphics text label
      function bregma = buildBregma(ax)
         %BUILDBREGMA Creates the "bregma" graphics object marker struct
         %
         %  bregma = ratskull_plot.buildBregma(ax);
         %
         % Inputs
         %  ax - Graphics axes object
         %
         % Output
         %  bregma - Struct with 'Marker' and 'Label' fields
         
         bregma.Marker = fill(ax,...
            defaults.ratskull_plot('Bregma_X'),...
            defaults.ratskull_plot('Bregma_Y'),...
            defaults.ratskull_plot('Bregma_C'));
         bregma.Label = text(ax,0,0,'Bregma','FontName','Arial',...
            'Color','k','FontWeight','bold','FontSize',14);
      end
      
      % Make Scale_Compass property using graphics objects and text labels
      function scale_compass = buildScale_Compass(ax)
         %BUILDSCALE_COMPASS Create graphics group for scale compass
         %
         %  scale_compass = ratskull_plot.buildScale_Compoass(ax);
         %
         % Inputs
         %  ax            - Axes object
         %
         % Output
         %  scale_compass - Graphics hggroup object
         
         scale_compass = hggroup(ax,'DisplayName','Compass');
         
         w = defaults.ratskull_plot('Scale_X');
         h = defaults.ratskull_plot('Scale_Y');
         pos = defaults.ratskull_plot('Scale_Pos');
         str = defaults.ratskull_plot('Scale_Up_Str');
%          rStr = defaults.ratskull_plot('Scale_R_Str');
         arr_col = defaults.ratskull_plot('Scale_Arrow_Col');
         arr_w = defaults.ratskull_plot('Scale_Arrow_W');
         str_col = defaults.ratskull_plot('Scale_Str_Col');
         
         % Horizontal arrow component
         hh = line(ax,[pos(1),pos(1)+w],[pos(2),pos(2)],...
            'Parent',scale_compass,...
            'Color',arr_col,...
            'Marker','>',...
            'MarkerIndices',2,...
            'MarkerFaceColor',arr_col,...
            'LineWidth',arr_w);
         th = text(ax,pos(1)+w*1.1,pos(2)+h*0.1,str,...
            'Color',str_col,...
            'FontName','Arial',...
            'FontSize',14,...
            'Parent',scale_compass);
         
         hv = line(ax,[pos(1),pos(1)],[pos(2),pos(2)+h],...
            'Parent',scale_compass,...
            'Color',arr_col,...
            'Marker','^',...
            'MarkerIndices',2,...
            'MarkerFaceColor',arr_col,...
            'LineWidth',arr_w);
         tv = text(ax,pos(1)+w*0.1,pos(2)+h*1.1,str,...
            'Color',str_col,...
            'FontName','Arial',...
            'FontSize',14,...
            'Parent',scale_compass);
         
         
      end
      
      % Set axes properties in constructor
      function ax = setAxProperties(ax)
         %SETAXPROPERTIES  Set properties of the axes with ratskull_plot
         %
         %  ax = ratskull_plot.setAxProperties(ax);
         %
         % Inputs
         %  ax - Axes object that ratskull_plot goes on
         %  varargin - Any `axes` 'name',value pairs
         %
         % Output
         %  ax - Updated version of input
         
         ax.XLim = defaults.ratskull_plot('XLim');
         ax.YLim = defaults.ratskull_plot('YLim');
         ax.XTick = [];
         ax.YTick = [];
         ax.NextPlot = 'add';
      end
      
      % Set figure properties in constructor
      function fig = setFigProperties(fig)
         %SETFIGPROPERTIES Set figure properties of ratskull_plot figure
         %
         %  fig = ratskull_plot.setFigProperties(fig);
         %
         % Inputs
         %  fig - Graphics figure object that contains axes with
         %        ratskull_plot.
         %  varargin - Any 'Figure' 'name',value pairs
         %
         % Output
         %  fig - Same as input with properties set to defaults for
         %        ratskull_plot.
         
         if isempty(get(fig,'Name'))
            set(fig,'Name',defaults.ratskull_plot('Fig_Name'));
         end
         fig.Color = defaults.ratskull_plot('Fig_Col');
         fig.Units = defaults.ratskull_plot('Fig_Units');
         fig.Position = defaults.ratskull_plot('Fig_Pos');
      end
   end
   
end

