function fig = plotGroupedScatter(T,varName)
%% PLOTGROUPEDSCATTER   Function to make scatter plot of scalar data by day and group
%
%  fig = PLOTGROUPEDSCATTER(T);
%
%  --------
%   INPUTS
%  --------
%     T        :     Table returned from GETPROP method of GROUP class.
%                    To group by multiple groups from RC project, needs to
%                    be data that has been split into the subgroups
%                    'Ischemia' and 'Intact'
%  
% By: Max Murphy  v1.0  2019-06-07  Original version (R2017a)

%%
if nargin < 2
   varName = T.Properties.VariableNames{end};
end


fig = figure('Name',sprintf('%s scatter by group',varName),...
   'Units','Normalized',...
   'Color','w',...
   'Position',[0.3 0.3 0.4 0.4]);

ax_bot = axes(fig,...
   'NextPlot','add',...
   'XColor','k',...
   'YColor','k',...
   'YScale','linear',...
   'XScale','linear',...
   'Units','Normalized',...
   'Position',[0.1 0.1 0.8 0.35],...
   'LineWidth',1.5);
xlabel('Post-Op Day','Color','k','FontName','Arial','FontSize',14);
ylabel(varName,'Color','k','FontName','Arial','FontSize',14);

ax_top = axes(fig,...
   'NextPlot','add',...
   'XColor','k',...
   'YColor','k',...
   'YScale','linear',...
   'XScale','linear',...
   'Units','Normalized',...
   'Position',[0.1 0.6 0.8 0.35],...
   'LineWidth',1.5);
xlabel('Behavior % Success','Color','k','FontName','Arial','FontSize',14);
ylabel(varName,'Color','k','FontName','Arial','FontSize',14);

u = unique(T.Rat);
iIschemia = 0;
iIntact = 0;
rat_marker = defaults.group('rat_marker');
for iU = 1:numel(u)
   S = T(ismember(T.Rat,u{iU}),:);
   switch lower(S.Group{1})
      case 'ischemia'
         iIschemia = iIschemia + 1;
         mrk_idx = iIschemia;
         col = 'r';
      case 'intact'
         iIntact = iIntact + 1;
         mrk_idx = iIntact;
         col = 'b';
      otherwise
         mrk_idx = 1;
         col = 'k';
   end
   
   scatter(ax_bot,S.PostOpDay,S.(varName)(:,1),20,'filled',col,...
      'MarkerFaceColor',col,...
      'MarkerEdgeColor',col,...
      'Marker',rat_marker{mrk_idx});   
   scatter(ax_top,S.Score*100,S.(varName)(:,1),20,'filled',col,...
      'MarkerFaceColor',col,...
      'MarkerEdgeColor',col,...
      'Marker',rat_marker{mrk_idx});   
         
end

end