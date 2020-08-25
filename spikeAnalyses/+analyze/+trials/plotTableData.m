function fig = plotTableData(T,field,varargin)
%PLOTTABLEDATA Plot struct data tables for weekly spike counts
%
%  fig = analyze.trials.plotTableData(T,field);
%  fig = analyze.trials.plotTableData(T);
%
% Inputs
%  T - Struct array containing fields referenced by `field`, or just the
%           struct directly (without field). Contents of struct fields are
%           the by-week table formatted data.
%  field - Name of the struct field (optional)
%  varargin - (Optional) 'Name',value pairs
%
% Output
%  fig - Figure handle
%
% See also: analyze.trials, unit_learning_stats,
%           analyze.stat.weekTrendTable

pars = struct;
pars.Color = struct('Ischemia', ...
      struct('RFA',[0.8 0.2 0.2], ...
             'CFA',[1.0 0.4 0.4]), ...
          'Intact',...
       struct('RFA',[0.2 0.2 0.8], ...
              'CFA',[0.4 0.4 1.0]));
pars.LineStyle = struct('Ischemia',...
      struct('RFA','-',...
             'CFA','-'), ...
          'Intact',...
       struct('RFA',':',...
              'CFA',':'));
pars.LineWidth = 2.0;
pars.Marker = struct('Ischemia',...
      struct('RFA','x',...
             'CFA','x'), ...
          'Intact',...
       struct('RFA','o',...
              'CFA','o'));
pars.MarkerFaceColor = [0.0 0.0 0.0];
pars.Offset = struct('Ischemia', ...
      struct('RFA',0.1,'CFA',0.2 ), ...
         'Intact',....
      struct('RFA',-0.2,'CFA',-0.1) ...
         );
pars.YLim_Detrended = [-10 10];
pars.YLim_Observed = [0 65];

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
      

if isstruct(T)
   if nargin < 2
      field = fieldnames(T);
      fig = gobjects(numel(field),1);
      for iF = 1:numel(field)
         fig(iF) = analyze.trials.plotTableData(T,field{iF},varargin{:});
      end
      return;
   end
   T = T.(lower(field));
else
   if nargin < 2
      field = 'Weekly Mean';
   end
end


fig = figure(...
   'Name','Weekly Trends by Area',...
   'Color','w',...
   'Units','Normalized',...
   'Position',[0.2 0.2 0.4 0.6],...
   'NumberTitle','off');
ax = subplot(2,2,1:2);
set(ax,'Parent',fig,...
   'FontName','Arial','NextPlot','add',...
   'XColor','k','YColor','k','Tag','Observed',...
   'XLim',[0.5 4.5],'XTick',1:4);

[G,TID] = findgroups(T(:,{'GroupID','Area'}));

splitapply(@(wk,val,sem,group,area)...
   errorbar(ax,wk+pars.Offset.(string(group(1))).(string(area(1))),val,sem,...
      'Marker',pars.Marker.(string(group(1))).(string(area(1))),...
      'DisplayName',sprintf('%s::%s_{obs}',string(group(1)),string(area(1))),...
      'Tag',sprintf('%s::%s::observed',string(group(1)),string(area(1))),...
      'Color',pars.Color.(string(group(1))).(string(area(1))),...
      'LineStyle',pars.LineStyle.(string(group(1))).(string(area(1))),...
      'LineWidth',pars.LineWidth-1.0,...
      'MarkerFaceColor',pars.MarkerFaceColor),...
   T.Week,T.(T.Properties.UserData.Response),T.sem,...
   T.GroupID,T.Area,G);
   
legend(ax,...
   'TextColor','black',...
   'Location','northwest',...
   'EdgeColor','none',...
   'Color','none',...
   'NumColumns',2,...
   'FontName','Arial');

title(ax,sprintf('Observed (%s; mean \\pm SEM)',strrep(field,'_',' ')),...
   'FontName','Arial','Color','k','FontWeight','bold');
