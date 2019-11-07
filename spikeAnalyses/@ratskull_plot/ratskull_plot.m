classdef ratskull_plot < handle
   %RATSKULL_PLOT  Graphics object handle
   % 
   % obj = ratskull_plot;        % Goes onto current axes
   % obj = ratskull_plot(ax);    % 
      
   properties(GetAccess = public, SetAccess = public)
      Name
      Children
   end
   
   properties (GetAccess = public, SetAccess = private)
      Figure
      Axes
      Score
      Image
      Bregma
      Scale_Compass
   end
   
   properties (GetAccess = public, Hidden = true)
      XLim
      YLim
   end
   
   properties (Access = private)
      CData
   end
   
   methods (Access = public)
      function obj = ratskull_plot(ax)
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
         
         % Set figure properties
         fig = ratskull_plot.setFigProperties(fig);
         obj.Figure = fig;
         
         % Make "Bregma" marker
         obj.Bregma = ratskull_plot.buildBregma(ax);
         
         % Make Scale bar/compass
         obj.Scale_Compass = ratskull_plot.buildScale_Compass(ax);
      end
      
      % Add a scatter plot group to the skull layout plot
      function hgg = addScatterGroup(obj,x,y,sizeData,ICMS)
         if nargin < 5
            ICMS = categorical(repmat({'O'},numel(x),1));
         end
         
         if nargin < 4
            sizeData = ones(size(x)) * 30;
         else
            if (numel(sizeData) == 1) && (numel(sizeData)~=numel(x))
               sizeData = ones(size(x)) * sizeData;
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
                  'MarkerSize',sizeData(ii),...
                  'Parent',hgg);
         end
         obj.Children = [obj.Children; hgg];
         
      end
      
      % Make the movie frame sequence as a tensor that can then be exported
      % one frame at a time. MV is a nRows x nColumns x 3 (RGB) x nFrames
      % tensor of class uint8.
      function MV = buildMovieFrameSequence(obj,sizeData,scoreData,scoreAx,scoreDays,t_orig_score,orig_score)
         set(obj.Figure,'Position',[0.3 0.3 0.2 0.5]);
         set(obj.Figure,'MenuBar','none');
         set(obj.Figure,'Toolbar','none');
         tmp = utils.screencapture(obj.Figure);
         MV = zeros(size(tmp,1),size(tmp,2),size(tmp,3),size(sizeData,2),...
               class(tmp));
         keepvec = true(size(sizeData,2),1);
         
         if nargin > 3
            obj.Score = struct;
            obj.Score.Axes = scoreAx;
            obj.Score.Axes.NextPlot = 'add';
            ylim(obj.Score.Axes,[0 100]);
            xlim(obj.Score.Axes,[1 31]);
            obj.Score.t = t_orig_score;
            obj.Score.pct = round(orig_score*100);
            ylabel(obj.Score.Axes,'% Successful',...
               'FontName','Arial',...
               'Color','k','FontSize',14);
            xlabel(obj.Score.Axes,'Post-Op Day',...
               'FontName','Arial',...
               'Color','k','FontSize',14);
            obj.Score.Trace = line(obj.Score.Axes,...
               scoreDays,nan(size(scoreDays)),...
               'Color','b',...
               'LineWidth',3,...
               'LineStyle','-');
            obj.Score.OrigPts = scatter(obj.Score.Axes,...
               obj.Score.t,obj.Score.pct,50,...
               'MarkerEdgeColor','b',...
               'MarkerFaceColor','flat',...
               'CData',ones(numel(obj.Score.t),3),...
               'LineWidth',2);
            obj.Score.OrigPts.SizeData = nan(numel(obj.Score.t),1);
            mindiff_scoreDays = false(size(scoreDays));
            for ii = 1:numel(obj.Score.t)
               [~,d] = min(abs(scoreDays - obj.Score.t(ii)));
               mindiff_scoreDays(d) = true;
            end
         end     
         iCount = 0;
         for ii = 1:size(sizeData,2)
            if nargin > 2
               s = round(scoreData(ii)*100);
               title(obj.Axes,...
                  [obj.Name sprintf(' (%g%%)',s)],...
                  'FontName','Arial','FontSize',14,'Color','k');
            end
            if nargin > 3
               obj.Score.Trace.YData(ii) = s;
               if mindiff_scoreDays(ii)
                  iCount = iCount + 1;
