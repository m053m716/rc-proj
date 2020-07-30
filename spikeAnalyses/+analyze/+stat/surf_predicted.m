function [fig,ax,h] = surf_predicted(glme,var1,var2,varargin)
%SURF_PREDICTED Visualize model prediction surface w.r.t. 2 variables
%
%  [fig,ax,h] = analyze.stat.surf_predicted(glme,var1,var2);
%  [..] = analyze.stat.surf_predicted(__,'Name',value,...);
%
% Inputs
%  glme     - Generalized Linear Mixed-Effects Model
%  var1     - First variable name or index (from glme expression)
%  var2     - Second variable name (from glme expression)
%  varargin - (Optional) Parameter 'Name',value input argument pairs
%            * 'ConditionalType' : 'none' | 'absolute' (def) | 'centered'
%            * 'Figure'          : [] (def) | handle to figure
%            * 'Axes'            : [] (def) | handle to axes
%            * 'ExtraPDPArgs'    : {} (def) | Cell array of 'Name',value
%                                         optional arguments for Matlab
%                                         plotPartialDependence from
%                                         Statistics and Machine Learning
%                                         Toolbox function.
%            * 'Tag'             : '' (def) | Appended to title string
%
% Output
%  fig      - Handle to generated figure
%  ax       - Handle to generated axes
%  h        - Handle to `patch` object generated in figure
%
% See also: analyze, analyze.stat, analyze.stat.surf_partial_dependence

pars                                = struct;
pars.AddObservations                = true;
pars.AlphaData                      = 0.6;
pars.Axes                           = [];
pars.Box                            = 'off';
pars.ConditionalType                = 'absolute';
pars.EdgeColor                      = [0.0 0.0 0.0];
pars.ExtraPDPArgs                   = {};
pars.FaceColor                      = [0.6 0.6 0.6];
pars.Figure                         = [];
pars.Jitter                         = 0.05;
pars.LineWidth                      = 1.5;
pars.Marker                         = 'o';
pars.MarkerSize                     = 10;
pars.MarkerFaceColor                = [0.6 0.6 0.6];
pars.MarkerEdgeColor                = [0.0 0.0 0.0];
pars.MaxObservations                = 1000;   % Max # obs to plot per "slice"
pars.MaxObservationSize             = 36; % Maximum marker size
pars.MinObservationSize             = 8;  % Minimum marker size
pars.ObservationColor               = [0.0 0.0 0.0];
pars.ObservationLineWidth           = 2;
pars.ObservationLineStyle           = ':';
pars.ObservationMarker              = 's';
pars.ObservationMarkerFaceColor     = [0.2 0.2 0.8];
pars.ObservationMarkerEdgeColor     = 'none';
pars.ObservationMarkerSize          = 12;
pars.Tag                            = '';
pars.TextPlaneOffsetFraction        = 0.05;
pars.TextVerticalOffsetFraction     = 0.15;
pars.ZLim                           = [];

fn = fieldnames(pars);
if numel(varargin) > 0
   if isstruct(varargin{1})
      pars = varargin{1};
      varargin(1) = [];
   end
end
for iV = 1:2:numel(varargin)
   idx = strcmpi(fn,varargin{iV});
   if sum(idx)==1
      pars.(fn{idx}) = varargin{iV+1};
   end
end

if isempty(pars.Figure)
   if isempty(pars.Axes)
      fig = figure('Name','Model Response Surface',...
         'Units','Normalized',...
         'Position',[0.3 0.3 0.4 0.4],...
         'Color','w',...
         'NumberTitle','off');
   else
      fig = get(pars.Axes,'Parent');
   end
else
   fig = pars.Figure;
end

if isempty(pars.Axes)
   ax = axes(fig,...
      'XColor','r',...
      'YColor','b',...
      'ZColor','k',...
      'ALim',[0 1],...
      'NextPlot','add',...
      'LineWidth',1.5,...
      'FontName','Arial',...
      'ZGrid','on',...
      'XMinorGrid','on',...
      'YMinorGrid','on',...
      'Box',pars.Box);
else
   ax = pars.Axes;
end

% Get variable names
if isnumeric(var1)
   var1 = glme.VariableNames{var1};
elseif ischar(var1)
   var1 = {var1};
end
if isempty(var2)
   v = var1;
   viewMode = 2;
else
   pars.ConditionalType = 'none'; % Can't do absolute or centered for 2 in
   viewMode = 3;
   if isnumeric(var2)
      var2 = glme.VariableNames{var2};
   elseif ischar(var2)
      var2 = {var2};
   end
   v = [var1, var2];
end

S = glme.Variables(~glme.ObservationInfo.Excluded,:);
pred = predict(glme);
pred = pred(~glme.ObservationInfo.Excluded); % Predicted response

% Make plot
switch numel(v)
   case 1
      if isempty(pars.Tag)
         name = sprintf('Model Conditional Predictions: %s',v{1});
      else
         name = sprintf('Model Conditional Predicitons: %s (%s)',v{1},pars.Tag);
      end
      x = unique(S.(v{1}));
      y_obs = nan(numel(x),1);
      y_pred = nan(numel(x),1);
      for iX = 1:numel(x)
         iResp = S.(v{1})==x(iX);
         y_obs(iX) = mean(S.(glme.ResponseName)(iResp));
         y_pred(iX) = pred(iResp);
      end
      
