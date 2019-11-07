function ax = addToAx_PlotScoreByDay(obj,ax,do_not_modify_properties,legOpts)
%% ADDTOAX_PLOTSCOREBYDAY    obj.ADDTOAX_PLOTSCOREBYDAY(axToAddPlotTo)
%
%  ax = obj.ADDTOAX_PLOTSCOREBYDAY(ax);
%  ax = obj.ADDTOAX_PLOTSCOREBYDAY(ax,do_not_modify_properties)
%
%  --------
%   INPUTS
%  --------
%     ax       :     Axes object to add plot to. If not specified, uses
%                       current axes.
%
%  do_not_modify_properties  :  (Optional) Flag (default: false). If set to
%                                   true, will not reset any of the axes
%                                   properties.
%  
%

%% PARSE INPUT
if nargin < 2
   ax = gca;
end

if nargin < 3
   do_not_modify_properties = false;
end

if nargin < 4
   legOpts = defaults.rat('ch_mod_legopts');
end

%% GET PARAMETERS
% Parse parameters for coloring lines, smoothing plots
[cm,nColorOpts] = defaults.load_cm;
idx = round(linspace(1,size(cm,1),nColorOpts)); 

%% SET AXES PROPERTIES
if ~do_not_modify_properties
   ax.NextPlot = 'add';
   ax.XLim = [0 nColorOpts+1];
   ax.YLim = legOpts.yLim;
   ax.XColor = 'k';
   ax.YColor = 'w';
   ax.FontName = 'Arial';  
   ax.FontSize = 10;
   ax.LineWidth = 1.5;
   ax.YAxisLocation = 'right';
end
plot(ax,getProp(obj.Children,'PostOpDay'),...
   getProp(obj.Children,'TrueScore').*legOpts.scoreScale+legOpts.scoreOffset,...
   'Color',[0.3 0.3 0.3],...
   'LineStyle','--','LineWidth',1.5)         
line(ax,[0 nColorOpts+1],[legOpts.scoreOffset, legOpts.scoreOffset],...
   'Color',[0.6 0.6 0.6],...
   'LineWidth',1,'LineStyle',':');

if isempty(obj.chMod)
   obj.updateChMod;
end

labelAreaFlag = true;
text_vert_offset_opts = legOpts.textOffset;
text_vert_offset_idx = 1;
for ii = 1:numel(obj.Children)
   text_vert_offset = text_vert_offset_opts(text_vert_offset_idx);
   if ~obj.Children(ii).HasAreaModulations
      continue; % Skip days where average rate by conditions doesn't exist
   end
   poDay = obj.Children(ii).PostOpDay;
   str = sprintf('D%02g',poDay);
   nTrial = obj.Children(ii).nTrialRecent.rate;
   
   % Plot "modulations" for the CFA and RFA channels. If this is the first
   % time through the loop, then add the 'CFA' and 'RFA' labels as text
   % annotations on the axes
   if nTrial >= legOpts.minTrials
      bar(ax,poDay,obj.Children(ii).chMod.CFA*legOpts.barScale,1,...
         'EdgeColor','none',...
         'FaceColor',cm(idx(poDay),:),...
         'Tag',[str '-CFA'],...
         'UserData',[poDay,ii]);
      bar(ax,poDay,-obj.Children(ii).chMod.RFA*legOpts.barScale,1,...
         'EdgeColor','k',...
         'LineStyle','-',...
         'LineWidth',1.5,...
         'FaceColor',cm(idx(poDay),:),...
         'Tag',[str '-RFA'],...
         'UserData',[poDay,ii]);
   end
   if labelAreaFlag
      text(ax,poDay-2.5,legOpts.cfaTextY,'CFA',...
         'FontName','Arial',...
         'FontSize',12,...
         'FontWeight','normal',...
         'Color','k');
      text(ax,poDay-2.5,legOpts.rfaTextY,'RFA',...
         'FontName','Arial',...
         'FontSize',12,...
         'FontWeight','bold',...
         'Color','k');
      labelAreaFlag = false;
   end
   
   % Plot the "by-day" score (TrueScore == scoring from annotated videos
   % used for neurophysiological alignment; excluded "failed" trials where
   % the pellet was not present so that those didn't count against the
   % overall success rate). 
   y_score = obj.Children(ii).TrueScore.*legOpts.scoreScale+legOpts.scoreOffset;
   if nTrial >= legOpts.minTrials
      scatter(ax,poDay,y_score,legOpts.scatterMarkerSize,...
         'MarkerFaceColor',cm(idx(poDay),:),...
         'LineWidth',1.5,...
         'MarkerEdgeColor','k');
   else
      scatter(ax,poDay,y_score,legOpts.scatterMarkerSize,...
         'MarkerFaceColor','none',...
         'LineWidth',0.75,...
         'MarkerEdgeColor','k');
   end
   
   % Add the total number of trials of that particular type, next to the
   % score scatter, so we know how many trials were averaged together on
   % each day.
   text(ax,poDay,y_score+text_vert_offset,sprintf('(%g)',nTrial),...
      'FontName','Arial','FontSize',10,...
      'Color','k','FontWeight','normal',...
      'HorizontalAlignment','center');
   text_vert_offset_idx = 3 - text_vert_offset_idx; % alternate above/below
   

end
title(ax,'Score (# Trials)','FontName','Arial',...
   'Color','k','FontSize',14);
xlabel(ax,'Post-Op Day',...
   'FontSize',14,'Color','k',...
   'FontName','Arial','FontWeight','bold');
ylabel(ax,legOpts.axYLabel,...
   'FontSize',12,'Color','k',...
   'FontName','Arial');


end