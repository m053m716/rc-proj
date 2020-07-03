function fig = scatter_channel_activations(P,varargin)
%SCATTER_CHANNEL_ACTIVATIONS Create scatter plots of channelwise activity
%
%  fig = analyze.jPCA.scatter_channel_activations(P);
%  fig = analzye.jPCA.scatter_channel_activations(P,pars); 
%     -> Give parameters struct directly
%  fig = analyze.jPCA.scatter_channel_activations(P,'name',value,...);
%     -> Use 'name',value pairs
%  fig = analyze.jPCA.scatter_channel_activations(P,channel,...);
%     -> Specify channel index as extra argument
%
% Inputs
%  P   - Cell array where each element is Projection corresponding to some
%           block. See analyze.jPCA.jPCA regarding Projection struct array
%  varargin - 'name',value pairs:
%              * 'channel' : Channel index (default: 1)
%              * 'plane'   : Plane index (default: 1)
%              * 'block'   : Block index (default: 1)
%              * 'axparams': Cell array of axes 'name',value parameters 
%                                -> see built-in `axes`
%              * 'figparams': Cell array of figure 'name',value pairs 
%                                -> see built-in `figure`
%              * 'fontparams': Cell array of label 'name',value pairs
%                                pertaining to fonts
%                                default: {'FontName','Arial','Color','k'}
%              * 'scatterparams_rate','scatterparams_p1','scatterparams_p2'
%                 -> cell array of 'name',value pairs for each
%                    corresponding call to `scatter` built-in function
%
% Output
%  fig - Graphics handle to figure

utils.addHelperRepos();

% % Parse input arguments % %
pars = struct;
pars.alignment = 'Grasp';
pars.channel = 1; 
pars.plane = 1; 
pars.block = 1; 
pars.ylim_rate = [-3 3];
pars.fig = [];
pars.figparams = {...
   'Color','w',...
   'Units','Normalized',...
   'Position',gfx__.addToSecondMonitor([0.2 0.2 0.5 0.5])};
pars.axparams = {...
   'XColor','k',...
   'YColor','k',...
   'LineWidth',1.5,...
   'NextPlot','add',...
   'FontName','Arial'};
pars.fontparams = {...
   'FontName','Arial',...
   'Color','k',...
   'FontWeight','bold'};
pars.scatterparams_rate = {...
   'MarkerFaceColor','k',...
   'MarkerEdgecolor','none',...
   'MarkerFaceAlpha',0.25,...
   'SizeData',10};
pars.scatterparams_p1 = {...
   'MarkerFaceColor','b',...
   'MarkerEdgecolor','none',...
   'MarkerFaceAlpha',0.25,...
   'SizeData',10};
pars.scatterparams_p2 = {...
   'MarkerFaceColor','b',...
   'MarkerEdgecolor','none',...
   'MarkerFaceAlpha',0.25,...
   'SizeData',10};
fn = fieldnames(pars);

if nargin >= 2
   if isstruct(varargin{1})
      pars = varargin{1};
      varargin(1) = [];
   elseif isnumeric(varargin{1})
      pars.channel = varargin{1};
      varargin{1} = [];
   end
end


for iV = 1:2:numel(varargin)
   idx = strcmpi(fn,varargin{iV});
   if sum(idx)==1
      pars.(fn{idx}) = varargin{iV+1};
   end
end

% % Create data arrays % %
W = vertcat(P{pars.block}.W); 
t = vertcat(P{pars.block}.times);
rates = vertcat(P{pars.block}.data);
xl = [min(t),max(t)];

% % Create figure handle % %
str = sprintf('Block-%02d Channel-%02d Plane-%02d',...
   pars.block,pars.channel,pars.plane);

if isempty(pars.fig)
   fig = figure(...
      'Name',sprintf('jPCA Channel Activations: %s',str),...
      pars.figparams{:}); 
else
   fig = pars.fig;
   clf(fig);
end
figure(fig);
ax_p1 = subplot(2,2,3); 
set(ax_p1,'XLim',xl,pars.axparams{:});

% First component of jPCA plane
scatter(ax_p1,t,W(:,2*(pars.plane-1)+1,pars.channel),'filled',...
   pars.scatterparams_p1{:}); 
title(ax_p1,sprintf('Plane-%02d_1',pars.plane)); 
xlabel(ax_p1,'Time (ms)',pars.fontparams{:});  

% Second component of jPCA plane
ax_p2 = subplot(2,2,4); 
set(ax_p2,'XLim',xl,'YAxisLocation','left',pars.axparams{:});
scatter(ax_p2,t,W(:,2*pars.plane,pars.channel),'filled',...
   pars.scatterparams_p2{:});   
title(ax_p2,sprintf('Plane-%02d_2',pars.plane)); 
xlabel(ax_p2,'Time (ms)',pars.fontparams{:}); 

yl = [min(ax_p2.YLim(1),ax_p1.YLim(1)),max(ax_p2.YLim(2),ax_p1.YLim(2))];
ax_p2.YLim = yl;
ax_p1.YLim = yl;

% Add lines indicating grasp onset to each
line(ax_p1,[0 0],yl,...
   'Color','m','LineWidth',1.5,'LineStyle','--',...
   'DisplayName',pars.alignment);
line(ax_p2,[0 0],yl,...
   'Color','m','LineWidth',1.5,'LineStyle','--',...
   'DisplayName',pars.alignment);

% Actual channel rates
ax_rate = subplot(2,2,[1,2]); 
set(ax_rate,'YLim',pars.ylim_rate,'XLim',xl,pars.axparams{:});
scatter(ax_rate,t,rates(:,pars.channel),'filled',...
   pars.scatterparams_rate{:}); 
title(ax_rate,sprintf('Channel-%02d',pars.channel));
xlabel(ax_rate,'Time (ms)',pars.fontparams{:}); 
ylabel(ax_rate,'Rate (spikes/sec)',pars.fontparams{:}); 
line(ax_rate,[0 0],pars.ylim_rate,...
   'Color','m','LineWidth',1.5,'LineStyle','--',...
   'DisplayName',pars.alignment);

str = strsplit(P{pars.block}(1).Trial_ID,'_');
str = [str{1} ': ' strjoin(str(2:4),'-')];
suptitle(str);

end