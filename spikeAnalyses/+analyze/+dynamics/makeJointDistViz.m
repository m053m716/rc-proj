function fig = makeJointDistViz(E,style)
%MAKEJOINTDISTVIZ  Visualize joint distribution between R2 & %-explained
%
%  fig = analyze.dynamics.makeJointDistViz(E);
%  fig = analyze.dynamics.makeJointDistViz(E,style);
%
% Inputs
%  E - Table from analyze.dynamics.exportTable(D); or
%                 analyze.dynamics.exportSubTable(D)
%  style - 'scatter' (def) | 'heatmap' | 'all'
%
% Output
%  fig - Figure handle
%
% See also: analyze.dynamics, analyze.jPCA,
%           population_firstorder_mls_regression_stats

if nargin < 2
   style = 'scatter';
end

if ismember('Explained_Best',E.Properties.VariableNames)
   expName = 'Explained_Best';
   E.(expName) = E.(expName).*100;
else
   expName = 'Explained';
end
xl = [min(E.(expName)), max(E.(expName))];

fig = figure('Name','Input Distribution: Joint Dist of Percent Explained',...
   'Color','w','Units','Normalized','Position',[0.25 0.25 0.3 0.4],...
   'UserData',E);

switch lower(style)
   case 'scatter'
      ax = axes(fig,'XColor','k','YColor','k','LineWidth',1.5,...
         'FontName','Arial','NextPlot','add','YLim',[0 1],'XLim',xl);
      gscatter(ax,E.(expName),E.R2_Best,categorical(E.Alignment),...
         [0.25 0.25 0.25; 0.6 0.6 0.6],'.x',10,'on','% Explained','R^2_{MLS}');
      title(ax,'Observed Values','FontName','Arial','Color','k','FontWeight','bold');
      set(get(ax,'XLabel'),'FontName','Arial','Color','k','FontWeight','bold');
      set(get(ax,'YLabel'),'FontName','Arial','Color','k','FontWeight','bold');
   case 'heatmap'
      ax = subplot(2,1,1);
      set(ax,'Parent',fig,'XColor','k','YColor','k','LineWidth',1.5,...
         'FontName','Arial','NextPlot','add','YLim',[0 1],'XLim',xl);
      % Only use unique values by block (so only 1 Grasp, only 1 Plane)
      iGrasp = E.Alignment=="Grasp";
      ksdensity(ax,[E.(expName)(iGrasp),E.R2_Best(iGrasp)],...
         'Kernel','normal',...
         'Bandwidth',0.25);
      c = get(ax,'Children');
      set(c,'EdgeColor','none');
      xlabel(ax,'\bf\itx\rm = % Explained','FontName','Arial','Color','k');
      ylabel(ax,'\bf\ity\rm = R^2_{MLS}','FontName','Arial','Color','k');
      title(ax,'Grasp','FontName','Arial','Color','k');
      colormap('jet');
      cb = colorbar(ax);
      cb.Label.String = 'pdf(\bf\itx\rm, \bf\ity\rm)';

      ax = subplot(2,1,2);
      set(ax,'Parent',fig,'XColor','k','YColor','k','LineWidth',1.5,...
         'FontName','Arial','NextPlot','add','YLim',[0 1],'XLim',xl);
      % Only use unique values by block (so only 1 Grasp, only 1 Plane)
      iReach = E.Alignment=="Reach";
      ksdensity(ax,[E.(expName)(iReach),E.R2_Best(iReach)],...
         'Kernel','normal',...
         'Bandwidth',0.25);
      c = get(ax,'Children');
      set(c,'EdgeColor','none');
      xlabel(ax,'\bf\itx\rm = % Explained','FontName','Arial','Color','k');
      ylabel(ax,'\bf\ity\rm = R^2_{MLS}','FontName','Arial','Color','k');
      title(ax,'Reach','FontName','Arial','Color','k');
      colormap('jet');
      cb = colorbar(ax);
      cb.Label.String = 'pdf(\bf\itx\rm, \bf\ity\rm)';
   case 'all'
      ax = subplot(2,2,1);
      set(ax,'Parent',fig,'XColor','k','YColor','k','LineWidth',1.5,...
         'FontName','Arial','NextPlot','add','YLim',[0 1],'XLim',xl);
      % Only use unique values by block (so only 1 Grasp, only 1 Plane)
      iGrasp = E.Alignment=="Grasp";
      ksdensity(ax,[E.(expName)(iGrasp),E.R2_Best(iGrasp)],...
         'Kernel','normal',...
         'Bandwidth',0.25);
      c = get(ax,'Children');
      set(c,'EdgeColor','none');
      xlabel(ax,'\bf\itx\rm = % Explained','FontName','Arial','Color','k');
      ylabel(ax,'\bf\ity\rm = R^2_{MLS}','FontName','Arial','Color','k');
      title(ax,'Grasp','FontName','Arial','Color','k');
      colormap('jet');
      cb = colorbar(ax);
      cb.Label.String = 'pdf(\bf\itx\rm, \bf\ity\rm)';

      ax = subplot(2,2,3);
      set(ax,'Parent',fig,'XColor','k','YColor','k','LineWidth',1.5,...
         'FontName','Arial','NextPlot','add','YLim',[0 1],'XLim',xl);
      % Only use unique values by block (so only 1 Grasp, only 1 Plane)
      iReach = E.Alignment=="Reach";
      ksdensity(ax,[E.(expName)(iReach),E.R2_Best(iReach)],...
         'Kernel','normal',...
         'Bandwidth',0.25);
      c = get(ax,'Children');
      set(c,'EdgeColor','none');
      xlabel(ax,'\bf\itx\rm = % Explained','FontName','Arial','Color','k');
      ylabel(ax,'\bf\ity\rm = R^2_{MLS}','FontName','Arial','Color','k');
      title(ax,'Reach','FontName','Arial','Color','k');
      colormap('jet');
      cb = colorbar(ax);
      cb.Label.String = 'pdf(\bf\itx\rm, \bf\ity\rm)';

      ax = subplot(2,2,[2,4]);
      set(ax,'Parent',fig,'XColor','k','YColor','k','LineWidth',1.5,...
         'FontName','Arial','NextPlot','add','YLim',[0 1],'XLim',xl);
      gscatter(E.(expName),E.R2_Best,categorical(E.Alignment),...
         [0.25 0.25 0.25; 0.6 0.6 0.6],'.x',10,'on','% Explained','R^2_{MLS}');
      title(ax,'Observed Values','FontName','Arial','Color','k','FontWeight','bold');
      set(get(ax,'XLabel'),'FontName','Arial','Color','k','FontWeight','bold');
      set(get(ax,'YLabel'),'FontName','Arial','Color','k','FontWeight','bold');
   otherwise
      error('Unrecognized style: "%s" (should be: ''scatter'' | ''heatmap'' | ''all'')\n',style);
end

end