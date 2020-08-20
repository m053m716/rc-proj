function [fig,mdl,Data] = per_animal_area_mean_rates(T,responseVar,varargin)
%PER_ANIMAL_AREA_MEAN_RATES Plot per-animal, per-area (mean) RATE trends
%
%  [fig,mdl] = analyze.behavior.per_animal_area_mean_rates(T,responseVar);
%  [fig,mdl,Data] = analyze.behavior.per_animal_area_mean_rates(T,responseVar,'Name',value,...);
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
%  Data - Data by Ischemia/Intact generated from model predictions
% 
% See also: analyze.behavior, analyze.behavior.per_animal_mean_trends,
%           trial_outcome_stats

% Default parameters %
pars = struct;
pars.Alpha = 0.05; % For display purposes only
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
pars.DurationModelFormula = '%s~1+(1+PostOpDay|AnimalID)';
pars.DurationVar = '';
pars.DurationValue = 0.6; % Fixed duration (PRE-GRASP; used if DurationVar is empty)
pars.ErrorLineStyle = ':';
pars.ErrorLineWidth = 1.5;
pars.FaceAlpha = 0.20;
pars.FitOptions = {...
   'FitMethod','REMPL',...
   'Distribution','normal',...
   'DummyVarCoding','effects',...
   'Link','identity' ...
   };
pars.GroupVars = {'GroupID','AnimalID','Area','Period','PostOpDay','PostOpDay_Cubed'};
pars.LegendLabels = {'Model Trend','Model 95% CB','Observed Mean','Model Error'};
pars.LegendLocation = 'northeast';
pars.LineWidth = 1.0;
pars.MarkerOrder = 'oshpv^';
pars.MarkerFaceAlpha = 0.45;
pars.ModelFormula = '%s~1+Area*GroupID+(1+PostOpDay+Performance_hat_mu%s|AnimalID)';
pars.ModelNumber = nan;
pars.RandomCovariates = {'Duration'};
pars.RandomModelFormula = '%s~1+(1+PostOpDay+PostOpDay_Cubed|AnimalID)';
pars.ResponseAggregatorFcn = [];
pars.ResponseAggregationVars = responseVar;
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
   if isfield(T.Properties.UserData,'Exclude')
      T = T(~T.Properties.UserData.Exclude,:);
   elseif isfield(T.Properties.UserData,'Excluded')
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
   unitLab = T.Properties.VariableUnits{responseVar};
   if isempty(unitLab)
      yLabel = strrep(responseVar,'_',' ');
   else
      yLabel = sprintf('%s (%s)',strrep(responseVar,'_',' '),unitLab);
   end
else
   yLabel = pars.YLabel;
end

if isempty(pars.DurationVar)
   pars.DurationVar = 'EpochDuration';
   T.EpochDuration = repmat(pars.DurationValue,size(T,1),1);
   useDurationMdl = false;
else
   useDurationMdl = true;
end
% Add 3rd-order term
cube_term = sprintf('%s_Cubed',pars.TimeTrendVar);
T.(cube_term) = T.(pars.TimeTrendVar).^3;
T.Period = categorical(discretize(T.PostOpDay,0:11:33),...
   [1,2,3],{'Early','Mid','Late'});

% Recover models for predicting interpolated values of random effects, in
% order to visualize responses as trends across days
randomVarStr = '';
randMdl = struct;
B = utils.readBehaviorTable(defaults.files('behavior_data_file'),true);
T = outerjoin(T,B,'Keys',{'GroupID','AnimalID','PostOpDay','PostOpDay_Cubed'},...
   'MergeKeys',true,...
   'Type','full',...
   'RightVariables',{'GroupID','AnimalID','PostOpDay','PostOpDay_Cubed','Performance_hat_mu','Performance_hat_cb95'});

[G,data] = findgroups(T(:,pars.GroupVars));
if ~isempty(pars.ResponseAggregatorFcn)
   responseVarOut = responseVar;
   data.(responseVarOut) = splitapply(pars.ResponseAggregatorFcn,T(:,pars.ResponseAggregationVars),G);
   data.(pars.DurationVar) = splitapply(@(x)nanmean(x),T.(pars.DurationVar),G);

   for iR = 1:numel(pars.RandomCovariates)
      if ~ismember(pars.RandomCovariates{iR},data.Properties.VariableNames)
         data.(pars.RandomCovariates{iR}) = splitapply(@(x)nanmean(x),...
            T.(pars.RandomCovariates{iR}),T.Trial_ID,G);
      end
      randomVarStr = [randomVarStr, sprintf('+%s',pars.RandomCovariates{iR})]; %#ok<AGROW>
      randMdl.(pars.RandomCovariates{iR}) = fitglme(data,...
         sprintf(pars.RandomModelFormula,pars.RandomCovariates{iR}));
   end
   
