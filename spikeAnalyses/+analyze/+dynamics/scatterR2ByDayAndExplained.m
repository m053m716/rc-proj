function fig = scatterR2ByDayAndExplained(E)
%SCATTERR2BYDAYANDEXPLAINED Create scatter plot for R2 fit by day & % exp
%
%  fig = analyze.dynamics.scatterR2ByDayAndExplained(E);
%
% Inputs
%  E - Data table of R2 and Explained values by Day, Animal, Group
%
% Output
%  fig - Figure handle
%
% See also: analyze.dynamics, population_firstorder_mls_regression_stats

if ismember('Explained_Best',E.Properties.VariableNames)
   varName = 'Explained_Best';
   E.(varName) = E.(varName).*100;
else
   varName = 'Explained';
end

fig = figure('Name','Grouped Scatter with Explained as Size Data',...
   'Color','w','Units','Normalized','Position',[0.2 0.2 0.4 0.4]);
ax = axes(fig,'XColor','k','YColor','k','NextPlot','add','FontName','Arial');
xlabel(ax,'Post-Op Day','FontName','Arial','Color','k');
ylabel(ax,'R^2_{MLS}','FontName','Arial','Color','k');
title(ax,['R^2_{MLS} By Group' newline '(larger = greater % explained)'],...
   'FontName','Arial','Color','k');
iIntact = E.GroupID=="Intact";
scatter(ax,...
   E.PostOpDay(iIntact)+randn(sum(iIntact),1).*0.10,...
   E.R2_Best(iIntact),...
   'filled','Marker','o','MarkerFaceColor',[0.1 0.1 0.9],...
   'DisplayName','Intact','MarkerFaceAlpha',0.5,'MarkerEdgeAlpha',0.5,...
   'MarkerEdgeColor',[0.1 0.1 0.9],'LineWidth',2.5,...
   'SizeData',(E.(varName)(E.GroupID=="Intact")/5).^2); 
scatter(ax,...
   E.PostOpDay(~iIntact)+randn(sum(~iIntact),1).*0.10,...
   E.R2_Best(~iIntact),...
   'filled','Marker','x',...
   'MarkerFaceColor',[0.9 0.1 0.1],...
   'MarkerFaceAlpha',0.5,...
   'MarkerEdgeAlpha',0.5,'LineWidth',2.5,...
   'MarkerEdgeColor',[0.9 0.1 0.1],...
   'SizeData',(E.(varName)(E.GroupID=="Ischemia")/5).^2,...
   'DisplayName','Ischemia'); 
legend(ax,'TextColor','black','FontName','Arial','Location','East');

end