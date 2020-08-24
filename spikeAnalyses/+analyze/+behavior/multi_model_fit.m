function [fig,mdl,Data] = multi_model_fit(T,responseVar,varargin)
%MULTI_MODEL_FIT Plot per-animal, per-area (mean) trends
%
%  [fig,mdl] = analyze.behavior.multi_model_fit(T,responseVar);
%  [fig,mdl,TID] = analyze.behavior.multi_model_fit(T,responseVar,'Name',value,...);
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
%  fig  - Figure handle
%  mdl  - GeneralizedLinearMixedModel fit to data
%  TID  - Data by Ischemia/Intact generated from model predictions
% 
% See also: analyze.behavior, analyze.behavior.per_animal_mean_trends,
%           trial_outcome_stats

% Default parameters %
pars = struct;
pars.Alpha = 0.05; % cosmetic only
pars.AutoScale = 0.15; % Increase bandwidth of y-axis by this fraction each direction
pars.BadConfBand = inf;
pars.BinomialSize = []; 
pars.Color = struct('Ischemia',...
      struct('RFA',[0.8 0.2 0.2],...
             'CFA',[1.0 0.4 0.4]), ...
          'Intact',...
       struct('RFA',[0.2 0.2 0.8],...
              'CFA',[0.4 0.4 1.0]));
pars.ConditioningNoiseVar = 1e-4;
pars.DoExclusions = true;
pars.DurationTrendVar = '';
pars.ErrorLineStyle = ':';
pars.ErrorLineWidth = 1.5;
pars.FaceAlpha = 0.20;
pars.FitOptions = {...
   'FitMethod','REMPL',...
   'Distribution','binomial',...
   'DummyVarCoding','effects',...
   'Link','logit' ...
   };
pars.ID = nan;
pars.LegendLabels = {'Model Trend','Model 95% CB','Observed Mean','Model Error'};
pars.LegendLocation = 'northoutside';
pars.LineStyle = struct('Ischemia',...
      struct('RFA','-',...
             'CFA','-'), ...
          'Intact',...
       struct('RFA',':',...
              'CFA',':'));
pars.LineWidth = 1.5;
pars.Marker = struct('Ischemia',...
      struct('RFA','x',...
             'CFA','x'), ...
          'Intact',...
       struct('RFA','o',...
              'CFA','o'));
pars.MarkerOrder = 'oshpv^';
pars.MarkerFaceAlpha = 0.45;
pars.ModelFormula = '%s~%s+GroupID*Area*PostOpDay';
pars.Offset = struct('Ischemia',...
      struct('RFA',0.1,...
             'CFA',0.2), ...
          'Intact',...
       struct('RFA',-0.2,...
              'CFA',-0.1));
pars.SimpleModelFormula = '%s~PostOpDayc+Duration+(1+PostOpDay|AnimalID)';
pars.Tag = '';
pars.TimeTrendVar = 'PostOpDay';
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
if ~ismember('GroupID',T.Properties.VariableNames)
   T.GroupID = T.Group;
end

if pars.DoExclusions
   if isfield(T.Properties.UserData,'Excluded')
      T = T(~T.Properties.UserData.Excluded,:);
   else
      warning('No "Exclude" or "Excluded" UserData field.');
   end
end

% % Parse graphics metavariables % %
if any(isnan(pars.XLim))
   xLim = [min(T.(pars.TimeTrendVar)),max(T.(pars.TimeTrendVar))];
else
   xLim = pars.XLim;
end

if isempty(pars.YLabel)
   yLabel = 'Spike Count';
else
   yLabel = pars.YLabel;
end
mdl = struct;
T.PostOpDayc = ordinal(T.PostOpDay);
[G,data] = findgroups(T(:,{'GroupID','AnimalID','Area','PostOpDayc','PostOpDay'}));
data.(responseVar) = splitapply(@(x)round(nanmean(x)),T.(responseVar),G);
data.N_Total = splitapply(@(x)round(nanmean(x)),T.N_Total,G);
data.Duration = splitapply(@(x)nanmean(x),T.Duration,G);
data.Reach_Epoch_Duration = splitapply(@(x)nanmean(x),T.Reach_Epoch_Duration,G);
data.Retract_Epoch_Duration = splitapply(@(x)nanmean(x),T.Retract_Epoch_Duration,G);
data.Performance = splitapply(@(x)nanmean(x),T.Performance_mu,G);
simpleModelSpec = sprintf(pars.SimpleModelFormula,responseVar);
mdl.simple = fitglme(data,simpleModelSpec,pars.FitOptions{:},'BinomialSize',data.N_Total);

