close all force;

% D = utils.loadTables('multi'); % Load "multi-jPCA" table.
% E2 = analyze.dynamics.exportSubTable(D);
uiopen('D:\MATLAB\Data\RC\Figures\Reach-Retract-Figures\Fig4d - PDP - R2_Best-Skew_Performance.fig',1);
fig = gcf;
ax = gca;
view(ax,2);
c = findobj(get(ax,'Children'),'Type','surface');
z = get(c,'ZData');
[~,~,cdata_indexing] = histcounts(z(:),linspace(-1,1,257));
cm = [nan nan nan; ax.Colormap];
cdata_indexing = cdata_indexing + 1; % account for "shift"
cdata = cm(cdata_indexing,:);
cdata = reshape(cdata,size(z,1),size(z,2),3);
set(c,'ZData',zeros(size(z)));
set(c,'CData',cdata);
scatter(ax,...
   E2.R2_Best,...
   E2.R2_Skew,...
   'Marker','x',...
   'MarkerFaceColor','none',...
   'MarkerEdgeColor','k',...
   'SizeData',12,...
   'LineWidth',1.0);
set(ax,...
   'XTick',max(E2.R2_Best),...
   'XTickLabel',round(max(E2.R2_Best),2),...
   'XColor',[0 0 0],...
   'XMinorTick','off',...
   'YTick',max(E2.R2_Skew),...
   'YColor',[0 0 0],...
   'YMinorTick','off',...
   'YTickLabel',round(max(E2.R2_Skew),2));
if exist(fullfile(pwd,'figures'),'dir')==0
   mkdir(fullfile(pwd,'figures'));
end

set(fig,...
   'Units','Normalized',...
   'Position',[0.03 0.05 0.90 0.80],...
   'PaperUnits','normalized',...
   'PaperPosition',[0.05 0.05 0.9 0.9],...
   'PaperOrientation','landscape',...
   'Renderer','OpenGL');

% savefig(fig,fullfile(pwd,'figures','R01-Renewal-Performance_Dynamics.fig'));
saveas(fig,fullfile('figures','R01-Renewal-Performance_Dynamics.tiff'),'epsc2');
% saveas(fig,fullfile(pwd,'figures','R01-Renewal-Performance_Dynamics.png'));
% utils.expAI(fig,fullfile(pwd,'figures','R01-Renewal-Performance_Dynamics.svg'));
% utils.expAI(fig,fullfile(pwd,'figures','R01-Renewal-Performance_Dynamics.ai'));
% delete(fig)