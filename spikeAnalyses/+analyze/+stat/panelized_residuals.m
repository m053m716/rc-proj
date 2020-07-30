function fig = panelized_residuals(glme,type,color)
%PANELIZED_RESIDUALS Plot generalized linear model residuals in panels
%
%  fig = analyze.stat.panelized_residuals(glme);
%  fig = analyze.stat.panelized_residuals(glme,type);
%  fig = analyze.stat.panelized_residuals(glme,type,color);
%
% Inputs
%  glme  - Generalized linear mixed effects model
%  type  - 'raw' (default) | 'Pearson'
%  color - [0.4 0.4 0.4] (default) | 3-element rgb color vector
%
% Output
%  fig  - Figure handle with two panels: top is histogram of residuals,
%           bottom is residual (y-axis) by model fit (x-axis).

if nargin < 2
   type = 'raw';
end

if nargin < 3
   color = [0.4 0.4 0.4];
end

utils.addHelperRepos();
if nargout > 0
   fig = figure(...
      'Name','Panelized GLME Residuals',...
      'Color','w',...
      'Units','Normalized',...
      'Position',gfx__.addToSecondMonitor,...
      'NumberTitle','off');
else
   fig = figure(...
      'Name','Panelized GLME Residuals',...
      'Color','w' ...
      );
end

% Plot histogram of residuals
ax = subplot(2,2,1); 
set(ax,'Parent',fig,...
   'FontName','Arial',...
   'XColor','k',...
   'YColor','k',...
   'LineWidth',1.5,...
   'Tag','histogramAxes');
h = plotResiduals(glme,'histogram','ResidualType',type); 
set(h,...
   'EdgeColor','none',...
   'FaceColor',color);
xlabel(ax,'Residual','FontName','Arial','Color','k','FontSize',14);
ylabel(ax,'Count','FontName','Arial','Color','k','FontSize',14);

% Plot probability density
ax = subplot(2,2,2); 
set(ax,...
   'Parent',fig,...
   'FontName','Arial',...
   'XColor','k',...
   'YColor','k',...
   'LineWidth',1.5,...
   'Tag','pdfAxes');
h = plotResiduals(glme,'probability',...
   'ResidualType',type); 
set(h(1),'Color',color,'LineStyle','none','Marker','o',...
   'MarkerFaceColor',color,'MarkerEdgeColor',color);
set(h(2),'LineWidth',1.5,'LineStyle','--','Color','k');
xlabel(ax,'Residual','FontName','Arial','Color','k','FontSize',14);
ylabel(ax,'Count','FontName','Arial','Color','k','FontSize',14);

% Plot scatter of fitted values vs. residuals
ax = subplot(2,2,[3,4]); 
set(ax,...
   'Parent',fig,...
   'FontName','Arial',...
   'XColor','k',...
   'YColor','k',...
   'LineWidth',1.5,...
   'Tag','fittedAxes');
h = plotResiduals(glme,'fitted','ResidualType',type);
set(h,'MarkerEdgeColor',color,'MarkerFaceColor',color);
xlabel(ax,'Fitted Value','FontName','Arial','Color','k','FontSize',14);
ylabel(ax,'Residual','FontName','Arial','Color','k','FontSize',14);

f = strrep(strrep(char(glme.Formula),'_','\_'),' ','');
formula_parts = strsplit(f,'(');
if numel(formula_parts) == 1
   str = formula_parts{1};
elseif numel(formula_parts) <= 3
   rePart = ['(' strjoin(formula_parts(2:end),'(')];
   if numel(rePart) > numel(formula_parts{1})
      rePart = '(Random Effects)';
   end
   str = [formula_parts{1} newline rePart];
else
   str = [formula_parts{1} newline '(Random Effects)'];
end

suptitle(str);
disp('<strong>R-squared</strong>');
disp(glme.Rsquared);

end