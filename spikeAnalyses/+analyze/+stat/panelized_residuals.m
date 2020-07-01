function fig = panelized_residuals(glme,type)
%PANELIZED_RESIDUALS Plot generalized linear model residuals in panels
%
%  fig = analyze.stat.panelized_residuals(glme);
%  fig = analyze.stat.panelized_residuals(glme,type);
%
% Inputs
%  glme - Generalized linear mixed effects model
%  type - 'raw' (default) | 'Pearson'
%
% Output
%  fig  - Figure handle with two panels: top is histogram of residuals,
%           bottom is residual (y-axis) by model fit (x-axis).

if nargin < 2
   type = 'raw';
end

addHelperRepos();
fig = figure('Name','Panelized GLME Residuals',...
   'Color','w',...
   'Units','Normalized',...
   'Position',gfx__.addToSecondMonitor,...
   'NumberTitle','off'); 

ax = subplot(2,1,1); 
set(ax,'FontName','Arial','XColor','k','YColor','k','LineWidth',1.5);
plotResiduals(glme,'histogram','ResidualType',type); 
xlabel('Residual','FontName','Arial','Color','k','FontSize',14);
ylabel('Count','FontName','Arial','Color','k','FontSize',14);

ax = subplot(2,1,2); 
set(ax,'FontName','Arial','XColor','k','YColor','k','LineWidth',1.5);
plotResiduals(glme,'fitted','ResidualType',type);
xlabel('Fitted Value','FontName','Arial','Color','k','FontSize',14);
ylabel('Residual','FontName','Arial','Color','k','FontSize',14);

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

end