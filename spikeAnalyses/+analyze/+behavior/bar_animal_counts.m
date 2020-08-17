function [fig,h] = bar_animal_counts(T,numeratorVar,denominatorVar,varargin)
%BAR_ANIMAL_COUNTS Create bar plot figure of counts or ratios
%
%  fig = analyze.behavior.bar_animal_counts(T,numeratorVar);
%  fig = analyze.behavior.bar_animal_counts(T,numeratorVar,denominatorVar);
%  fig = analyze.behavior.bar_animal_counts(__,'Name',value,...);
%
% Example:
%  fig = analyze.behavior.bar_animal_counts(tPreOp,'nSuccess','nTotal')
%
% Inputs
%  T              - Data table; must contain 'GroupID' variable
%  numeratorVar   - Variable to use for bar numerator
%  denominatorVar - (Optional; if not specified, all denominators are 1)
%  varargin       - (Optional) 'Name',value input argument pairs
%
% Output
%  fig            - Figure handle
%  h              - Graphics objects handles
% 
% See also: analyze.behavior, analyze.behavior.per_animal_trends,
%           trial_outcome_stats

pars = struct;
pars.Title = '';
pars.YLabel = '';
pars.YLim = [nan nan];
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

num = T.(numeratorVar);
if nargin < 3
   den = ones(size(num));
   if isempty(pars.YLabel)
      yLab = 'Count';
   else
      yLab = pars.YLabel;
   end
   figStr = sprintf('Bar of %s counts',numeratorVar);
else
   den = T.(denominatorVar);
   if isempty(pars.YLabel)
      yLab = '%';
   else
      yLab = pars.YLabel;
   end
   num = num .* 100; % Convert to percentages
   figStr = sprintf('Bar of %s by %s',numeratorVar,denominatorVar);   
end
fig = figure('Name',figStr,'Color','w','Units','Normalized',...
   'Position',[0.2 0.2 0.4 0.4],'NumberTitle','off');
y = num ./ den;
g = T.GroupID;
[gIdx,G] = findgroups(g);
x = double(G);
labs = string(G);

mu = splitapply(@nanmean,y,gIdx);
cb95 = cell2mat(splitapply(@analyze.stat.getCB95,y,gIdx));   

ax = axes(fig,'XColor','k','YColor','k','LineWidth',1.5,'NextPlot','add',...
   'FontName','Arial',...
   'ColorOrder',[0.9 0.1 0.1;0.1 0.1 0.9],...
   'XTick',x,'XTickLabels',labs,...
   'TitleFontSizeMultiplier',1.50,...
   'LabelFontSizeMultiplier',1.25);
if ~any(isnan(pars.YLim))
   ylim(ax,pars.YLim);
end
ylabel(ax,yLab,'FontName','Arial','Color','k','FontWeight','bold');
if isempty(pars.Title)
   titleStr = figStr;
else
   titleStr = pars.Title;
end
title(ax,titleStr,'FontName','Arial','Color','k','FontWeight','bold');
h = hggroup(ax,'Tag',figStr);
h.Annotation.LegendInformation.IconDisplayStyle = 'off';
for ii = 1:numel(mu)
   hBar = bar(x(ii),mu(ii),0.75,...
      'EdgeColor','none',...
      'FaceAlpha',0.45,...
      'DisplayName',labs(ii),...
      'Parent',h);
   hBar.Annotation.LegendInformation.IconDisplayStyle = 'on';
end
hErr = errorbar(x,mu,...
   cb95(:,1)-mu,... % Observations lower bound (95% confidence interval)
   cb95(:,2)-mu,... % Observations upper bound (95% confidence interval)
   'Parent',h,...
   'Color','k',...
   'LineStyle','none',...
   'LineWidth',3.5,...
   'DisplayName','95% CB');
hErr.Annotation.LegendInformation.IconDisplayStyle = 'on';

legend(hErr,...
   'TextColor','black',...
   'EdgeColor','none',...
   'Color','none',...
   'FontName','Arial',...
   'FontSize',12,...
   'FontWeight','bold');

end