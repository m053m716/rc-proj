function fig = scatter_var(Gr,responseVar,varargin)
%SCATTER_VAR Make grouped scatter plot of response variable by day
%
%  fig = analyze.stat.scatter_var(Gr);
%  fig = analyze.stat.scatter_var(Gr,responseVar);
%  fig = analyze.stat.scatter_var(Gr,responseVar,'Name',value,...);
%
% Inputs
%  Gr  - Reduced dataset (table) see analyze.stat.remove_excluded
%  responseVar - Name of response variable to use (default: 'PeakOffset')
%        -> Returns multiple figures if supplied as cell array
%  varargin - (Optional) 'Name',value parameter pairs
%  
% Output
%  fig - Figure handle of output figure

if nargin < 2
   responseVar = 'PeakOffset';
end

pars = struct;
utils.addHelperRepos();
pars.AddLabel = true;
pars.AxParams = {'NextPlot','add','XColor','k','YColor','k',...
   'LineWidth',1.5,'FontName','Arial'};
pars.ChLineWidth = 0.015;
pars.Color = [0 0 1; 0.2 0.2 0.8; 1 0 0; 0.8 0.2 0.2];
pars.EdgeAlpha = 0.30; % Edge of CB shaded error patches
pars.FaceAlpha = 0.25; % Face of CB shaded error patches
pars.FigParams = {'Color','w','Units','Normalized',...
   'Position',gfx__.addToSecondMonitor};
pars.FontParams = {'FontName','Arial','Color','k'};
pars.formatspec = '%5.1f';
pars.Group = ["Intact","RFA"; ...
              "Intact","CFA"; ...
              "Ischemia","RFA"; ...
              "Ischemia","CFA"];
pars.GroupVar = ["GroupID","Area"];
pars.Jitter = 0.05;
pars.MarkerEdgeAlpha = 0.25;
pars.MarkerFaceAlpha = 0.25;
pars.MarkerSize = 12;
pars.RegressionType = "logistic";
pars.ScatterParams = {};
pars.ScatterType = 'trials';
pars.ShowAnimals = true;
pars.ShowCB = true;
pars.ShowChannels = false;
pars.ShowGrandAverage = true;
pars.XLabLoc = [-2.25;-2.25;-2.25;-2.25];
pars.XPlot = linspace(3,30,100);
pars.YLim = [nan nan];
pars.YLab = '';

if nargin >= 3
   if isstruct(varargin{1})
      pars = varargin{1};
      varargin(1) = [];
   end
end

fn = fieldnames(pars);
for iV = 1:2:numel(varargin)
   iParam = strcmpi(fn,varargin{iV});
   if sum(iParam)==1
      pars.(fn{iParam}) = varargin{iV+1};
   end
end

if iscell(responseVar)
   fig = [];
   if ~isempty(pars.YLab)
      if isscalar(pars.YLab) || ischar(pars.YLab)
         yl = repelem(string(pars.YLab),numel(responseVar),1);
      else
         yl = pars.YLab;
      end
   end
   for ii = 1:numel(responseVar)
      if ~isempty(pars.YLab)
         p = pars;
         p.YLab = yl(ii);
         fig = [fig; ...
            analyze.stat.scatter_var(Gr,responseVar{ii},p)]; %#ok<AGROW>
      else
         fig = [fig; ...
            analyze.stat.scatter_var(Gr,responseVar{ii},pars)]; %#ok<AGROW>
      end
      
   end
   return;
end

if pars.ShowChannels
   pars.AddLabel = false;
end

fig = figure(...
   'Name',sprintf('Grouped %s scatter by Post-Op Day',responseVar),...
   pars.FigParams{:});   
figure(fig);

nTotal = size(pars.Group,1);
nCol = floor(sqrt(nTotal));
nRow = ceil(nTotal/nCol);

yLimExtrema = [inf, -inf];
ax = [];
o = pars.ChLineWidth;
Xf = ([pars.XPlot+o, fliplr(pars.XPlot-o)])';
F = [1:numel(Xf),1];

iVar = strcmp(Gr.Properties.VariableNames,responseVar);
unit = Gr.Properties.VariableUnits{iVar};

