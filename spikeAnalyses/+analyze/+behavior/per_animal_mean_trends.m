function [fig,T,mdl] = per_animal_mean_trends(T,responseVar,varargin)
%PER_ANIMAL_MEAN_TRENDS Plot per-animal (mean) trends
%
%  [fig,T,mdl] = analyze.behavior.per_animal_mean_trends(T,responseVar);
%  [fig,T,mdl] = analyze.behavior.per_animal_mean_trends(T,responseVar,'Name',value,...);
%
% Inputs
%  T - Table of behavior with variables:
%        'Day','nSuccess','nTotal','AnimalID','GroupID'
%  responseVar - Name of response variable to estimate mean and fit on
%                 per-animal grouping
%  varargin - (Optional) 'Name',value pairs
%           -> 'Title' : "" (def); title string for plot
%           -> 'BinomialSize' : [] (def); allows specifying size for
%                                            Binomial fits
%           -> 'FitOptions' : {} (def) 
%                    -> Cell array of 'Name',value pairs for `fitglm`
%
% Output
%  fig - Figure handle
%  T   - Table of mean values
%  mdl - Cell array (by animal) 
% 
% See also: analyze.behavior, analyze.behavior.per_animal_mean_trends,
%           trial_outcome_stats

% Default parameters %
pars = struct;
pars.AutoScale = 0.15; % Increase bandwidth of y-axis by this fraction each direction
pars.BadConfBand = inf;
pars.BinomialSize = []; 
pars.Color = struct;
pars.Color.Ischemia = [0.9 0.1 0.1];
pars.Color.Intact = [0.1 0.1 0.9];
pars.ConditioningNoiseVar = 1e-4;
pars.DoExclusions = true;
pars.ErrorLineStyle = ':';
pars.ErrorLineWidth = 1.5;
pars.FaceAlpha = 0.35;
pars.FitOptions = {};
pars.LegendLabels = {'Model Trend','Model 95% CB','Observed Mean','Model Error'};
pars.LegendLocation = 'northeast';
pars.LegendStyle = 'standard'; % 'standard' | 'animals'
pars.LineWidth = 2.5;
pars.MarkerOrder = 'oshpv^';
pars.MarkerFaceAlpha = 0.45;
pars.ModelFormula = '%s~1+Day+Day_Cubed';
pars.ModelNumber = nan;
pars.Scale = 1;
pars.Title = '';
pars.XLabel = 'Day';
pars.XLim = [nan nan];
pars.YLabel = '';
pars.YLim = [nan nan];

% % % % Parse inputs % % % %
fn = fieldnames(pars);
if numel(varargin) > 0
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


% % Exclude rows if specified in table % %
if pars.DoExclusions
   T = T(~T.Properties.UserData.Excluded,:);
end
T.(responseVar) = T.(responseVar) .* pars.Scale;

% % Parse graphics metavariables % %
if any(isnan(pars.XLim))
   if ~ismember('Day',T.Properties.VariableNames)
      xLim = [min(T.PostOpDay),max(T.PostOpDay)];
   else
      xLim = [min(T.Day),max(T.Day)];
   end
else
   xLim = pars.XLim;
end

if isempty(pars.YLabel)
   unitLab = T.Properties.VariableUnits{responseVar};
   if isempty(unitLab)
      yLabel = strrep(responseVar,'_',' ');
   else
      yLabel = sprintf('%s (%s)',strrep(responseVar,'_',' '),unitLab);
   end
else
   yLabel = pars.YLabel;
end


[G,data] = findgroups(T(:,{'GroupID','AnimalID','PostOpDay'}));
data.(responseVar) = splitapply(@nanmean,T.(responseVar),G);
if ~ismember(T.Properties.VariableNames,'Day')
   T.Properties.VariableNames{'PostOpDay'} = 'Day';
end
if ~ismember(data.Properties.VariableNames,'Day')
   data.Properties.VariableNames{'PostOpDay'} = 'Day';
end
if ~ismember(data.Properties.VariableNames,'Duration')
   data.Duration = splitapply(@nanmean,T.Duration,G);
end
% Add 3rd-order term
T.Day_Cubed = T.Day.^3;
data.Day_Cubed = data.Day.^3;

if any(isnan(pars.YLim))
   yTmp = [min(data.(responseVar)),max(data.(responseVar))];
   dY = diff(yTmp);
   yLim = [yTmp(1)-pars.AutoScale*dY, yTmp(2)+pars.AutoScale*dY];
else
   yLim = pars.YLim;
end

fig = figure('Name',sprintf('%s by Day (Block Average Animal Trends)',responseVar),...
   'Units','Normalized','Position',[0.35 0.52 0.39 0.39],'Color','w');
ax = axes(fig,'NextPlot','add','XColor','k','YColor','k','LineWidth',1.5,...
   'FontName','Arial','XLim',xLim,'YLim',yLim);

[Gplot,TIDplot] = findgroups(data(:,{'GroupID','AnimalID'}));
[Gmdl,TIDmdl] = findgroups(T(:,{'GroupID','AnimalID'}));
mdl = cell(size(TIDplot,1),2);

iMarker = struct('Intact',0,'Ischemia',0);
if iscolumn(pars.FitOptions)
   pars.FitOptions = pars.FitOptions';
