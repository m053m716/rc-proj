function [fig,ax,h] = surf_partial_dependence(glme,var1,var2,varargin)
%SURF_PARTIAL_DEPENDENCE Create partial-dependence plot (PDP) surface
%
%  [fig,ax,h] = analyze.stat.surf_partial_dependence(glme,var1,var2);
%  [..] = analyze.stat.surf_partial_dependence(__,'Name',value,...);
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
% See also: analyze, analyze.stat

pars = struct;
pars.Axes = [];
pars.Box = 'off';
pars.ConditionalType = 'absolute';
pars.ExtraPDPArgs = {};
pars.Figure = [];
pars.FaceColor = [0.6 0.6 0.6];
% pars.EdgeColor = [0.0 0.0 0.0];
pars.EdgeColor = 'none';
pars.Marker          = 'o';
pars.MarkerSize      = 15;
pars.MarkerFaceColor = [0.6 0.6 0.6];
pars.MarkerEdgeColor = [0.0 0.0 0.0];
pars.LineWidth = 1.5;
pars.FaceAlpha = 0.7;
pars.EdgeAlpha = 0.7;
pars.TextPlaneOffsetFraction = 0.05;
pars.TextVerticalOffsetFraction = 0.1;
pars.Tag = '';
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
      fig = figure('Name','Partial Dependence Plot',...
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

% Make plot
ax = plotPartialDependence(glme,v,...
   'Conditional',pars.ConditionalType,...
   'ParentAxisHandle',ax,...
   pars.ExtraPDPArgs{:});
view(ax,viewMode);
h = ax.Children(1);
set(h,...
   'LineWidth',pars.LineWidth,...
   'Marker',pars.Marker,...
   'MarkerFaceColor',pars.MarkerFaceColor,...
   'MarkerEdgeColor',pars.MarkerEdgeColor,...
   'FaceColor',pars.FaceColor,...
   'EdgeColor',pars.EdgeColor,...
   'FaceAlpha',pars.FaceAlpha,...
   'EdgeAlpha',pars.EdgeAlpha,...
   'MarkerSize',pars.MarkerSize);

dX = range(ax.XLim)*pars.TextPlaneOffsetFraction;
dY = range(ax.YLim)*pars.TextPlaneOffsetFraction;
dZ = range(ax.ZLim)*pars.TextVerticalOffsetFraction;
set(ax,'XLim',[ax.XLim(1)-2*dX,ax.XLim(2)+2*dX]);
set(ax,'YLim',[ax.YLim(1)-2*dY,ax.YLim(2)+2*dY]);
set(ax,'ZLim',[ax.ZLim(1)-2*dZ,ax.ZLim(2)+2*dZ]);
switch numel(v)
   case 1
      if isempty(pars.Tag)
         set(ax.Title,'String',...
            sprintf('Individual Conditional Expectation: %s',v{1}));
      else
         set(ax.Title,'String',...
            sprintf('Individual Conditional Expectation: %s (%s)',v{1},pars.Tag));
      end
   case 2
      if isempty(pars.Tag)
         set(ax.Title,'String',...
            sprintf('Partial Dependence Plot: %s & %s',v{1},v{2}));
      else
         set(ax.Title,'String',...
            sprintf('Partial Dependence Plot: %s & %s (%s)',v{1},v{2},pars.Tag));
      end
end
for iPt = 1:numel(h.XData)
   x = h.XData(iPt);
   y = h.YData(iPt);
   z = h.ZData(iPt);
   text(ax,x,y,z+dZ,sprintf('%5.2f',z),...
      'FontName','Arial',...
      'Color',[0.25 0.25 0.25],...
      'FontWeight','bold',...
      'FontSize',14);
end

for iRow = 1:size(h.XData,1)
   line(ax,h.XData(iRow,:),h.YData(iRow,:),h.ZData(iRow,:),...
      'Color','r','LineWidth',2,'LineStyle','-');
end

for iCol = 1:size(h.XData,2)
   line(ax,h.XData(:,iCol),h.YData(:,iCol),h.ZData(:,iCol),...
      'Color','b','LineWidth',2,'LineStyle','-');
end

end