for iG = 1:nTotal
   ax = [ax; subplot(nRow,nCol,iG)];  %#ok<AGROW>
   set(ax(iG),pars.AxParams{:});
   idx = true(size(Gr,1),1);
   for igg = 1:numel(pars.GroupVar)
      idx = idx & (Gr.(pars.GroupVar(igg))==pars.Group(iG,igg));
   end
   G = Gr(idx,:);
   str = strjoin(pars.Group(iG,:),'::');
   gThis= findgroups(G(:,{'AnimalID'}));
   p = pars;
   if pars.AddLabel
      p.AddLabel = [char(str) ': '];
   end
   p.TX = pars.XLabLoc(iG);
   switch lower(pars.ScatterType)
      case {'trials','trial','individual'}
         splitapply(@(x,y,a)analyze.stat.addJitteredScatter(...
            ax(iG),x,y,a,pars.Color(iG,:),p),...
               G.PostOpDay,G.(responseVar),G.AnimalID,gThis);
      case {'averages','channel','channels','mean','means'}
         for igg = 1:max(gThis)
            iThis = findgroups(G(:,{'ChannelID','PostOpDay'}));
            thisRat = G.AnimalID(gThis==igg);
            thisRat = strrep(char(thisRat(1)),'-','');
            [xDay,yS] = splitapply(@meanByDay,G.PostOpDay,G.(responseVar),iThis);
            xDay(isnan(yS)) = [];
            yS(isnan(yS)) = [];
            xj = xDay+randn(size(xDay)).*pars.Jitter;
            if ~isfield(pars,'Marker')
               marker = defaults.experiment('marker');
               mrk_this = marker.(thisRat);
            else
               mrk_this = pars.Marker;
            end
            scatter(ax(iG),xj,yS,'filled',...
               'Marker',mrk_this,...
               'MarkerFaceAlpha',pars.MarkerFaceAlpha,...
               'MarkerEdgeAlpha',pars.MarkerEdgeAlpha,...
               'SizeData',pars.MarkerSize,...
               'LineWidth',1.5,...
               pars.ScatterParams{:},...
               'MarkerEdgeColor',pars.Color(iG,:),...
               'MarkerFaceColor',pars.Color(iG,:),...
               'DisplayName',thisRat); 
         end
      otherwise
         error('Unexpected case: %s',pars.ScatterType);
   end
      
   if pars.ShowChannels
      for igg = 1:max(gThis)
         A = G(gThis==igg,:);
         cThis = findgroups(A(:,{'ChannelID'}));
         Y = splitapply(@(x,y)analyze.stat.addLinearRegression(...
               ax(iG),x,y,pars.Color(iG,:).*0.75,pars.XPlot,...
               'LineStyle',':','LineWidth',1,'plotline',false),...
               A.PostOpDay,A.(responseVar),cThis);
         Y = cell2mat(Y);
         Y(any(isnan(Y)|isinf(Y),2),:) = [];
         Yf = mean(Y,1)';
         V = [Xf, [Yf+o; flipud(Yf)-o]];
         patch(ax(iG),'Faces',F,'Vertices',V,...
            'FaceAlpha',pars.FaceAlpha,...
            'EdgeAlpha',pars.EdgeAlpha,...
            'FaceColor',pars.Color(iG,:),...
            'EdgeColor',pars.Color(iG,:));
         if pars.ShowCB
            gfx__.plotWithShadedError(ax(iG),pars.XPlot',Y',...
               'LineStyle',':',...
               'FaceColor',pars.Color(iG,:),...
               'Color',pars.Color(iG,:),...
               'FaceAlpha',pars.FaceAlpha);
         end
      end
   end
   
   if pars.ShowGrandAverage
      dThis = findgroups(G(:,{'PostOpDay'}));
      [xU,yAvg] = splitapply(@meanByDay,G.PostOpDay,G.(responseVar),dThis);
      [yLB,yUB] = splitapply(@groupByDay,G.(responseVar),dThis);
      iBad = isnan(yLB) | isnan(yUB) | isnan(yAvg) | isinf(yAvg) | isinf(yLB) | isinf(yUB);
      err = [yLB(~iBad),yUB(~iBad)];
      if (size(err,1) > 1) && (pars.ShowCB) && (~pars.ShowChannels)
         gfx__.plotWithShadedError(ax(iG),xU(~iBad),yAvg(~iBad),err,...
            'LineStyle',':','Annotation','on','DisplayName','Group Mean');
      end
      
      switch lower(pars.RegressionType)
         case 'linear'
            yGM = analyze.stat.addLinearRegression(ax(iG),xU,yAvg,[0 0 0],...
            	pars.XPlot,'LineWidth',2,'LineStyle','-',...
               'DisplayName',sprintf('%s (Grand Average)',str));
         case 'logistic'
            yGM = analyze.stat.addLogisticRegression(ax(iG),xU,yAvg,[0 0 0],...
            	pars.XPlot,'LineStyle','-','LineWidth',2,...
               'DisplayName',sprintf('%s (Grand Average)',str));
         otherwise
            error('Unrecognized case: %s',pars.RegressionType);
      end
      if isempty(unit)
         text(ax(iG),-2.5,yGM{1}(1),sprintf(pars.formatspec,yGM{1}(1)),...
            'Color',pars.Color(iG,:),...
            'FontName','Arial',...
            'FontWeight','bold',...
            'FontSize',10);
         text(ax(iG),30.5,yGM{1}(end),sprintf(pars.formatspec,yGM{1}(end)),...
            'Color',pars.Color(iG,:),...
            'FontName','Arial',...
            'FontWeight','bold',...
            'FontSize',10);
      else
         text(ax(iG),-2.75,yGM{1}(1),sprintf([pars.formatspec '(%s)'],...
            yGM{1}(1),unit),...
            'Color',pars.Color(iG,:),...
            'FontName','Arial',...
            'FontWeight','bold',...
            'FontSize',10);
         text(ax(iG),30.5,yGM{1}(end),sprintf([pars.formatspec '(%s)'],...
            yGM{1}(end),unit),...
            'Color',pars.Color(iG,:),...
            'FontName','Arial',...
            'FontWeight','bold',...
            'FontSize',10);
      end
      
   end
      
   xlabel(ax(iG),'Post-Op Day',pars.FontParams{:});
   xlim(ax(iG),[-3 30]);
   
   if isempty(pars.YLab)
      if isempty(unit)
         ylabel(ax(iG),strrep(responseVar,'_',' '),pars.FontParams{:});
      else
         ylabel(ax(iG),sprintf('%s (%s)',strrep(responseVar,'_',' '),unit),pars.FontParams{:});
      end
   else
      if isempty(unit)
         ylabel(ax(iG),pars.YLab,pars.FontParams{:});
      else
         ylabel(ax(iG),sprintf('%s (%s)',pars.YLab,unit),pars.FontParams{:});
      end
   end
   title(ax(iG),strrep(str,'_',' '),pars.FontParams{:});

   yLimExtrema(1) = min(yLimExtrema(1),ax(iG).YLim(1));
   yLimExtrema(2) = max(yLimExtrema(2),ax(iG).YLim(2));
   
   if ~pars.ShowAnimals
      legend(ax(iG),'Location','Best');
   end
   
