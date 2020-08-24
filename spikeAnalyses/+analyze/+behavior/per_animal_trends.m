function [fig,mdl] = per_animal_trends(T,varargin)
%PER_ANIMAL_TRENDS Plot per-animal trends
%
%  [fig,mdl] = analyze.behavior.per_animal_trends(T);
%
% Inputs
%  T - Table of behavior with variables:
%        'Day','nSuccess','nTotal','AnimalID','GroupID','Percent_Successful'
%  varargin - (Optional) 'Name',value pairs
%           -> 'Title' : "" (def); title string for plot
%
% Output
%  fig - Figure handle
%  mdl - Cell array (by animal) 
% 
% See also: analyze.behavior, analyze.behavior.bar_animal_counts,
%           trial_outcome_stats

pars = struct;
pars.Color = struct;
pars.Color.Ischemia = [0.9 0.1 0.1];
pars.Color.Intact = [0.1 0.1 0.9];
pars.ErrorLineStyle = ':';
pars.ErrorLineWidth = 1.5;
pars.FaceAlpha = 0.35;
pars.LegendLocation = 'southeast';
pars.LegendStyle = 'standard'; % 'standard' | 'animals'
pars.LineWidth = 2.5;
pars.MarkerOrder = 'oshpv^';
pars.MarkerFaceAlpha = 0.45;
pars.Title = "";
pars.XLim = [nan nan];
pars.YLim = [0 100];


fn = fieldnames(pars);
for iV = 1:2:numel(varargin)
   idx = strcmpi(fn,varargin{iV});
   if sum(idx)==1
      pars.(fn{idx}) = varargin{iV+1};
   end
end

T.Day_Cubed = T.Day.^3;
if any(isnan(pars.XLim))
   xLim = [min(T.Day),max(T.Day)];
else
   xLim = pars.XLim;
end

fig = figure('Name','Success by Day (standard scoring)',...
   'Units','Normalized','Position',[0.35 0.52 0.39 0.39],'Color','w');
ax = axes(fig,'NextPlot','add','XColor','k','YColor','k','LineWidth',1.5,...
   'FontName','Arial','XLim',xLim,'YLim',pars.YLim);

[Gplot,TIDplot] = findgroups(T(:,{'GroupID','AnimalID'}));
mdl = cell(size(TIDplot,1),2);

iMarker = struct('Intact',0,'Ischemia',0);
hGroup = gobjects(size(TIDplot,1),1);

for ii = 1:size(TIDplot,1)
   gName = string(TIDplot.GroupID(ii));
   c = pars.Color.(gName);
   iMarker.(gName) = iMarker.(gName) + 1;
   tThis = T(Gplot==ii,{'Day','Day_Cubed','nSuccess','nTotal','Percent_Successful'});
   mdl{ii,1} = fitglm(tThis,"nSuccess~1+Day+Day_Cubed",...
      "BinomialSize",tThis.nTotal,...
      "Distribution",'binomial',...
      "Link",'logit');
   mdl{ii,2} = string(TIDplot.AnimalID(ii));
   Day = (min(tThis.Day):max(tThis.Day))';
   Day_Cubed = Day.^3;
   tPred = table(Day,Day_Cubed);
   [mu,cb95] = predict(mdl{ii},tPred,'BinomialSize',ones(size(Day)));
   iBad = diff(cb95,1,2)>= 0.95;
   cb95(iBad,:) = nan(sum(iBad),2);
%    tThis.Percent_Successful = tThis.nSuccess./tThis.nTotal.*100;
   dayVec = 1:numel(Day);
   mrkIndices = dayVec(ismember(Day,tThis.Day));
   hGroup(ii) = gfx__.plotWithShadedError(ax,...
      Day,mu.*100,cb95.*100,...
      'FaceColor',c,...
      'FaceAlpha',pars.FaceAlpha,...
      'Marker',pars.MarkerOrder(iMarker.(gName)),...
      'MarkerIndices',mrkIndices,...
      'MarkerEdgeColor','k',...
      'DisplayName',sprintf('%s (fit)',string(TIDplot.AnimalID(ii))),...
      'Annotation','on',...
      'Tag',sprintf('Trend::%s',gName),...
      'LineWidth',pars.LineWidth);
   hScatter = scatter(ax,tThis.Day,tThis.Percent_Successful,'filled',...
      'Marker',pars.MarkerOrder(iMarker.(gName)),...
      'MarkerFaceColor',c,...
      'MarkerEdgeColor','none',...
      'MarkerFaceAlpha',pars.MarkerFaceAlpha,...
      'Tag',sprintf('Scatter::%s',gName),...
      'DisplayName',sprintf('%s (observed)',string(TIDplot.AnimalID(ii))));
   eLineX = ([tThis.Day,tThis.Day,nan(size(tThis,1),1)])';
   eLineY = ([tThis.Percent_Successful,mu(mrkIndices).*100,nan(size(tThis,1),1)])';
   hLine = line(ax,eLineX(:),eLineY(:),...
      'LineStyle',pars.ErrorLineStyle,...
      'LineWidth',pars.ErrorLineWidth,...
      'Color',c,...
      'DisplayName','Matched Observation');
   drawnow;
end
if strcmpi(pars.LegendStyle,'standard')
   trendLine = hGroup(end).Children(1);
   trendErr = hGroup(end).Children(2);
   legend([trendLine,trendErr,hScatter,hLine],...
      {'Model Trend','Model 95% CB','Observed','Matched Error'},...
      'TextColor','black',...
      'FontName','Arial',...
      'FontSize',12,...
      'EdgeColor','none',...
      'Color','none',...
      'Location',pars.LegendLocation);
elseif strcmpi(pars.LegendStyle,'animals')
   excVec = false(size(hGroup));
   for ii = 1:size(hGroup,1)
      excVec(ii) = isa(hGroup(ii),'matlab.graphics.GraphicsPlaceholder');
   end
   hGroup(excVec) = [];
   c = gobjects(size(hGroup));
   for ii = 1:size(hGroup,1)
      c(ii) = hGroup(ii).Children(1);
   end
   legend(c,...
      'TextColor','black',...
      'FontName','Arial',...
      'FontSize',12,...
      'EdgeColor','none',...
      'Color','none',...
      'AutoUpdate','off',...
      'Location',pars.LegendLocation);
end

xlabel(ax,'Post-Op Day','FontName','Arial','Color','k');
ylabel(ax,'Success %','FontName','Arial','Color','k');
title(ax,pars.Title,'FontName','Arial','Color','k');

end