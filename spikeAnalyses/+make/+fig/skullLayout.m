function gObj = skullLayout(nRow,nCol,nonSkullAxes,skullAxes,varargin)
%SKULLLAYOUT Make figure with skull layouts on some subset of axes
%
%  gObj = make.fig.skullLayout(); 
%     -> Default is 2x2 grid, where "nonSkullAxes" is top-2 columns, and
%        bottom 2 columns are each a unique "skullAxes"
%  gObj = make.fig.skullLayout(nAxes); 
%           -> Automatically parses <nRow,nCol> based on total number of
%              axes.
%  gObj = make.fig.skullLayout(nRow,nCol,nonSkullAxes,skullAxes);
%  gObj = make.fig.skullLayout(__,'name',value,...);
%
%  Example:
%     gObj = make.fig.skullLayout(2,2,{[1,2]},{3});
%     -> Make 2x2 grid layout; top-2 axes are one "non-skull" axes; only
%        other axes is the "bottom-left" axes, which is a skull axes.
%
% Inputs
%  nRow         - Scalar integer. Number of rows in subplot grid layout
%  nCol         - Scalar integer. Number of columns in subplot grid layout
%  nonSkullAxes - Cell array. Specify as empty cell {} if no non-skull
%                             axes. Each element contains indexing of
%                             subplot indices (which increment in value
%                             from left-to-right); cell arrays containing
%                             vectors indicate that those subplots get
%                             combined into one axes.
%  skullAxes    - Cell array. Same syntax as nonSkullAxes. 
%  varargin     - 'Name',value parameter pairs
%
% Outputs
%  gObj         - Struct containing the following fields:
%                 * 'Figure' - Figure containing all axes.
%                 * 'NonSkullAxes' - Array containing axes that 
%                                    correspond in order to elements
%                                    specified by the `nonSkullAxes` input
%                 * 'SkullAxes'    - Array containing axes that 
%                                    correspond in order to elements
%                                    specified by the `skullAxes` input
%                 * 'SkullObj'     - Array of ratskull_plot objects
%                                    corresponding to elements of SkullAxes

pars = struct;
pars.FontParams = {'FontName','Arial','FontWeight','bold','Color','w'};
pars.FigureColor = [0 0 0];
pars.GroupID = {'Intact'};
pars.Name = 'Skull Plot Figure';
pars.NonSkullAxesParams = {...
   'XTick',[],'YTick',[],...
   'XLim',[-5 5],'YLim',[-5 5],...
   'NextPlot','add', ...
   'XColor','none','YColor','none',...
   'Color',[0 0 0]};
pars.Position = [0.2 0.2 0.6 0.6];
pars.SkullAxesParams = {...
   'XTick',[],'YTick',[],...
   'FontName','Arial',...
   'Color','none',...
   'NextPlot','add'};
pars.SkullTitle = {''};
pars.SkullLabel = {''};
% pars.SkullYAxisLocation = {'left'};
pars.Units = 'Normalized';
fn = fieldnames(pars);

switch nargin
   case 0
      nRow = 2;
      nCol = 2;
      nonSkullAxes = {[1,2]};
      skullAxes = {3,4};
   case 1
      nTotal = nRow;
      nRow = floor(sqrt(nTotal));
      nCol = ceil(nTotal/nRow);
      nonSkullAxes = {[1,2]};
      skullAxes = {3,4};
   case 2
      if nRow > 1
         nonSkullAxes = {1:nCol};
      else
         nonSkullAxes = {1};
      end
      if nRow > 1
         skullAxes = {(nCol+1):(nRow*nCol)};
      else
         skullAxes = {2:nCol};
      end
   case 3
      m = max(cellfun(@(C)max(C),skullAxes));
      nonSkullAxes = {(m+1):(nRow*nCol)};
   otherwise % Check if pars was passed directly
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

nNonSkullAxes = numel(nonSkullAxes);
nSkullAxes = numel(skullAxes);
if isscalar(pars.GroupID)
   pars.GroupID = repmat(pars.GroupID,nSkullAxes,1);
end
if isscalar(pars.SkullTitle)
   pars.SkullTitle = repmat(pars.SkullTitle,nSkullAxes,1);
end
if isscalar(pars.SkullLabel)
   pars.SkullLabel = repmat(pars.SkullLabel,nSkullAxes,1);
end
% if isscalar(pars.SkullYAxisLocation)
%    pars.SkullYAxisLocation = repmat(pars.SkullYAxisLocation,nSkullAxes,1);
% end

% Make graphics objects containers for movie %
fig = figure(...
   'Name',pars.Name,...
   'Units',pars.Units,...
   'Position',pars.Position,...
   'Color',pars.FigureColor,...
   'NumberTitle','off',...
   'MenuBar','none',...
   'Toolbar','none');

% % % Assign outputs % % % 
gObj = struct;
gObj.Figure = fig;
gObj.NonSkullAxes = gobjects(nNonSkullAxes,1);
gObj.SkullAxes = gobjects(nSkullAxes,1);
gObj.SkullObj = ratskull_plot([nSkullAxes,1]);

% % 1) Get NonSkullAxes (and corresponding titles) % %
for iAx = 1:nNonSkullAxes
   gObj.NonSkullAxes(iAx) = subplot(nRow,nCol,nonSkullAxes{iAx});
   set(gObj.NonSkullAxes(iAx),'Parent',fig,pars.NonSkullAxesParams{:},...
      'Tag',sprintf('NonSkullAxes-%02d',iAx));
   title(gObj.NonSkullAxes(iAx),'',pars.FontParams{:});
   xlabel(gObj.NonSkullAxes(iAx),'',pars.FontParams{:});
   ylabel(gObj.NonSkullAxes(iAx),'',pars.FontParams{:});
end

% % 2) Get SkullAxes and SkullObj pairs % %
for iAx = 1:nSkullAxes
   gObj.SkullAxes(iAx) = subplot(nRow,nCol,skullAxes{iAx});
   gObj.SkullObj(iAx) = make.fig.skullPlot(pars.GroupID,...
      'axes',gObj.SkullAxes(iAx));
   set(gObj.SkullAxes(iAx),'Parent',fig,...
      ... 'YAxisLocation',pars.SkullYAxisLocation{iAx},...
      'Tag',sprintf('SkullAxes-%02d',iAx),...
      pars.SkullAxesParams{:});
   title(gObj.SkullAxes(iAx),pars.SkullTitle{iAx},pars.FontParams{:});
   ylabel(gObj.SkullAxes(iAx),'',pars.FontParams{:});
   xlabel(gObj.SkullAxes(iAx),pars.SkullLabel{iAx},pars.FontParams{:});
   gObj.SkullObj(iAx).Name = pars.SkullLabel{iAx};
end


set(fig,'Color',pars.FigureColor);

end