ylabel(ax,'Spike Count',...
   'FontName','Arial','Color','k','FontWeight','bold');
xlabel(ax,'Post-Op Week',...
   'FontName','Arial','Color','k','FontWeight','bold');
ylim(ax,pars.YLim_Observed);

ax = subplot(2,2,3);
set(ax,'Parent',fig,'FontName','Arial','NextPlot','add',...
   'XColor','k','YColor','k','Tag','Detrended',...
   'XLim',[0.5 4.5],'XTick',1:4);
splitapply(@(wk,val,sem,group,area)...
   errorbar(ax,wk+pars.Offset.(string(group(1))).(string(area(1))),val,sem,...
      'Marker',pars.Marker.(string(group(1))).(string(area(1))),...
      'DisplayName',sprintf('%s::%s_{det}',string(group(1)),string(area(1))),...
      'Tag',sprintf('%s::%s::detrended',string(group(1)),string(area(1))),...
      'Color',pars.Color.(string(group(1))).(string(area(1))),...
      'LineStyle',pars.LineStyle.(string(group(1))).(string(area(1))),...
      'LineWidth',pars.LineWidth,...
      'MarkerFaceColor',pars.MarkerFaceColor),...
   T.Week,T.(T.Properties.UserData.Detrended),T.sem_detrended,...
   T.GroupID,T.Area,G);
   
legend(ax,...
   'TextColor','black',...
   'Location','northwest',...
   'EdgeColor','none',...
   'Color','none',...
   'NumColumns',2,...
   'FontName','Arial');

title(ax,sprintf('Detrended (%s)',strrep(field,'_',' ')),...
   'FontName','Arial','Color','k','FontWeight','bold');
ylabel(ax,'Spike Count',...
   'FontName','Arial','Color','k','FontWeight','bold');
xlabel(ax,'Post-Op Week',...
   'FontName','Arial','Color','k','FontWeight','bold');
ylim(ax,pars.YLim_Detrended);

ax = subplot(2,2,4);
set(ax,'Parent',fig,'FontName','Arial','NextPlot','add',...
   'XColor','k','YColor','k','Tag','Bars');
TID.mu = splitapply(@(x,nC,nT)nansum(x.*nC.*nT./(nansum(nC.*nT))),...
   T.(T.Properties.UserData.Detrended),T.N_Channels,T.N_Trials,G);
TID.sem = splitapply(@(x)nanstd(x)/sqrt(numel(x)),T.(T.Properties.UserData.Detrended),G);
TID.x_off = 4*(double(TID.GroupID)-1.5) + 2*(double(TID.Area)-1.5);
set(ax,'XLim',[-4 4],'XTick',TID.x_off,...
   'XTickLabels',strcat(string(TID.Area),'_{',string(TID.GroupID),'}'),...
   'XTickLabelRotation',60);
for iT = 1:size(TID,1)
   a = char(TID.Area(iT));
   g = char(TID.GroupID(iT));
   bar(ax,TID.x_off(iT),TID.mu(iT),...
      'FaceColor',pars.Color.(g).(a),...
      'EdgeColor','none',...
      'BarWidth',1.0,...
      'DisplayName',sprintf('%s::%s',g,a));
   errorbar(ax,TID.x_off(iT),TID.mu(iT),TID.sem(iT)/2,TID.sem(iT)/2,...
      'LineStyle','none',...
      'Color',[0 0 0],...
      'LineWidth',1.5,...
      'Tag','SEM',...
      'DisplayName','SEM');
end

title(ax,sprintf('Aggregate Detrended (%s)',strrep(field,'_',' ')),...
   'FontName','Arial','Color','k','FontWeight','bold');
ylabel(ax,'Spike Count',...
   'FontName','Arial','Color','k','FontWeight','bold');
xlabel(ax,'Post-Op Week',...
   'FontName','Arial','Color','k','FontWeight','bold');
ylim(ax,pars.YLim_Detrended.*0.25);

end