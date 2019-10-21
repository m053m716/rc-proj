function ax = addToAx_PlotScoreByDay(obj,ax,do_not_modify_properties)
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


%% GET PARAMETERS
% Parse parameters for coloring lines, smoothing plots
[cm,nColorOpts] = defaults.load_cm;
idx = round(linspace(1,size(cm,1),nColorOpts)); 

%% SET AXES PROPERTIES
if ~do_not_modify_properties
   ax.NextPlot = 'add';
   ax.XLim = [0 nColorOpts+1];
   ax.YLim = [-2 3.75];
   ax.XColor = 'k';
   ax.YColor = 'w';
   ax.FontName = 'Arial';  
   ax.FontSize = 10;
   ax.LineWidth = 1.5;
   ax.YAxisLocation = 'right';
end
plot(ax,getProp(obj.Children,'PostOpDay'),...
   getProp(obj.Children,'TrueScore').*2+1.5,...
   'Color',[0.3 0.3 0.3],...
   'LineStyle','--','LineWidth',1.5)         
line(ax,[0 nColorOpts+1],[1.5 1.5],'Color',[0.6 0.6 0.6],...
   'LineWidth',1,'LineStyle',':');

if isempty(obj.chMod)
   obj.updateChMod;
end

labelAreaFlag = true;
text_vert_offset_opts = [0.75,-0.85];
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
   if nTrial >= 10
      bar(ax,poDay,obj.Children(ii).chMod.CFA,1,...
         'EdgeColor','none',...
         'FaceColor',cm(idx(poDay),:),...
         'Tag',[str '-CFA'],...
         'UserData',[poDay,ii]);
      bar(ax,poDay,-obj.Children(ii).chMod.RFA,1,...
         'EdgeColor','k',...
         'LineStyle','-',...
         'LineWidth',1.5,...
         'FaceColor',cm(idx(poDay),:),...
         'Tag',[str '-RFA'],...
         'UserData',[poDay,ii]);
   end
   if labelAreaFlag
      text(ax,poDay-2.5,0.5,'CFA',...
         'FontName','Arial',...
         'FontSize',12,...
         'FontWeight','normal',...
         'Color','k');
      text(ax,poDay-2.5,-0.5,'RFA',...
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
   y_score = obj.Children(ii).TrueScore.*2+1.5;
   if nTrial >= 10
      scatter(ax,poDay,y_score,30,...
         'MarkerFaceColor',cm(idx(poDay),:),...
         'LineWidth',1.5,...
         'MarkerEdgeColor','k');
   else
      scatter(ax,poDay,y_score,30,...
         'MarkerFaceColor','none',...
         'LineWidth',0.75,...
         'MarkerEdgeColor','k');
   end
   
   % Add the total number of trials of that particular type, next to the
   % score scatter, so we know how many trials were averaged together on
   % each day.
   text(ax,poDay,y_score+text_vert_offset,num2str(nTrial),...
      'FontName','Arial','FontSize',10,...
      'Color','k','FontWeight','normal',...
      'HorizontalAlignment','center');
   text_vert_offset_idx = 3 - text_vert_offset_idx; % alternate above/below
   

end
title(ax,'Score','FontName','Arial',...
   'Color','k','FontSize',14);
xlabel(ax,'Post-Op Day',...
   'FontSize',14,'Color','k',...
   'FontName','Arial','FontWeight','bold');
ylabel(ax,'Relative Modulation',...
   'FontSize',12,'Color','k',...
   'FontName','Arial');


end