%       % Set initial axes y-scale
%       mY = median(pred);
%       rY = 0.66*iqr(pred);
%       set(ax,'YLim',[mY-rY mY+rY]);
      
      error('Not added yet.');

      % Update axes properties
      dX = range(ax.XLim)*pars.TextPlaneOffsetFraction;
      dY = range(ax.YLim)*pars.TextVerticalOffsetFraction;
      set(ax,...
         'XLim',[ax.XLim(1)-2*dX,ax.XLim(2)+2*dX],...
         'YLim',[ax.YLim(1)-2*dY,ax.YLim(2)+2*dY],...
         'XTick',double(x),...
         'XTickLabel',string(x));
   case 2
      if isempty(pars.Tag)
         name = sprintf('Model Predictions: %s & %s',v{1},v{2});
      else
         name = sprintf('Model Predictions: %s & %s (%s)',...
            v{1},v{2},pars.Tag);
      end
      
%       % Set initial axes z-scale
%       mZ = median(pred);
%       rZ = 0.66*iqr(pred);
%       set(ax,'ZLim',[mZ-rZ mZ+rZ]);
      if numel(pars.ZLim)==2
         set(ax,'ZLim',pars.ZLim);
      end
      
      x = unique(S.(v{1}));
      y = unique(S.(v{2}));
      [Xc,Yc] = meshgrid(x,y);
      [X,Y] = meshgrid(double(x),double(y));
      Z_O = nan(size(X));
      Z_P = nan(size(X));

      for iX = 1:numel(X)
         iResp = (S.(v{1})==Xc(iX)) & (S.(v{2})==Yc(iX));
         Z_O(iX) = nanmean(S.(glme.ResponseName)(iResp));
         Z_P(iX) = nanmean(pred(iResp));
      end
      
      h = hggroup(ax,'DisplayName',name);
      surf(X,Y,Z_P, ...
         'LineWidth',pars.LineWidth,...
         'FaceColor',pars.FaceColor,...
         'EdgeColor',pars.EdgeColor,...
         'FaceAlpha',pars.AlphaData,...
         'EdgeAlpha',pars.AlphaData,...
         'MarkerSize',pars.MarkerSize,...
         'DisplayName','Predicted Response',...
         'Parent',h);
      SZ = min(pars.MinObservationSize+(Z_P - Z_O).^2,pars.MaxObservationSize);
      scatter3(X(:),Y(:),Z_P(:),SZ(:),...
         'Parent',h,...
         'Marker',pars.Marker,...
         'MarkerFaceColor',pars.MarkerFaceColor,...
         'MarkerEdgeColor',pars.MarkerEdgeColor,...
         'MarkerFaceAlpha',pars.AlphaData,...
         'MarkerEdgeAlpha',pars.AlphaData, ...
         'DisplayName','Average Predicted Response');
      
      dX = range(ax.XLim)*pars.TextPlaneOffsetFraction;
      dY = range(ax.YLim)*pars.TextPlaneOffsetFraction;
      dZ = range(ax.ZLim)*pars.TextVerticalOffsetFraction;
      for iX = 1:numel(X)
         
         line([X(iX),X(iX)],[Y(iX),Y(iX)],...
            [Z_P(iX),Z_O(iX)], ...
            'Parent',h, ...
            'Color',pars.ObservationColor,...
            'LineWidth',pars.ObservationLineWidth,...
            'LineStyle',pars.ObservationLineStyle,...
            'Marker',pars.ObservationMarker,...
            'MarkerIndices',2,...
            'MarkerFaceColor',pars.ObservationMarkerFaceColor,...
            'MarkerEdgeColor',pars.ObservationMarkerEdgeColor,...
            'MarkerSize',pars.ObservationMarkerSize,...
            'DisplayName',...
               sprintf('%s::%s Average Obesrved',...
                  string(Xc(iX)),string(Yc(iX))));
         z = max(Z_P(iX),Z_O(iX));
         text(ax,X(iX),Y(iX),z+dZ,sprintf('%5.2f',z),...
            'FontName','Arial',...
            'Color',[0.25 0.25 0.25],...
            'FontWeight','bold',...
            'BackgroundColor',[0.95 0.95 0.95],...
            'FontSize',14);   
      end
      % Update axes properties
      set(ax,...
         'XLim',[ax.XLim(1)-2*dX,ax.XLim(2)+2*dX],...
         'YLim',[ax.YLim(1)-2*dY,ax.YLim(2)+2*dY],...
         'ZLim',[ax.ZLim(1)-2*dZ,ax.ZLim(2)+2*dZ],...
         'XTick',double(x),'YTick',double(y),...
         'XTickLabel',string(x),'YTickLabel',string(y));
end

% Update common axes properties
set(ax.Title,'String',name);
view(ax,viewMode);

if ~pars.AddObservations
   return;
end

% If adding observed data, depends on 2D or 3D plot
switch numel(v)
   case 1
      error('Not added yet.');
   case 2
      for iX = 1:numel(x)
         for iY = 1:numel(y)
            iResp = find(S.(v{1})==x(iX) & S.(v{2})==y(iY));
            iSample = randi(numel(iResp),min(numel(iResp),pars.MaxObservations),1);
            z_pred = pred(iResp(iSample));
            z_obs = S.(glme.ResponseName)(iResp(iSample));
            sz = min(...
               pars.MinObservationSize + (z_obs - z_pred).^2,...
               pars.MaxObservationSize);
            xx = pars.Jitter .* randn(pars.MaxObservations,1) + double(x(iX));
            yy = pars.Jitter .* randn(pars.MaxObservations,1) + double(y(iY));
            scatter3(xx,yy,z_obs,sz,...
               'MarkerFaceColor',pars.ObservationMarkerFaceColor,...
               'Marker','o',...
               'MarkerEdgeColor','none',...
               'MarkerFaceAlpha',0.5,...
               'DisplayName',...
                  sprintf('%s::%s (Data)',string(x(iX)),string(y(iY))), ...
               'Parent',h);
         end
      end
end

end