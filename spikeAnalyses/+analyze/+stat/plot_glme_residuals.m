function [fig,ax] = plot_glme_residuals(glme,Gr,groupings,TID,varargin)
%PLOT_GLME_RESIDUALS Plot generalized linear mixed-effects model residuals
%
%  [fig,ax] = analyze.stat.plot_glme_residuals(glme,Gr,groupings,TID);
%  [__] = analyze.stat.plot_glme_residuals(glme,Gr,groupings,TID,...
%           'name',value,...);
%
% Inputs
%  glme - Fit glme object
%  Gr   - Data table used to fit glme
%  varargin - (Optional) Pairs of 'Name',value input arguments
%     * 'fig' - Figure handle
%     * 'ax'  - Axes handle
%
% Output
%  fig - Generated figure handle
%  ax  - Generated axes handle

% Set parameters
p = struct('ax',[],'fig',[],'mdlIndex',1,...
   'xVar','PostOpDay',...
   'yVar','PeakOffset',...
   'scatterAlpha',0.15,...
   'scatterSize',12);
fn = fieldnames(p);
for iV = 1:2:numel(varargin)
   iP = strcmpi(fn,varargin{iV});
   if sum(iP)==1
      p.(fn{iP}) = varargin{iV+1};
   end
end

if isempty(p.fig)
   if isempty(p.ax)
      fig = figure(...
         'Name','GLME Grouped Residuals',...
         'Units','Normalized',...
         'NumberTitle','off',...
         'Color','w',...
         'Position',[0.1 0.1 0.8 0.8]);
   else
      fig = get(p.ax,'Parent');
      while(~isa(fig,'matlab.ui.Figure'))
         fig = get(fig,'Parent');
      end
   end
else
   fig = p.fig;
end

if isempty(p.ax)
   ax = axes(fig);
else
   ax = p.ax;
end

nTotal = max(groupings);
nRow = floor(sqrt(nTotal));
nCol = ceil(nTotal/nRow);
varNames = Gr.Properties.VariableNames;
Ypred = splitapply(@(varargin){glme.predict(table(varargin{:},'VariableNames',varNames))},Gr,groupings);
Yact = splitapply(@(y){y},Gr.(p.yVar),groupings);
% Y = cellfun(@(C1,C2)C1-C2,Yact,Ypred,'UniformOutput',false);
% X = splitapply(@(x){x},Gr.(p.xVar),groupings);
for ii = 1:nTotal
   ax = subplot(nRow,nCol,ii);
   set(ax,'XColor','k','YColor','k','LineWidth',1.25,...
      'FontName','Arial','NextPlot','add');
%    set(ax,'View',[30 45]);
%    scatter3(ax,X{ii},Yact{ii},Y{ii},'filled','MarkerFaceColor',...
%       'r','MarkerEdgeColor','r');
%    scatter3(ax,X{ii},Ypred{ii},Y{ii},'filled','MarkerFaceColor',...
%       'k','MarkerEdgeColor','k','Marker','.');
%    legend(ax,{'Actual','Predicted'},'Location','best');
   scatter(ax,Yact{ii},Ypred{ii},'filled','SizeData',p.scatterSize,...
      'MarkerFaceColor','r','MarkerEdgeColor','none',...
      'MarkerFaceAlpha',p.scatterAlpha);
   str = '';
   if nargin > 3
      for ik = 1:size(TID,2)
         gThis = TID.(TID.Properties.VariableNames{ik})(ii);
         if isnumeric(gThis)
            str = [str ' - ' num2str(gThis)]; %#ok<*AGROW>
         else
            str = [str ' - ' char(gThis)];
         end
      end
      str(1:3) = [];
   else
      str = sprintf('Grouping: %02d',ii);
   end
   title(ax,str,'FontName','Arial','Color','k');
   xlabel(ax,sprintf('%s_{actual}',p.yVar),'FontName','Arial','Color','k');
   ylabel(ax,sprintf('%s_{pred}',p.yVar),'FontName','Arial','Color','k');
   % Add line indicating "X == Y"
   xl = ax.XLim;
   line(ax,xl,xl,...
      'Color','k','LineWidth',1.75,'LineStyle',':',...
      'DisplayName','y_{pred} = y_{actual}');
%    xlabel(ax,p.xVar,'FontName','Arial','Color','k');
%    ylabel(ax,sprintf('%s',p.yVar),'FontName','Arial','Color','k');
%    zlabel(ax,'Residuals','FontName','Arial','Color','k');
end

end