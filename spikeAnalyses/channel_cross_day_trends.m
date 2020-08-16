%CHANNEL_CROSS_DAY_TRENDS Evaluate trends on a per-channel basis across
% days, with respect to spike rates in pre-defined epochs as they fluctuate
% over the time-course of all recordings. 
%
% Treats the spike rates during these epochs as a spline effect; values are
% interpolated and smoothed (using sgolayfilt). 

clc;
clearvars -except r
if exist('r','var')==0
   fprintf(1,'Loading raw rates table...');
   r = getfield(load(defaults.files('learning_rates_table_file'),'r'),'r');
   fprintf(1,'complete\n');
else
   fprintf(1,'Found `r` (<strong>%d</strong> rows) in workspace.',size(r,1));
   k = 5;
   fprintf(1,'\n\t->\tPreview (%d rows):\n\n',k);
   disp(r(randsample(size(r,1),k),:));
end
% `r` has the following exclusions:
%  -> 'Grasp' aligned only
%  -> Min total trial rate: > 2.5 spikes/sec
%  -> Max total trial rate: < 300 spikes/sec
%  -> Min trial duration: 100-ms
%  -> Max trial duration: 750-ms
%  -> Note: some of these are taken care of by
%              r.Properties.UserData.Excluded

% % Get data table where rows are Channel observations across all days % %
Y = analyze.stat.interpolateUniformTrend(r);

% % Create output data structs using PCA % %
Grasp = struct;
[Grasp.coeff,Grasp.score,~,~,Grasp.explained,Grasp.mu] = pca(Y.Grasp' - Y.Pre');
Reach = struct;
[Reach.coeff,Reach.score,~,~,Reach.explained,Reach.mu] = pca(Y.Reach' - Y.Pre');
Retract = struct;
[Retract.coeff,Retract.score,~,~,Retract.explained,Retract.mu] = pca(Y.Retract' - Y.Pre');
Reach.labels = categorical(strcat(string(Y.Group),"::",string(Y.Area)));
Grasp.labels = categorical(strcat(string(Y.Group),"::",string(Y.Area)));
Retract.labels = categorical(strcat(string(Y.Group),"::",string(Y.Area)));
Group = ["Ischemia";"Intact"]; 
Area = ["RFA";"CFA"];

outPath = defaults.files('reach_extension_figure_dir');
if exist(outPath,'dir')==0
   mkdir(outPath);
end

% Create figures for Grasp trends %
% % Create Line Plots for primary channel trends across days % %
fig = figure('Name','Grasp Per-Channel Trends','Color','w',...
   'Units','Normalized','Position',[0.3 0.3 0.3 0.3]); 
fig.UserData = Grasp;
ax = subplot(2,1,1); 
set(ax,'XColor','k','YColor','k',...
   'LineWidth',1.5,'NextPlot','add','FontName','Arial');
plot(ax,Y.Properties.UserData.PostOpDay,Grasp.score(:,1:3),'LineWidth',2); 
title(ax,'Grasp','FontName','Arial','Color','k');
xlabel(ax,'Post-Op Day','FontName','Arial','Color','k');
ylabel(ax,'Score','FontName','Arial','Color','k');
ylim(ax,[-20 20]);
xlim(ax,[6 25]);
ax = subplot(2,1,2); 
set(ax,'XColor','k','YColor','k','LineWidth',1.5,...
   'NextPlot','add','FontName','Arial');
e = cumsum(Grasp.explained);
for iPC = 1:3
   stem(ax,iPC,e(iPC),...
      'DisplayName',sprintf('PC-%d',iPC),'LineWidth',2.5);
end
stem(ax,4:numel(Grasp.explained),e(4:end),...
   'LineWidth',2,'Color','k','Marker','x','DisplayName','Remaining PCs');
xlabel(ax,'PC Index','FontName','Arial','Color','k');
ylabel(ax,'%% Explained','FontName','Arial','Color','k');
legend(ax,'FontName','Arial','TextColor','k');
saveas(fig,fullfile(outPath,'FigS5 - Grasp Channel Trends.png'));
savefig(fig,fullfile(outPath,'FigS5 - Grasp Channel Trends.fig'));
delete(fig);