end
if ~isempty(pars.BinomialSize)
   pars.FitOptions = [pars.FitOptions, 'BinomialSize', pars.BinomialSize];
end

mdlspec = string(sprintf(pars.ModelFormula,responseVar));
needsLegend = true;
hGroup = gobjects(size(TIDplot,1),1);
for ii = 1:size(TIDplot,1)
   gName = string(TIDplot.GroupID(ii));
   c = pars.Color.(gName);
   iMarker.(gName) = iMarker.(gName) + 1;
   theseData = data(Gplot==ii,:);
   iMdlData = find(TIDmdl.AnimalID==TIDplot.AnimalID(ii),1,'first');
   allAnimalData = T(Gmdl==iMdlData,:);
   mdl{ii,2} = string(TIDplot.AnimalID(ii));
   if size(allAnimalData,1) < 5
      fprintf(1,'Too few observations for %s; skipped\n',...
         string(TIDplot.AnimalID(ii)));
      continue;
   end
   mdl{ii,1} = fitglm(allAnimalData,mdlspec,pars.FitOptions{:});
   Day = (min(theseData.Day):max(theseData.Day))';
   Day_Cubed = Day.^3;
%    Duration = interp1(theseData.Day,theseData.Duration,Day);
   nObs = size(theseData,1);
   mid = round((1 + nObs)/2);
   pp = csape(theseData.Day([1 mid nObs]),theseData.Duration([1 mid nObs]),'clamped');
   Duration = fnval(pp,Day);
   tPred = table(Day,Day_Cubed,Duration);
   try
      [mu,cb95] = predict(mdl{ii},tPred);
   catch me
      disp(me);
      fprintf(1,'Input Data <strong>(%s)</strong>:',string(TIDplot.AnimalID(ii)));
      disp(allAnimalData);
      disp('Prediction Table:');
      disp(tPred);
      disp('Covariance Matrix:');
      disp(mdl{ii}.CoefficientCovariance);
      fprintf(1,'<strong>Ill-conditioned covariance matrix</strong>\n');
      fprintf(1,'->\tAdding conditioning noise (variance: %f)...',pars.ConditioningNoiseVar);
      allAnimalData.(responseVar) = allAnimalData.(responseVar) + randn(size(allAnimalData.(responseVar))).*pars.ConditioningNoiseVar; % Add conditioning noise
      % Try to re-fit %
      mdl{ii,1} = fitglm(allAnimalData,mdlspec,pars.FitOptions{:});
      [mu,cb95] = predict(mdl{ii},tPred);
   end
   iBad = diff(cb95,1,2)>= pars.BadConfBand;
   cb95(iBad,:) = nan(sum(iBad),2);
   dayVec = 1:numel(Day);
   mrkIndices = dayVec(ismember(Day,theseData.Day));
   hGroup(ii) = gfx__.plotWithShadedError(ax,...
      Day,mu,cb95,...
      'FaceColor',c,...
      'FaceAlpha',pars.FaceAlpha,...
      'Marker',pars.MarkerOrder(iMarker.(gName)),...
      'MarkerIndices',mrkIndices,...
      'MarkerEdgeColor','k',...
      'DisplayName',sprintf('%s (fit)',string(TIDplot.AnimalID(ii))),...
      'Annotation','on',...
      'Tag',sprintf('Trend::%s',gName),...
      'LineWidth',pars.LineWidth);
   hScatter = scatter(ax,theseData.Day,theseData.(responseVar),'filled',...
      'Marker',pars.MarkerOrder(iMarker.(gName)),...
      'MarkerFaceColor',c,...
      'MarkerEdgeColor','none',...
      'MarkerFaceAlpha',pars.MarkerFaceAlpha,...
      'Tag',sprintf('Scatter::%s',gName),...
      'DisplayName',sprintf('%s (observed)',string(TIDplot.AnimalID(ii))));
   eLineX = ([theseData.Day,theseData.Day,nan(size(theseData,1),1)])';
   eLineY = ([theseData.(responseVar),mu(mrkIndices),nan(size(theseData,1),1)])';
   hLine = line(ax,eLineX(:),eLineY(:),...
      'LineStyle',pars.ErrorLineStyle,...
      'LineWidth',pars.ErrorLineWidth,...
      'Color',c,...
      'DisplayName','Matched Observation');
   if strcmpi(pars.LegendStyle,'standard')
      if needsLegend
         trendLine = hGroup(ii).Children(1);
         trendErr = hGroup(ii).Children(2);
         legend([trendLine,trendErr,hScatter,hLine],...
            pars.LegendLabels,...
            'TextColor','black',...
            'FontName','Arial',...
            'FontSize',12,...
            'EdgeColor','none',...
            'Color','none',...
            'AutoUpdate','off',...
            'Location',pars.LegendLocation);
         needsLegend = false;
      end
   end
   drawnow;
end
if strcmpi(pars.LegendStyle,'animals')
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

xlabel(ax,pars.XLabel,'FontName','Arial','Color','k');
ylabel(ax,yLabel,'FontName','Arial','Color','k');
title(ax,pars.Title,'FontName','Arial','Color','k');

end