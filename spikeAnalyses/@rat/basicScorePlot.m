function ax = basicScorePlot(obj,ax)
%BASICSCOREPLOT  Adds plot of basic scores by day
%
%  ax = basicScorePlot(obj,ax);
%
%  --------
%   INPUTS
%  --------
%    obj       :     `rat` class object
%
%     ax       :     Axes object to add plot to. 
%                    --> If not specified, uses current axes

% PARSE INPUT
if nargin < 2
   ax = gca;
end

% GET PARAMETERS
% Parse parameters for coloring lines, smoothing plots
[cm,nColorOpts] = defaults.load_cm;
idx = round(linspace(1,size(cm,1),nColorOpts)); 
poDay = getProp(obj.Children,'PostOpDay');
s = getProp(obj.Children,'TrueScore') * 100;

% SET AXES PROPERTIES
ax.NextPlot = 'add';
ax.FontName = 'Arial';  
ax.FontSize = 10;
ax.LineWidth = 1.5;

% X-axis properties
ax.XColor = 'k';
ax.XLim = [0 nColorOpts+1];
ax.XMinorTick = 'on';
ax.XMinorGrid = 'on';
ax.XAxis.TickValues = [5 10 15 20 25];
ax.XAxis.MinorTickValues = poDay;

ax.YLim = [-10 110];
ax.YColor = 'k';
ax.YMinorTick = 'on';
ax.YGrid = 'on';
ax.YTick = [0 50 100];
ax.YMinorGrid = 'on';
ax.YAxis.MinorTickValues = [25 75];

line(ax,poDay,s,...
   'Color',[0.3 0.3 0.3],... 
   'Marker','none',...
   'LineStyle','--',...
   'LineWidth',1.5,...
   'DisplayName','% Successful Retrievals')         

offset = 7; % Hard-coded constant
for ii = 1:numel(obj.Children)
   thisColor = cm(idx(poDay(ii)),:);
   line(ax,poDay(ii),s(ii),...
      'LineStyle','none',...
      'Marker','o',...
      'MarkerSize',10,...
      'MarkerFaceColor',thisColor,...
      'MarkerEdgeColor','k');
   txt = sprintf('(%g)',obj.Children(ii).nTrialRecent.rate);
   if ii == 1
      iAbove = true;
   else
      if iAbove
         if s(ii) <= (s(ii-1)+2*offset)
            iAbove = false;            
         end
      else
         if s(ii) >= (s(ii-1)-2*offset)
            iAbove = true;
         end
      end
   end
   if iAbove
      text(ax,poDay(ii),s(ii)+offset,txt,...
         'FontName','Arial',...
         'Color',[0.4 0.4 0.4],...
         'FontSize',10,...
         'FontWeight','bold',...
         'HorizontalAlignment','center',...
         'VerticalAlignment','bottom');
   else
      text(ax,poDay(ii),s(ii)-offset,txt,...
         'FontName','Arial',...
         'Color',[0.4 0.4 0.4],...
         'FontWeight','bold',...
         'FontSize',10,...
         'HorizontalAlignment','center',...
         'VerticalAlignment','top');
   end
end
xlabel(ax,'Post-Op Day',...
   'FontSize',14,...
   'Color','k',...
   'FontName','Arial',...
   'FontWeight','bold');
ylabel(ax,'Score (N/trace)',...
   'FontSize',12,...
   'Color','k',...
   'FontName','Arial');


end