% % Plot 3D Scatter of coefficients % %
fig = figure('Name','Grasp Channel PC Coefficients','Color','w',...
   'Units','Normalized','Position',[0.6 0.3 0.3 0.3]); 
fig.UserData = Grasp;
ax = axes(fig,...
   'XColor','k','YColor','k','LineWidth',1.5,...
   'NextPlot','add','FontName','Arial');
for iG = 1:2
   for iA = 1:2
      scatter3(ax,...
         Grasp.coeff(Y.Group==Group(iG) & Y.Area==Area(iA),1),...
         Grasp.coeff(Y.Group==Group(iG) & Y.Area==Area(iA),2),...
         Grasp.coeff(Y.Group==Group(iG) & Y.Area==Area(iA),3),'filled',...
         'DisplayName',sprintf('%s::%s',Group(iG),Area(iA)),...
         'MarkerFaceAlpha',0.5,'MarkerEdgeAlpha',0.25);
   end
end
legend(ax,'FontName','Arial','TextColor','black');
view(ax,3);
title(ax,'Grasp Trend Coefficients','FontName','Arial','Color','k');
xlabel(ax,'PC-1','FontName','Arial','Color','k');
ylabel(ax,'PC-2','FontName','Arial','Color','k');
zlabel(ax,'PC-3','FontName','Arial','Color','k');
saveas(fig,fullfile(outPath,'FigS5 - Grasp PC Coefficients.png'));
savefig(fig,fullfile(outPath,'FigS5 - Grasp PC Coefficients.fig'));
delete(fig);

% Create figures for Reach trends %
% % Create Line Plots for primary channel trends across days % %
fig = figure('Name','Reach Per-Channel Trends','Color','w',...
   'Units','Normalized','Position',[0.3 0.3 0.3 0.3]); 
fig.UserData = Reach;
ax = subplot(2,1,1); 
set(ax,'XColor','k','YColor','k',...
   'LineWidth',1.5,'NextPlot','add','FontName','Arial');
plot(ax,Y.Properties.UserData.PostOpDay,Reach.score(:,1:3),'LineWidth',2); 
title(ax,'Reach','FontName','Arial','Color','k');
xlabel(ax,'Post-Op Day','FontName','Arial','Color','k');
ylabel(ax,'Score','FontName','Arial','Color','k');
ylim(ax,[-20 20]);
xlim(ax,[6 25]);
ax = subplot(2,1,2); 
set(ax,'XColor','k','YColor','k','LineWidth',1.5,...
   'NextPlot','add','FontName','Arial');
e = cumsum(Reach.explained);
for iPC = 1:3
   stem(ax,iPC,e(iPC),...
      'DisplayName',sprintf('PC-%d',iPC),'LineWidth',2.5);
end
stem(ax,4:numel(Reach.explained),e(4:end),...
   'LineWidth',2,'Color','k','Marker','x','DisplayName','Remaining PCs');
xlabel(ax,'PC Index','FontName','Arial','Color','k');
ylabel(ax,'%% Explained','FontName','Arial','Color','k');
legend(ax,'FontName','Arial','TextColor','k');
saveas(fig,fullfile(outPath,'FigS5 - Reach Channel Trends.png'));
savefig(fig,fullfile(outPath,'FigS5 - Reach Channel Trends.fig'));
delete(fig);

% % Plot 3D Scatter of coefficients % %
fig = figure('Name','Reach Channel PC Coefficients','Color','w',...
   'Units','Normalized','Position',[0.6 0.3 0.3 0.3]); 
fig.UserData = Reach;
ax = axes(fig,...
   'XColor','k','YColor','k','LineWidth',1.5,...
   'NextPlot','add','FontName','Arial');
for iG = 1:2
   for iA = 1:2
      scatter3(ax,...
         Reach.coeff(Y.Group==Group(iG) & Y.Area==Area(iA),1),...
         Reach.coeff(Y.Group==Group(iG) & Y.Area==Area(iA),2),...
         Reach.coeff(Y.Group==Group(iG) & Y.Area==Area(iA),3),'filled',...
         'DisplayName',sprintf('%s::%s',Group(iG),Area(iA)),...
         'MarkerFaceAlpha',0.5,'MarkerEdgeAlpha',0.25);
   end
