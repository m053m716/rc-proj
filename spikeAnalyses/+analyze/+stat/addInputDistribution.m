function ax_i = addInputDistribution(ax,data,thresh)
%ADDINPUTDISTRIBUTION Add input distribution to target axes
%
%  ax_i = analyze.stat.addInputDistribution(ax,data);
%  ax_i = analyze.stat.addInputDistribution(ax,data,thresh);
%
% Inputs
%  ax     - Target axes handle
%  data   - Data used for input distribution estimate
%  thresh - (Optional) Threshold applied to the data (for visualization)
%              -> IF not given, estimated from mean of input data
% Output
%  ax_i   - Inset axes handle
%
% See also: analyze.stat.plotROC, analyze.stat, unit_learning_stats

if nargin < 3
   thresh = nanmean(data(:));
end

ax.Units = 'Normalized';
pos = ax.InnerPosition; % For inset
x = pos(1);
y = pos(2);
w = pos(3);
h = pos(4);
xi = x + 0.66*w;
yi = y + 0.40*h;
wi = 0.30*w;
hi = 0.20*h;
pos_inset = [xi yi wi hi];
ax_i = axes(ax.Parent,...
   'Units','Normalized',...
   'Color',[0.8 0.8 0.8],...
   'Position',pos_inset,...
   'FontName','Arial','NextPlot','add',...
   'XColor','black','YColor','none',...
   'XLim',[0 1]);
histogram(ax_i,data,...
   'EdgeColor','none','FaceColor','k',...
   'Normalization','pdf');
ksdensity(ax_i,data,'Function','pdf');
c = findobj(ax_i,'Type','line');
set(c,'LineWidth',2.5,'Color','b','DisplayName','PDF: Predictions');
xlabel(ax_i,'Prediction PDF',...
   'FontName','Arial','Color','k','FontWeight','bold');
ax_i.XAxis.Label.BackgroundColor = [0.8 0.8 0.8];
line(ax_i,ones(1,2).*thresh,ax_i.YLim,...
   'LineStyle',':','Color','m',...
   'LineWidth',2.0,'DisplayName','Threshold');

end