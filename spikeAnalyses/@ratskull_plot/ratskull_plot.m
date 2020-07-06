classdef ratskull_plot < handle
   %RATSKULL_PLOT  Skull plot image for spatial map overlay
   % 
   % obj = ratskull_plot;        % Goes onto current axes
   % obj = ratskull_plot(ax);     
      
   properties(GetAccess = public, SetAccess = public)
      Name        % Name of plot
      Parent      % "Parent" object
      Children    % "Child" graphics of plot
   end
   
   properties (GetAccess = public, SetAccess = private)
      Covariate      % Covariate associated with plot
      Image          % Graphics image object
      Bregma         % Graphics group representing Bregma, stereotaxic 0
      Scale_Compass  % Compass graphics group for showing size scale
   end
   
   properties (GetAccess = public, Hidden = true)
      Listeners   % Listener handle array
      XLim        % X-axis limits (determines scaling)
      YLim        % Y-axis limits (determines scaling)
   end
   
   % Class constructor and overloads
   methods
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
         
         % Assign obj.Parent first
         if nargin == 0
            obj.Parent = gca;
         elseif isa(ax,'matlab.ui.Figure')
            obj.Parent = axes(ax);
         else
            obj.Parent = ax;
         end
         
         % Load defaults for image and create "skull" background
         [CData,XData,YData] = defaults.ratskull_plot(...
            'CData','XData','YData');
         obj.Image = image(obj.Parent,XData,YData,CData,...
            'Tag','Dorsal View of Skull');

         % Add listener to axes and set axes properties
         obj.Listeners = addlistener(obj.Parent,...
            'XLim','PostSet',...
            @obj.handleAxesLimChange);
         obj.Listeners = [obj.Listeners; addlistener(obj.Parent,...
            'YLim','PostSet',...
            @obj.handleAxesLimChange)];
         
         % Set graphics properties 
         setAxProperties(obj);
         setFigProperties(obj);
         
         % Make "Bregma" marker
         buildBregma(obj);
         
         % Make Scale bar/compass
         buildScale(obj);
         
         % Ensure deletion if axes is deleted
         obj.Parent.DeleteFcn = {@(src,evt,o)delete(o),obj};
      end
      
      % Overloaded `delete` method to clean up on destruction
      function delete(obj)
         %DELETE Overloaded `delete` method to clean up on destructor
         %
         %  delete(obj);
         %
         % Ensures that any listener handles, etc. are properly deleted.
         
         if isempty(obj)
            return;
         end
         
         if ~isempty(obj.Children)
            for ii = 1:numel(obj.Children)
               if isvalid(obj.Children(ii))
                  delete(obj.Children(ii));
               end
            end
         end
         
         if ~isempty(obj.Listeners)
            for ii = 1:numel(obj.Listeners)
               if isvalid(obj.Listeners(ii))
                  delete(obj.Listeners(ii));
               end
            end
         end
      end
   end
   
   % Main methods (public access)
   methods (Access = public)
      % Add a scatter plot group to the skull layout plot
      function hgg = addScatterGroup(obj,x,y,sz,c,name,varargin)
         %ADDSCATTERGROUP Add a scatter plot group to the skull layout plot
         %
         %  hgg = addScatterGroup(obj,x,y,sz,c,varargin);
         %
         % Inputs
         %  obj  - ratskull_plot object
         %  x    - X-coordinates of scatter plot objects
         %  y    - Y-coordinates of scatter plot objects
         %  sz   - Size data of scatter plot objects
         %           -> Default size is 30-pt
         %  c    - Color data of scatter plot objects
         %           -> Default color is black
         %  name - Name of scatter group
         %  varargin - Optional 'Name',value scatter parameter argument
         %              pairs
         %
         % Output
         %  hgg  - Graphics hgroup object
         %
         % See also: ratskull_plot
         
         if nargin < 6
            name = 'Group';
         end
         
         if nargin < 5
            c = zeros(numel(x),3); % Default color is black
         end
         
         if nargin < 4
            sz = ones(size(x)) * 30;
         else
            if (numel(sz) == 1) && (numel(sz)~=numel(x))
               sz = ones(size(x)) * sz;
            end
         end
         
         hgg = hggroup(obj.Parent);
         for ii = 1:numel(x)
            scatter(obj,x(ii),y(ii),name,...
                  'MarkerEdgeColor','none',...
                  'MarkerFaceColor','flat',...
                  'SizeData',sz(ii),...
                  'MarkerFaceAlpha',0.6,...
                  'LineWidth',1.5,...
                  'MarkerEdgeAlpha',0.75,...
                  'CData',c(ii,:),...
                  'Tag',sprintf('%s-%03d',name,ii),...
                  'Parent',hgg,...
                  varargin{:});
         end
         obj.Children = [obj.Children; hgg];
         
      end
      
      % Add a scatter plot group to the skull layout plot
      function hgg = addScatterGroup_ICMS(obj,x,y,sz,ICMS)
         %ADDSCATTERGROUP_ICMS Add a scatter plot group to the skull layout plot that uses ICMS for color-code
         %
         %  hgg = addScatterGroup_ICMS(obj,x,y,sz,ICMS);
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
         hgg = hggroup(obj.Parent);
         for ii = 1:numel(x)
            icms = strrep(char(ICMS(ii)),'-','');
            col = icms_key.(icms);
            scatter(obj,x(ii),y(ii),icms,...
                  'MarkerFaceColor',col,...
                  'MarkerFaceAlpha',0.6,...
                  'MarkerEdgeColor','none',...
                  'LineWidth',1.5,...
                  'MarkerEdgeAlpha',0.75,...
                  'SizeData',sz(ii),...
                  'Tag',sprintf('%s-%03d',icms,ii),...
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
         
         
         set(obj.Parent.Parent,'Position',[0.3 0.3 0.2 0.5]);
         set(obj.Parent.Parent,'MenuBar','none');
         set(obj.Parent.Parent,'Toolbar','none');
         tmp = utils.screencapture(obj.Parent.Parent);
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
            MV(:,:,:,ii) = utils.screencapture(obj.Parent.Parent);
         end
      end
      
      % Change the sizes for data on an existing scatter group of electrode channels
      function changeScatterProp(obj,g,varargin)
         %CHANGESCATTERPROP Change sizes for data on an existing scatter group of electrode channels
         %
         %  changeScatterProp(obj,sizeData,groupIdx);
         %
         % Inputs
         %  obj      - ratskull_plot object
         %  g        - Group index
         %  varargin - 'Name',value property pairs for scatter plot
         %
         % Output
         %  -- none -- Simply updates the correct scatter point sizes
         
         if isnumeric(g)
            if numel(g) > 1
               for ii = 1:numel(g)
                  changeScatterProp(obj,g(ii),varargin{:});
               end
               return;
            end
            hChild = obj.Children(g);
         else
            hChild = getScatterGroup(obj,g);
         end
         
         n = numel(hChild.Children);
         idx = find(strcmpi(varargin(1:2:end),'SizeData'),1,'first');
         if ~isempty(idx)         
            sz = varargin{idx+1};
            if isrow(sz)
               sz = sz';
            end
            sz = flipud(sz);
            varargin([idx,idx+1]) = [];
            for ii = 1:n
               hChild.Children(ii).SizeData = sz(ii);
            end
         end
         
         idx = find(strcmpi(varargin(1:2:end),'CData'),1,'first');
         if ~isempty(idx)         
            c = varargin{idx+1};
            if size(c,2)~=3
               c = c';
            end
            c = flipud(c); % To match order
            varargin([idx,idx+1]) = [];
            for ii = 1:n
               hChild.Children(ii).CData = c(ii,:);
            end
         end
         
         if ~isempty(varargin)
            for ii = 1:n
               set(hChild.Children(ii),varargin{:});
            end
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
         
         MV = utils.screencapture(obj.Parent);
      end
      
      % Return scatter group by name
      function hChild = getScatterGroup(obj,groupName)
         %GETSCATTERGROUP  Return scatter group by name (Tag property)
         %
         %  hChild = getScatterGroup(obj,groupName);
         %  
         %  example:
         %  hChild = getScatterGroup(obj,'Electrodes');
         %  -> Return scatter group with name 'Electrodes'
         %  -> If no 'Electrodes' group, then hChild is empty
         %  
         % Inputs
         %  obj       - ratskull_plot object
         %  groupName - char array corresponding to 'Tag' property
         %
         % Output
         %  hChild    - Scatter hggroup object or else empty array
         
         hChild = findobj(obj.Children,'Tag',groupName,'-depth',1);
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
         hgg = hggroup(obj.Parent);
         hscatter = scatter(x,y,...
            'Parent',hgg,...
            'SizeData',p.MarkerSize,...
            'MarkerEdgeColor',p.MarkerEdgeColor,...
            'Marker',p.Marker,...
            'MarkerFaceColor',p.MarkerFaceColor,...
            'MarkerFaceAlpha',p.MarkerFaceAlpha,...
            varargin{:});
         set(hscatter.Parent,...
            'DisplayName',scattername,...
            'Tag',scattername);
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
   
   % Hidden public methods = listener callbacks
   methods (Hidden,Access = public)
      % Change the sizes for data on an existing scatter group of electrode channels
      function changeScatterGroupSizeData(obj,sz,g)
         %CHANGESCATTERGROUPSIZEDATA Change sizes for data on an existing scatter group of electrode channels
         %
         %  changeScatterGroupSizeData(obj,sz,g);
         %  changeScatterGroupSizeData(obj,sz,'groupname');
         %
         % Inputs
         %  obj - ratskull_plot object
         %  sz  - Size data to update (should be upside down with respect
         %           to original channels order)
         %  g   - Group index | char array corresponding to .Name property
         %
         % Output
         %  -- none -- Simply updates the correct scatter point sizes

         hChild = obj.Children(g);
         for ii = 1:numel(sz)
            hChild.Children(ii).SizeData = sz(ii);
         end
         drawnow;
      end
      
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
      
      % Listener function that handles changes in axes limits
      function handleConditionalDelete(obj,~,~)
         %HANDLECONDITIONALDELETE Listener that deletes based on property
         %
         %  handleConditionalDelete(obj,src,evt);
         %
         % Inputs
         %  obj - ratskull_plot object
         %  src - Event source object
         %  evt - Event object
         %
         % Output
         %  -- none -- Handles changes in axes limits
         
         delete(obj);
      end
      
   end
   
   % Private methods for constructing generic graphics objects
   methods (Access = private)
      % Make property struct with graphics object and graphics text label
      function buildBregma(obj)
         %BUILDBREGMA Creates the "bregma" graphics object marker struct
         %
         % buildBregma(obj);
         %
         % Inputs
         %  obj    - ratskull_plot object
         %
         % Output
         %  obj.Bregma - Struct with 'Marker' and 'Label' fields
         
         [bregma_params,font_params] = defaults.ratskull_plot(...
            'Bregma','Font');
         
         bregma.Marker = fill(obj.Parent,...
            bregma_params.X,...
            bregma_params.Y,...
            bregma_params.C,...
            'FaceAlpha',0.6,...
            'EdgeAlpha',0.75,...
            'LineWidth',1.5);
         bregma.Label = text(obj.Parent,...
            bregma_params.Xt,...
            bregma_params.Yt,...
            bregma_params.Text,...
            font_params{:},...
            'VerticalAlignment','bottom',...
            'HorizontalAlignment','right');
         obj.Bregma = bregma;
      end
      
      % Make Scale_Compass property using graphics objects and text labels
      function buildScale(obj)
         %BUILDSCALE Create graphics group for scale compass
         %
         %  buildScale(obj);
         %
         % Inputs
         %  obj               - ratskull_plot object
         %
         % Output
         %  obj.Scale_Compass - Graphics hggroup object
         
         
         Scale = defaults.ratskull_plot('Scale');
         
         scale_compass = hggroup(obj.Parent,'DisplayName',Scale.Name);
         w = Scale.X;
         h = Scale.Y;
         pos = Scale.Pos;
         str = Scale.Up_Str;
         arr_col = Scale.Arrow_Col;
         arr_w = Scale.Arrow_W;
         str_col = Scale.Str_Col;
         
         % Horizontal arrow component
         hh = line(obj.Parent,[pos(1),pos(1)+w],[pos(2),pos(2)],...
            'Parent',scale_compass,...
            'Color',arr_col,...
            'Marker','>',...
            'MarkerIndices',2,...
            'MarkerFaceColor',arr_col,...
            'LineWidth',arr_w);
         hh.Annotation.LegendInformation.IconDisplayStyle = 'off';
         text(obj.Parent,pos(1)+w*1.1,pos(2)+h*0.1,str,...
            'Color',str_col,...
            'FontName','Arial',...
            'FontSize',14,...
            'Parent',scale_compass);
         hv = line(obj.Parent,[pos(1),pos(1)],[pos(2),pos(2)+h],...
            'Parent',scale_compass,...
            'Color',arr_col,...
            'Marker','^',...
            'MarkerIndices',2,...
            'MarkerFaceColor',arr_col,...
            'LineWidth',arr_w);
         hv.Annotation.LegendInformation.IconDisplayStyle = 'off';
         text(obj.Parent,pos(1)+w*0.1,pos(2)+h*1.1,str,...
            'Color',str_col,...
            'FontName','Arial',...
            'FontSize',14,...
            'Parent',scale_compass);
         obj.Scale_Compass = scale_compass;
      end
      
      % Set axes properties in constructor
      function setAxProperties(obj)
         %SETAXPROPERTIES  Set properties of the axes with ratskull_plot
         %
         %  setAxProperties(obj);
         %
         % Inputs
         %  obj         - ratskull_plot object with .Parent initialized
         %
         % Output
         %  obj.Parent  - Updated obj.Parent property (axes)
         
         [obj.Parent.XLim,obj.Parent.YLim] = ...
            defaults.ratskull_plot('XLim','YLim');
         set(obj.Parent,'XTick',[],'YTick',[],...
            'YDir','normal','NextPlot','add');
      end
      
      % Set figure properties in constructor
      function setFigProperties(obj)
         %SETFIGPROPERTIES Set figure properties of ratskull_plot figure
         %
         %  setFigProperties(obj);
         %
         % Inputs
         %  obj - Graphics figure object that contains axes with
         %        ratskull_plot.
         %
         % Output
         %  obj.Parent - Updated obj.Parent property, with its properties
         %               set to defaults for ratskull_plot.
         
         fDef = defaults.ratskull_plot('Fig');
         
         if isempty(get(obj.Parent.Parent,'Name'))
            set(obj.Parent.Parent,'Name',fDef.Name);
         end
         obj.Parent.Parent.Color = fDef.Col;
         obj.Parent.Parent.Units = fDef.Units;
         obj.Parent.Parent.Position = fDef.Pos;
      end
   end
   
end

