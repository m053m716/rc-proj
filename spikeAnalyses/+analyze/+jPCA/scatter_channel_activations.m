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
%              * 'group'   : Group index (default: 1)
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
pars.group = nan;
pars.plane = nan;
pars.block = randi(size(P,1),1,1);  
pars.ylim_rate = [-3 3];
pars.close_others = false;
pars.fig = [];
pos = [0.2+randn(1)*0.05 0.2+randn(1)*0.05 0.22 0.4];
pars.figparams = {...
   'Color','w',...
   'Units','Normalized',...
   'NumberTitle','off',...
   'MenuBar','none',...
   'ToolBar','none',...
   'Position',gfx__.addToSecondMonitor(pos)};
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
   'MarkerFaceAlpha',0.08,...
   'SizeData',8};
pars.scatterparams_p1 = {...
   'MarkerFaceColor','b',...
   'MarkerEdgecolor','none',...
   'MarkerFaceAlpha',0.10,...
   'SizeData',10};
pars.scatterparams_p2 = {...
   'MarkerFaceColor','b',...
   'MarkerEdgecolor','none',...
   'MarkerFaceAlpha',0.10,...
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

if isnan(pars.group)
   pars.group = randi(size(P{pars.block}(1).W_Key,1),1,1); 
end

if isnan(pars.plane)
   pars.plane = min(randi(floor(size(P{pars.block}(1).W,2)/2),1,1),3); 
end

if (pars.close_others) && isempty(pars.fig)
   close all force;
end

% % Create data arrays % %
W = vertcat(P{pars.block}.W); 
t = vertcat(P{pars.block}.times);
rates = vertcat(P{pars.block}.data);
xl = [min(t),max(t)];

channels = P{pars.block}(1).W_Groups==pars.group;

% % Create figure handle % %
str = strjoin(cellfun(@(C)string(C),...
   table2cell(P{pars.block}(1).W_Key(pars.group,:))),'::');

if isempty(pars.fig)
   pars.fig = figure(...
      'Name',sprintf('jPCA Grouped Activations: %s',str),...
      pars.figparams{:}); 
else
   clf(pars.fig);
end
fig = pars.fig;
figure(fig);
ax_p1 = subplot(2,2,3); 
set(ax_p1,'XLim',xl,pars.axparams{:});

% First component of jPCA plane
scatter(ax_p1,t,W(:,2*(pars.plane-1)+1,pars.group),'filled',...
   pars.scatterparams_p1{:}); 
title(ax_p1,sprintf('Plane-%02d_1',pars.plane)); 
xlabel(ax_p1,'Time (ms)',pars.fontparams{:});  

% Second component of jPCA plane
ax_p2 = subplot(2,2,4); 
set(ax_p2,'XLim',xl,'YAxisLocation','left',pars.axparams{:});
scatter(ax_p2,t,W(:,2*pars.plane,pars.group),'filled',...
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
r = rates(:,channels);
scatter(ax_rate,repmat(t,sum(channels),1),r(:),'filled',...
   pars.scatterparams_rate{:}); 

title(ax_rate,str,pars.fontparams{:});
xlabel(ax_rate,'Time (ms)',pars.fontparams{:}); 
ylabel(ax_rate,'Rates (spikes/sec)',pars.fontparams{:}); 
line(ax_rate,[0 0],pars.ylim_rate,...
   'Color','m','LineWidth',1.5,'LineStyle','--',...
   'DisplayName',pars.alignment);

str = [P{pars.block}(1).AnimalID sprintf('::Post-Op-D%02d',P{pars.block}(1).PostOpDay)];
suptitle(str);

fig.UserData = pars;

end