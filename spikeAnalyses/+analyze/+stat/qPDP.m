function fig = qPDP(glme,vars,varargin)
%QPDP Quick partial-dependence plot
%
%  fig = analyze.stat.qPDP(glme,vars);
%  fig = analyze.stat.qPDP(glme,vars,'Name',value,...);
%
% Inputs
%  glme - GeneralizedLinearMixedModel object
%  vars - Cell array with variables to create partial dependence plot for
%  varargin - (Optional) 'Name',value pairs 
%           (see also: plotPartialDependence)
%
% Output
%  fig  - Figure handle
%
% See also: analyze.stat, raw_rate_stats.mlx, plotPartialDependence

fig = figure('Name','Partial Dependence','Color','w','NumberTitle','off');
ax = axes(fig,'NextPlot','add','FontName','Arial',...
   'XColor','k','YColor','k','ZColor','k');
plotPartialDependence(glme,vars,'ParentAxisHandle',ax,varargin{:});
set(get(ax,'Children'),'FaceAlpha',0.5,'EdgeAlpha',0.25,'LineWidth',2);
set(ax,'View',[-10.32, 10.65]);
colorbar(ax);

end