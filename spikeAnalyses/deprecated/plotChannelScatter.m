function fig = plotChannelScatter(T,loglinearYscale)
%% PLOTCHANNELSCATTER   Function to make scatter plot of scalar data by day and group
%
%  fig = PLOTCHANNELSCATTER(T);
%
%  --------
%   INPUTS
%  --------
%     T        :     Table returned from GETCHANNELPROP method of GROUP 
%                    class. To group by multiple groups from RC project, 
%                    needs to be data that has been split into the 
%                    subgroups 'Ischemia' and 'Intact'
%
%  loglinearYscale : (Optional) Can be 'log' or 'linear' (for scaling of
%                                y-axis)
%  
% By: Max Murphy  v1.0  2019-06-07  Original version (R2017a)

%%
if nargin < 2
   loglinearYscale = 'log';
end

varName = T.Properties.VariableNames{end};
fig = figure('Name',sprintf('%s scatter by group',varName),...
   'Units','Normalized',...
   'Color','w',...
   'Position',[0.3 0.3 0.4 0.4]);

ax = axes(fig,...
   'NextPlot','add',...
   'XColor','k',...
   'YColor','k',...
   'XScale','linear',...
   'YScale',loglinearYscale,...
   'Units','Normalized',...
   'Position',[0.1 0.1 0.8 0.8],...
   'LineWidth',1.5);
xlabel([strrep(varName,'_','-') '_1'],...
   'Color','k','FontName','Arial','FontSize',14);
ylabel([strrep(varName,'_','-') '_2'],...
   'Color','k','FontName','Arial','FontSize',14);

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
   
   scatter(ax,S.(varName)(:,1),S.(varName)(:,2),20,'filled',col,...
      'MarkerFaceColor',col,...
      'MarkerEdgeColor',col,...
      'Marker',rat_marker{mrk_idx});    
         
end

end