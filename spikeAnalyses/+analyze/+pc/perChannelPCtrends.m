function fig = perChannelPCtrends(data)
%PERCHANNELPCTRENDS Create stem and trend plots for PC data struct
%
%  fig = analyze.pc.perChannelPCtrends(data);
%
% Inputs
%  data - struct with fields: 'epoch', 'score', 'explained', 'day', 'desc'
%
% Output
%  fig  - Figure handle
%
% See also: analyze.pc, channel_cross_day_trends

fig = figure('Name',sprintf('%s Per-Channel Trends',data.epoch),...
   'Color','w',...
   'Units','Normalized',...
   'Position',[0.3 0.3 0.3 0.3]); 
fig.UserData = data;
% Top axes shows trends against post-op day
ax = subplot(2,1,1); 
set(ax,'XColor','k','YColor','k',...
   'LineWidth',1.5,'NextPlot','add','FontName','Arial');
plot(ax,data.day,data.score(:,1:3),'LineWidth',2); 
title(ax,data.epoch,'FontName','Arial','Color','k','FontWeight','bold');
xlabel(ax,'Post-Op Day','FontName','Arial','Color','k','FontWeight','bold');
ylabel(ax,'Score','FontName','Arial','Color','k','FontWeight','bold');
ylim(ax,[-25 25]);
xlim(ax,[6 25]);

% Bottom axes has stem plot with % explained by component
ax = subplot(2,1,2); 
set(ax,'XColor','k','YColor','k','LineWidth',1.5,...
   'NextPlot','add','FontName','Arial');
e = cumsum(data.explained);

for iPC = 1:3
   stem(ax,iPC,e(iPC),...
      'DisplayName',sprintf('%s (PC-%d)',data.desc(iPC),iPC),...
      'LineWidth',2.5);
end
stem(ax,4:numel(data.explained),e(4:end),...
   'LineWidth',2,'Color','k','Marker','x','DisplayName','Remaining PCs');
xlabel(ax,'PC Index','FontName','Arial','Color','k','FontWeight','bold');
ylabel(ax,'%% Explained','FontName','Arial','Color','k','FontWeight','bold');
legend(ax,'FontName','Arial','TextColor','k','FontWeight','bold');

end