else
   responseVarOut = strrep(responseVar,'N_','');
   responseVarOut = [responseVarOut '_Rate'];
   data.(responseVarOut) = splitapply(@(x,d)nanmean(sqrt(x)./d),T.(responseVar),T.(pars.DurationVar),G);
   data.(pars.DurationVar) = splitapply(@(x,id)utils.getUniqueTrialsAverage(x,id),T.(pars.DurationVar),T.Trial_ID,G);

   for iR = 1:numel(pars.RandomCovariates)
      if ~ismember(pars.RandomCovariates{iR},data.Properties.VariableNames)
         data.(pars.RandomCovariates{iR}) = splitapply(@(x,id)utils.getUniqueTrialsAverage(x,id),...
            T.(pars.RandomCovariates{iR}),T.Trial_ID,G);
      end
      randomVarStr = [randomVarStr, sprintf('+%s',pars.RandomCovariates{iR})]; %#ok<AGROW>
      randMdl.(pars.RandomCovariates{iR}) = fitglme(data,...
         sprintf(pars.RandomModelFormula,pars.RandomCovariates{iR}));
   end
end

if useDurationMdl
   durationMdl = fitglme(data,...
      sprintf(pars.DurationModelFormula,pars.DurationVar));
else
   durationMdl = nan;
end

mdlspec = string(sprintf(pars.ModelFormula,responseVarOut,randomVarStr));

if iscolumn(pars.FitOptions)
   pars.FitOptions = pars.FitOptions';
end
if ~isempty(pars.BinomialSize)
   pars.FitOptions = [pars.FitOptions, 'BinomialSize', pars.BinomialSize];
end

data = outerjoin(data,B,...
   'Keys',{'GroupID','AnimalID','PostOpDay','PostOpDay_Cubed'},...
   'MergeKeys',true,'Type','full',...
   'LeftVariables',{'Area',responseVarOut,pars.DurationVar,'Duration'},...
   'RightVariables',{'GroupID','AnimalID','PostOpDay','PostOpDay_Cubed','Performance_hat_mu','Performance_hat_cb95'});

mdlTic = tic;
fprintf(1,'Fitting model: %s  ...',mdlspec);
mainMdl = fitglme(data,mdlspec,pars.FitOptions{:});
mdlToc = toc(mdlTic);
fprintf(1,'complete (%6.2f sec)\n',mdlToc);

if any(isnan(pars.YLim))
   yTmp = [min(data.(responseVarOut)),max(data.(responseVarOut))];
   dY = diff(yTmp);
   yLim = [yTmp(1)-pars.AutoScale*dY, yTmp(2)+pars.AutoScale*dY];
else
   yLim = pars.YLim;
end

fig = figure('Name',sprintf('%s by Day (Block Average Animal Trends)',responseVar),...
   'Units','Normalized','Position',[0.545 0.125 0.323 0.750],'Color','w');
ax = [ ...
   axes(fig,'NextPlot','add','XColor','k','YColor','k','LineWidth',1.5,...
         'FontName','Arial','XLim',xLim,'YLim',yLim,'Units','Normalized',...
         'Position',[0.15 0.55 0.7 0.30],'Tag','Intact CFA');
   axes(fig,'NextPlot','add','XColor','k','YColor','k','LineWidth',1.5,...
         'FontName','Arial','XLim',xLim,'YLim',yLim,'Units','Normalized',...
         'Position',[0.15 0.15 0.7 0.30],'Tag','Injured RFA')];
areaTags = ["Intact CFA"; "Injured RFA"];
 
for iAx = 1:2
   ylabel(ax(iAx),sprintf('\\surd%s (%s)',yLabel,areaTags(iAx)),...
      'FontName','Arial','Color','k');
end
title(ax(1),pars.Title,'FontName','Arial','Color','k');
xlabel(ax(2),pars.XLabel,'FontName','Arial','Color','k');

[Gplot,TIDplot] = findgroups(data(:,{'GroupID','AnimalID','Area'}));