predName = sprintf('%s_pred',responseVar);
T.(predName) = predict(mdl.simple,T);

mdlspec = string(sprintf(pars.ModelFormula,responseVar,predName));
mdlTic = tic;
fprintf(1,'Fitting model: %s  ...',mdlspec);
mdl.mdl = fitglme(T,mdlspec,pars.FitOptions{:},'BinomialSize',T.N_Total);
mdl.id = pars.ID;
mdl.tag = pars.Tag;
mdlToc = toc(mdlTic);
fprintf(1,'complete (%6.2f sec)\n',mdlToc);

if any(isnan(pars.YLim))
   yTmp = [min(data.(responseVar)),max(data.(responseVar))];
   dY = diff(yTmp);
   yLim = [yTmp(1)-pars.AutoScale*dY, yTmp(2)+pars.AutoScale*dY];
else
   yLim = pars.YLim;
end

fig = figure('Name',sprintf('%s by Day (Block Average Animal Trends)',responseVar),...
   'Units','Normalized','Position',[0.545 0.125 0.323 0.750],'Color','w');
ax = axes(fig,'NextPlot','add','XColor','k','YColor','k','LineWidth',1.5,...
         'FontName','Arial','XLim',xLim,'YLim',yLim);
yyaxis left;
ylabel(ax,sprintf('%s (mean \\pm1 S.D.)',yLabel),...
      'FontName','Arial','Color','k','FontWeight','bold');
title(ax,pars.Title,'FontName','Arial','Color','k','FontWeight','bold');
xlabel(ax,pars.XLabel,'FontName','Arial','Color','k','FontWeight','bold');
[G,Data] = findgroups(T(:,{'GroupID','Area','PostOpDay'}));
sdVar = sprintf('%s_sd',responseVar);
Data.(responseVar) = splitapply(@(x)round(nanmean(x)),T.(responseVar),G);
Data.(sdVar) = splitapply(@(x)nanstd(x),T.(responseVar),G);

if ~isempty(pars.DurationTrendVar)
   yyaxis right;
   durVar = strrep(pars.DurationTrendVar,'_',' ');
   durVar_s = strsplit(durVar,'_');
   ylabel(ax,sprintf('Mean %s \\pm1 S.D. (%s)',durVar,T.Properties.VariableUnits{pars.DurationTrendVar}),...
      'FontName','Arial','Color','k','FontWeight','bold');
   Data.(pars.DurationTrendVar) = splitapply(@(x)nanmean(x),T.(pars.DurationTrendVar),G);
   durSD = sprintf('%s_sd',pars.DurationTrendVar);
   Data.(durSD) = splitapply(@(x)nanstd(x),T.(pars.DurationTrendVar),G);
   utils.addHelperRepos();
end
[G,TID] = findgroups(Data(:,{'GroupID','Area'}));

for ii = 1:size(TID,1)
   gName = string(TID.GroupID(ii));
   aName = string(TID.Area(ii));
   c = pars.Color.(gName).(aName);
   o = pars.Offset.(gName).(aName);
   [Day,iSort] = sort(Data.PostOpDay(G==ii),'ascend');
   mu = Data.(responseVar)(G==ii);
   mu = mu(iSort);
   sd = Data.(sdVar)(G==ii);
   sd = sd(iSort);
   yyaxis left;
   errorbar(ax,...
      Day+o,mu,sd,...
      'Color',c,...
      'Marker',pars.Marker.(gName).(aName),...
      'MarkerFaceColor','k',...
      'DisplayName',sprintf('%s::%s',gName,aName),...
      'Tag',sprintf('Trend::%s::%s',gName,aName),...
      'LineStyle',pars.LineStyle.(gName).(aName),...
      'LineWidth',pars.LineWidth);
   if ~isempty(pars.DurationTrendVar) && (aName=="RFA")
      yyaxis right;
      mu_t = sgolayfilt(Data.(pars.DurationTrendVar)(G==ii),3,5);
      sd_t = sgolayfilt(Data.(durSD)(G==ii),3,5);
      gfx__.plotWithShadedError(ax,...
         Day+o,mu_t,sd_t,...
         'Color',c,...
         'FaceColor',c,...
         'DisplayName',sprintf('%s_{%s}',durVar_s{1},gName),...
         'LineWidth',2.5,...
         'LineStyle',':',...
         'Tag',sprintf('%s_{%s}',durVar_s{1},gName),...
         'Annotation','on');
   end
   
   drawnow;
end
legend(ax,'TextColor','black',...
   'Location',pars.LegendLocation,'FontName','Arial');

end