end

if ~any(isnan(pars.YLim))
   yLimExtrema = pars.YLim;
end

for iG = 1:nTotal
   ax(iG).YLim = yLimExtrema; %#ok<AGROW>
end

drawnow;

   function [x,y] = meanByDay(X,Y)
      %GROUPBYDAY Helper function takes group mean of data by day
      %
      %  [x,y] = meanByDay(X,Y);
      %
      % Inputs
      %  X - Post-Op Days
      %  Y - Data corresponding to those days
      %
      % Output
      %  x - Unique post-op days
      %  y - Data averaged over unique post-op days
      
      x = X(1);
      ygood = Y(~isnan(Y) & ~isinf(Y));
      if numel(ygood) > 0
         y = mean(ygood);
      else
         y = nan;
      end
   end

   function [ylb,yub] = groupByDay(Y)
      %GROUPBYDAY Helper function groups data by day
      %
      %  [ylb,yub] = groupByDay(Y);
      %
      % Inputs
      %  Y - Data corresponding to those days
      %
      % Output
      %  ylb - 95% Lower-bound on data at this day
      %  yub - 95% Upper-bound on data at this day
      
      y = sort(Y(~isnan(Y) & ~isinf(Y)),'ascend');
      if isempty(y)
         ylb = nan;
         yub = nan;
         return;
      elseif numel(y)==1
         ylb = y;
         yub = y;
         return;
      end
      iLB = ceil(0.05*numel(y));
      iUB = floor(0.95*numel(y));
      ylb = y(iLB);
      yub = y(iUB);
   end

end