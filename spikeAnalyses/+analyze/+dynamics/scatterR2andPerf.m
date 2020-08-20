function fig = scatterR2andPerf(E,nAx)
%SCATTERR2ANDPERF Scatter R^2_BEST on x-axis and y-axis as behavioral perf
%
%  fig = analyze.dynamics.scatterR2andPerf(E);
%  fig = analyze.dynamics.scatterR2andPerf(E,nAx);
%
% Inputs
%  E - Table with grouped data from linearized dynamics fits
%  nAx - 2 | default (R2 & Performance)
%        3 | (R2 & Performance & PostOpDay)
%
% Output
%  fig - Figure handle

if nargin < 2
   nAx = 2;
end

fig = figure('Name','Grouped Scatter with Explained as Size Data',...
   'Color','w','Units','Normalized','Position',[0.2 0.2 0.4 0.4]);
ax = axes(fig,'XColor','k','YColor','k','NextPlot','add','FontName','Arial');
C = [0.9 0.1 0.1; ... % RC-02
     0.9 0.1 0.1; ... % RC-04
     0.9 0.1 0.1; ... % RC-05
     0.9 0.1 0.1; ... % RC-08
     0.1 0.1 0.9; ... % RC-14
     0.9 0.1 0.1; ... % RC-26
     0.9 0.1 0.1; ... % RC-30
     0.1 0.1 0.9];    % RC-43
MRK = 'xshpo.^s';
SZ = 12;
ALPHA = 0.5;

switch nAx
   case 2
      gscatter(ax,...
         E.R2_Best,...
         E.Performance,...
         E.AnimalID,...
         C,MRK,SZ,'on');
      set(ax,'XLim',[0 1],'YLim',[-1 1]);
      xlabel(ax,'R^2_{MLS}','FontName','Arial','Color','k');
      ylabel(ax,'Performance','FontName','Arial','Color','k');
      title(ax,'Observed Data for Main Model','FontName','Arial','Color','k');
   case 3
      U = unique(E.AnimalID);
      for iU = 1:numel(U)
         c = C(iU,:);
         mrk = MRK(iU);
         idx = E.AnimalID==U(iU);
         x = ([E.PostOpDay(idx), E.PostOpDay(idx), nan(sum(idx),1)])';
         y = ([E.R2_Best(idx), E.R2_Best(idx), nan(sum(idx),1)])';
         z = ([ones(sum(idx),1).*-1, E.Performance(idx), nan(sum(idx),1)])';
         
         line(ax,x(:),y(:),z(:),...
            'MarkerSize',SZ,'Color',c,'Marker',mrk,'MarkerFaceColor','none',...
            'LineWidth',1.5,'MarkerIndices',2:3:numel(z),'LineStyle',':',...
            'DisplayName',string(U(iU)));
      end
      view(ax,3);
      xlabel(ax,'Post-Op Day','FontName','Arial','Color','k');
      ylabel(ax,'R^2_{MLS}','FontName','Arial','Color','k');
      zlabel(ax,'Performance','FontName','Arial','Color','k');
      title(ax,'Observed Data for Main Model','FontName','Arial','Color','k');
      legend(ax,'Location','eastoutside','TextColor','black','FontName','Arial');
      set(ax,'XLim',[0 30],'YLim',[0 1],'ZLim',[-1 1]);
      box(ax,'on');
      grid(ax,'on');
   otherwise
      error('Unexpected value of `nAx` (%g)\n',nAx);
      
end

end