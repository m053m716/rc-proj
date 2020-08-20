function fig = inputDistribution(E,varName)
%INPUTDISTRIBUTION Plot observed distribution & smoothed cdf estimate
%
%  fig = analyze.dynamics.inputDistribution(E,'varName');
%
% See also: analyze.dynamics, population_firstorder_mls_regression_stats

fig = figure('Name','Input Distribution: Performance Covariate',...
   'Color','w','Units','Normalized','Position',[0.25 0.25 0.3 0.4],...
   'UserData',E);
ax = axes(fig,'XColor','k','YColor','k','LineWidth',1.5,...
   'FontName','Arial','NextPlot','add','XLim',[-1 1]);
% Only use unique values by block (so only 1 Grasp, only 1 Plane)
[~,idx] = unique(E.BlockID);
E = E(idx,:);

histogram(ax,E.(varName),...
   'BinMethod','sqrt',...
   'BinLimits',[-1 1],...
   'Normalization','pdf',...
   'EdgeColor','none',...
   'FaceColor',[0.3 0.3 0.3],...
   'FaceAlpha',0.75);
ksdensity(ax,E.(varName),...
   'BoundaryCorrection','reflection',...
   'Bandwidth',0.05,...
   'Kernel','epanechnikov',...
   'Function','cdf');
c = get(ax,'Children');
set(c(1),'Color',[0 0 0],'LineWidth',2.5,...
   'DisplayName','Smoothed CDF','Tag','KDE');
set(c(2),'DisplayName','Observed Performance','Tag','Histogram');
xlabel(ax,'\bf\itx\rm = 2*\pi*tanh([Success Rate]-0.5)','FontName','Arial','Color','k');
ylabel(ax,'pdf(\bf\itx\rm)','FontName','Arial','Color','k');
title(ax,'Distribution of Performance Covariate','FontName','Arial','Color','k');
legend(ax,'Color','none',...
   'TextColor','black','FontName','Arial',...
   'FontSize',11,'FontWeight','bold',...
   'EdgeColor','none','Location','north');

end