iMarker = struct('Intact',struct('CFA',0,'RFA',0),'Ischemia',struct('CFA',0,'RFA',0));
needsLegend = true(2,1);
Data = [];
for ii = 1:size(TIDplot,1)
   gName = string(TIDplot.GroupID(ii));
   aName = string(TIDplot.Area(ii));
   c = pars.Color.(gName).(aName);
   iAx = find(contains(areaTags,aName),1,'first');
   
   iMarker.(gName).(aName) = iMarker.(gName).(aName) + 1;
   theseData = data(Gplot==ii,:);
   if size(theseData,1) < 5
      fprintf(1,'Insufficient data: %s::%s (skipped)\n',string(TIDplot.AnimalID(ii)),aName);
      continue;
   end
   
   Day = theseData.(pars.TimeTrendVar);
   Day_Cubed = theseData.(cube_term);
   nDay = numel(Day);
   GroupID = repmat(TIDplot.GroupID(ii),nDay,1);
   Area = repmat(TIDplot.Area(ii),nDay,1);
   AnimalID = repmat(TIDplot.AnimalID(ii),nDay,1);
   Period = categorical(discretize(Day,0:11:33),...
      [1,2,3],{'Early','Mid','Late'});
   dayVec = 1:nDay;
   mrkIndices = dayVec(~isnan(theseData.(responseVarOut)));

   tPred = table(GroupID,AnimalID,Area,Period,Day,Day_Cubed);
   tPred.Properties.VariableNames{'Day'} = pars.TimeTrendVar;
   tPred.Properties.VariableNames{'Day_Cubed'} = cube_term;
   tPred.Performance_hat_mu = theseData.Performance_hat_mu;
   tPred.Performance_hat_cb95 = theseData.Performance_hat_cb95;
   for iR = 1:numel(pars.RandomCovariates)  
      if ~ismember(pars.RandomCovariates{iR},tPred.Properties.VariableNames)
         tPred.(pars.RandomCovariates{iR}) = predict(randMdl.(pars.RandomCovariates{iR}),tPred);
      end
   end
   if useDurationMdl
      tPred.(pars.DurationVar) = predict(durationMdl,tPred);
   else
      tPred.(pars.DurationVar) = repmat(pars.DurationValue,nDay,1);
   end
   
   [mu,cb95] = predict(mainMdl,tPred);
   iBad = diff(cb95,1,2)>= pars.BadConfBand;
   cb95(iBad,:) = nan(sum(iBad),2);   
   Data = [Data; table(GroupID,Area,AnimalID,Day,mu,cb95)]; %#ok<AGROW>
   
   hGroup = gfx__.plotWithShadedError(ax(iAx),...
      Day,mu,cb95,...
      'FaceColor',c,...
      'FaceAlpha',pars.FaceAlpha,...
      'Marker',pars.MarkerOrder(iMarker.(gName).(aName)),...
      'MarkerIndices',mrkIndices,...
      'MarkerEdgeColor','k',...
      'DisplayName',sprintf('%s (fit)',string(TIDplot.AnimalID(ii))),...
      'Annotation','on',...
      'Tag',sprintf('Trend::%s::%s',gName,aName),...
      'LineWidth',pars.LineWidth);
   hScatter = scatter(ax(iAx),...
      theseData.(pars.TimeTrendVar),...
      theseData.(responseVarOut),'filled',...
      'Marker',pars.MarkerOrder(iMarker.(gName).(aName)),...
      'MarkerFaceColor',c,...
      'MarkerEdgeColor','none',...
      'MarkerFaceAlpha',pars.MarkerFaceAlpha,...
      'Tag',sprintf('Scatter::%s::%s',gName,aName),...
      'DisplayName',sprintf('%s (observed)',string(TIDplot.AnimalID(ii))));
   eLineX = ([theseData.(pars.TimeTrendVar),theseData.(pars.TimeTrendVar),nan(size(theseData,1),1)])';
   eLineX = eLineX(:,mrkIndices);
   eLineY = ([theseData.(responseVarOut),mu,nan(size(theseData,1),1)])';
   eLineY = eLineY(:,mrkIndices);
   hLine = line(ax(iAx),eLineX(:),eLineY(:),...
      'LineStyle',pars.ErrorLineStyle,...
      'LineWidth',pars.ErrorLineWidth,...
      'Color',c,...
      'DisplayName','Matched Observation');
   if needsLegend(iAx)
      trendLine = hGroup.Children(1);
      trendErr = hGroup.Children(2);
      legend([trendLine,trendErr,hScatter,hLine],...
         pars.LegendLabels,...
         'TextColor','black',...
         'FontName','Arial',...
         'FontSize',9,...
         'EdgeColor','none',...
         'Color','white',...
         'AutoUpdate','off',...
         'Location',pars.LegendLocation);
      needsLegend(iAx) = false;
   end
   drawnow;
end
Data = splitvars(Data,'cb95');
Data.Properties.VariableNames{'cb95_1'} = 'cb95_lb';
Data.Properties.VariableNames{'cb95_2'} = 'cb95_ub';
Data.cb95 = Data.cb95_ub - Data.cb95_lb;
Data.Week = ordinal(ceil(Data.Day./7));
[~,~,rStats] = randomEffects(mainMdl);
idx = contains(rStats.Name,'Performance_hat_mu') & (rStats.pValue < pars.Alpha);
rStats = rStats(idx,[1:4,8]);
[~,iSort] = sort(rStats.pValue,'ascend');
rStats = rStats(iSort,:);
[~,~,fStats] = fixedEffects(mainMdl);
[~,iSort] = sort(fStats.pValue,'ascend');
fStats = fStats(iSort,:);

mdl = struct('main',mainMdl,'random',randMdl,'duration',durationMdl,'id',pars.ModelNumber,...
   'perfStats',rStats,'fixedEffects',fStats(:,[1,2,4,5,6]));
fprintf(1,'--------------------------------------------------------------------\n');
fprintf(1,'<strong>MODEL-%02db:</strong> %s\n',pars.ModelNumber,responseVarOut);
fprintf(1,'--------------------------------------------------------------------\n');
disp(anova(mainMdl));
fprintf(1,'<strong>FIT (R^2):</strong>\n');
disp(mainMdl.Rsquared);
disp(rStats);
end