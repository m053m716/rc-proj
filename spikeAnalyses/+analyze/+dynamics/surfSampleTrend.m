function fig = surfSampleTrend(E)
%SURFSAMPLETREND Surface: x - PostOpDay, y - % Explained, z - R^2_MLS
%
%  fig = analyze.dynamics.surfSampleTrend(E);
%
% Inputs
%  glme_best - GeneralizedLinearMixedModel produced in 
%                 population_firstorder_mls_regression_stats
%
% Output
%  fig       - Figure handle
%
%  See Figure 3.
%
% See also: analyze.dynamics, population_firstorder_mls_regression_stats
%           slicesample (R2006a+)

% Add helper repository %
utils.addHelperRepos();

% Create graphics for output %
fig = figure('Name','Population Dynamics Fit Trends',...
   'Color','w','Units','Normalized','Position',[0.3 0.2 0.25 0.65]);
ax_top = axes(fig,'XColor','k','YColor','k','ZColor','k',...
   'LineWidth',1.5,'FontName','Arial',...
   'NextPlot','add','XLim',[0 30],'YLim',[0 40],'ZLim',[0 1],...
   'Units','Normalized','Position',[0.2 0.55 0.6 0.35]);
xlabel(ax_top,'Post-Op Day','FontName','Arial','Color','k');
ylabel(ax_top,'% Explained','FontName','Arial','Color','k');
zlabel(ax_top,'R^2_{MLS}','FontName','Arial','Color','k');
view(ax_top,3);
box(ax_top,'on');
grid(ax_top,'on');
title(ax_top,'Intact','FontName','Arial','Color','k');

ax_bot = axes(fig,'XColor','k','YColor','k','ZColor','k',...
   'LineWidth',1.5,'FontName','Arial',...
   'NextPlot','add','XLim',[0 30],'YLim',[0 40],'ZLim',[0 1],...
   'Units','Normalized','Position',[0.2 0.15 0.6 0.35]);
xlabel(ax_bot,'Post-Op Day','FontName','Arial','Color','k');
ylabel(ax_bot,'% Explained','FontName','Arial','Color','k');
zlabel(ax_bot,'R^2_{MLS}','FontName','Arial','Color','k');
view(ax_bot,3);
box(ax_bot,'on');
grid(ax_bot,'on');
title(ax_bot,'Ischemia','FontName','Arial','Color','k');

E = E(E.Alignment=="Grasp",:);
% Plot Intact surface
e = E(E.GroupID=="Intact",:);
scatter3(ax_top,e.PostOpDay,e.Explained_Best*100,e.R2_Best,'filled',...
   'MarkerFaceColor',[0.1 0.1 0.9],'MarkerFaceAlpha',0.5);

% Plot Ischemia surface
e = E(E.GroupID=="Ischemia",:);
scatter3(ax_bot,e.PostOpDay,e.Explained_Best*100,e.R2_Best,'filled',...
   'MarkerFaceColor',[0.9 0.1 0.1],'MarkerFaceAlpha',0.5);

end