%                   obj.Score.OrigPts.YData(iCount) = obj.Score.pct(iCount);
                  obj.Score.OrigPts.SizeData(iCount) = 100;
                  obj.Score.OrigPts.CData(iCount,:) = [1 1 0];
                  if iCount > 1
                     obj.Score.OrigPts.SizeData(iCount-1) = 50;
                     obj.Score.OrigPts.CData(iCount-1,:) = [1 1 1];
                  end
                  drawnow;
               end
            end
            obj.changeScatterGroupSizeData(sizeData(:,ii));
            MV(:,:,:,ii) = utils.screencapture(obj.Figure);
         end
      end
      
      % Change the sizes for data on an existing scatter group of electrode
      % channels
      function changeScatterGroupSizeData(obj,sizeData,groupIdx)
         if nargin < 3
            groupIdx = 1;
         end
         for ii = 1:numel(sizeData)
            obj.Children(groupIdx).Children(ii).SizeData = sizeData(ii);
         end
      end
      
      % MV(:,:,:,fi) = getMovieFrame(obj);
      function MV = getMovieFrame(obj)
         MV = utils.screencapture(obj.Axes);
      end
      
      % Overloads SCATTER method
      function hgg = scatter(obj,x,y,scattername,varargin)
         if nargin < 4
            scattername = defaults.ratskull_plot('Scatter_GroupName');
         end
         
         if numel(obj) > 1
            if iscell(x)
               for ii = 1:numel(obj)
                  scatter(obj(ii),x{ii},y{ii},varargin);
               end
            else
               for ii = 1:numel(obj)
                  scatter(obj(ii),x,y,varargin);
               end
            end
            return;
         end
         
         % Parse variable 'Name' value pairs
         p = defaults.ratskull_plot('Scatter');
         f = fieldnames(p);
         if ~isempty(varargin)
            if (numel(varargin)==1)&&(iscell(varargin{1}))
               varargin = varargin{1};
            end
            for iV = 1:2:numel(varargin)
               % Check that it is a correct property
               if isfield(p,varargin{iV})
                  p.(varargin{iV}) = varargin{iV+1};
               else
                  idx = find(ismember(lower(f),lower(varargin{iV})),1,'first');
                  if isempty(idx)
                     error('%s is not a valid Scatter Property.',varargin{iV});
                  else
                     p.(f{idx}) = varargin{iV+1};
                  end
               end
            end
         end
         
         if isempty(p.Parent)
            hgg = hggroup(obj.Axes,'DisplayName',scattername);
            scatter(obj.Axes,x,y,p.MarkerSize,...
               'MarkerEdgeColor',p.MarkerEdgeColor,...
               'Marker',p.Marker,...
               'MarkerFaceColor',p.MarkerFaceColor,...
               'MarkerFaceAlpha',p.MarkerFaceAlpha,...
               'Parent',hgg);
         else
            scatter(obj.Axes,x,y,p.MarkerSize,...
               'MarkerEdgeColor',p.MarkerEdgeColor,...
               'Marker',p.Marker,...
               'MarkerFaceColor',p.MarkerFaceColor,...
               'MarkerFaceAlpha',p.MarkerFaceAlpha,...
               'Parent',p.Parent);
         end
      end
      
      function setProp(obj,propName,propVal)
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
         setProp(obj,src.Name,evt.AffectedObject.(src.Name));
      end
      
   end
   
   methods (Access = private, Static = true)
      % Make property struct with graphics object and graphics text label
      function bregma = buildBregma(ax)
         bregma.Marker = fill(ax,...
            defaults.ratskull_plot('Bregma_X'),...
            defaults.ratskull_plot('Bregma_Y'),...
            defaults.ratskull_plot('Bregma_C'));
         bregma.Label = text(ax,0,0,'Bregma','FontName','Arial',...
            'Color','k','FontWeight','bold','FontSize',14);
      end
      
      % Make Scale_Compass property using graphics objects and text labels
      function scale_compass = buildScale_Compass(ax)
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
         ax.XLim = defaults.ratskull_plot('XLim');
         ax.YLim = defaults.ratskull_plot('YLim');
         ax.XTick = [];
         ax.YTick = [];
         ax.NextPlot = 'add';
      end
      
      % Set figure properties in constructor
      function fig = setFigProperties(fig)
         if isempty(get(fig,'Name'))
            set(fig,'Name',defaults.ratskull_plot('Fig_Name'));
         end
         fig.Color = defaults.ratskull_plot('Fig_Col');
         fig.Units = defaults.ratskull_plot('Fig_Units');
         fig.Position = defaults.ratskull_plot('Fig_Pos');
      end
   end
   
end