end
legend(ax,'FontName','Arial','TextColor','black');
view(ax,3);
title(ax,'Reach Trend Coefficients','FontName','Arial','Color','k');
xlabel(ax,'PC-1','FontName','Arial','Color','k');
ylabel(ax,'PC-2','FontName','Arial','Color','k');
zlabel(ax,'PC-3','FontName','Arial','Color','k');
saveas(fig,fullfile(outPath,'FigS5 - Reach PC Coefficients.png'));
savefig(fig,fullfile(outPath,'FigS5 - Reach PC Coefficients.fig'));
delete(fig);

% Create figures for Retract trends %
% Create figures for Reach trends %
% % Create Line Plots for primary channel trends across days % %
fig = figure('Name','Retract Per-Channel Trends','Color','w',...
   'Units','Normalized','Position',[0.3 0.3 0.3 0.3]); 
fig.UserData = Retract;
ax = subplot(2,1,1); 
set(ax,'XColor','k','YColor','k',...
   'LineWidth',1.5,'NextPlot','add','FontName','Arial');
plot(ax,Y.Properties.UserData.PostOpDay,Retract.score(:,1:3),'LineWidth',2); 
title(ax,'Retract','FontName','Arial','Color','k');
xlabel(ax,'Post-Op Day','FontName','Arial','Color','k');
ylabel(ax,'Score','FontName','Arial','Color','k');
ylim(ax,[-20 20]);
xlim(ax,[6 25]);
ax = subplot(2,1,2); 
set(ax,'XColor','k','YColor','k','LineWidth',1.5,...
   'NextPlot','add','FontName','Arial');
e = cumsum(Retract.explained);
for iPC = 1:3
   stem(ax,iPC,e(iPC),...
      'DisplayName',sprintf('PC-%d',iPC),'LineWidth',2.5);
end
stem(ax,4:numel(Retract.explained),e(4:end),...
   'LineWidth',2,'Color','k','Marker','x','DisplayName','Remaining PCs');
xlabel(ax,'PC Index','FontName','Arial','Color','k');
ylabel(ax,'%% Explained','FontName','Arial','Color','k');
legend(ax,'FontName','Arial','TextColor','k');

saveas(fig,fullfile(outPath,'FigS5 - Retract Channel Trends.png'));
savefig(fig,fullfile(outPath,'FigS5 - Retract Channel Trends.fig'));
delete(fig);

% % Plot 3D Scatter of coefficients % %
fig = figure('Name','Retract Channel PC Coefficients','Color','w',...
   'Units','Normalized','Position',[0.6 0.3 0.3 0.3]); 
fig.UserData = Retract;
ax = axes(fig,...
   'XColor','k','YColor','k','LineWidth',1.5,...
   'NextPlot','add','FontName','Arial');
for iG = 1:2
   for iA = 1:2
      scatter3(ax,...
         Retract.coeff(Y.Group==Group(iG) & Y.Area==Area(iA),1),...
         Retract.coeff(Y.Group==Group(iG) & Y.Area==Area(iA),2),...
         Retract.coeff(Y.Group==Group(iG) & Y.Area==Area(iA),3),'filled',...
         'DisplayName',sprintf('%s::%s',Group(iG),Area(iA)),...
         'MarkerFaceAlpha',0.5,'MarkerEdgeAlpha',0.25);
   end
end
legend(ax,'FontName','Arial','TextColor','black');
view(ax,3);
title(ax,'Retract Trend Coefficients','FontName','Arial','Color','k');
xlabel(ax,'PC-1','FontName','Arial','Color','k');
ylabel(ax,'PC-2','FontName','Arial','Color','k');
zlabel(ax,'PC-3','FontName','Arial','Color','k');
saveas(fig,fullfile(outPath,'FigS5 - Retract PC Coefficients.png'));
savefig(fig,fullfile(outPath,'FigS5 - Retract PC Coefficients.fig'));
delete(fig);
