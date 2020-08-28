function [fig,mdl,Data] = per_animal_area_mean_trends(T,responseVar,varargin)
%PER_ANIMAL_AREA_MEAN_TRENDS Plot per-animal, per-area (mean) trends
%
%  [fig,mdl] = analyze.behavior.per_animal_area_mean_trends(T,responseVar);
%  [fig,mdl,Data] = analyze.behavior.per_animal_area_mean_trends(T,responseVar,'Name',value,...);
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
pars.LegendLocation = 'northeast';
pars.LegendStyle = 'standard';
pars.LineWidth = 1.0;
pars.MarkerOrder = 'oshpv^';
pars.MarkerFaceAlpha = 0.45;
pars.ModelFormula = '%s~1+Area*(Outcome+GroupID)+(1%s|AnimalID)';
pars.RandomCovariates = {'Duration'};
pars.RandomModelFormula = '%s~1+(1+PostOpDay+PostOpDay_Cubed+Performance_mu|AnimalID)';
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
   unitLab = T.Properties.VariableUnits{responseVar};
   if isempty(unitLab)
      yLabel = strrep(responseVar,'_',' ');
   else
      yLabel = sprintf('%s (%s)',strrep(responseVar,'_',' '),unitLab);
   end
else
   yLabel = pars.YLabel;
end

cube_term = sprintf('%s_Cubed',pars.TimeTrendVar);
T.(cube_term) = T.(pars.TimeTrendVar).^3;

B = utils.readBehaviorTable(defaults.files('behavior_data_file'),true);
T = outerjoin(T,B,'Keys',{'GroupID','AnimalID','PostOpDay','PostOpDay_Cubed'},...
   'MergeKeys',true,...
   'Type','left',...
   'LeftVariables',setdiff(T.Properties.VariableNames,{'Performance_mu','Performance_hat_mu','Performance_hat_cb95'}),...
   'RightVariables',{'Performance_mu','Performance_hat_mu','Performance_hat_cb95'});

T.Period = categorical(discretize(T.PostOpDay,0:11:33),...
   [1,2,3],{'Early','Mid','Late'});
[G,data] = findgroups(T(:,{'GroupID','AnimalID','Area','Period','PostOpDay','PostOpDay_Cubed'}));
data.(responseVar) = splitapply(@(x)round(nanmean(x)),T.(responseVar),G);
data.N_Total = splitapply(@(x)round(nanmean(x)),T.N_Total,G);
data.Performance_mu = splitapply(@(x)nanmean(x),T.Performance_mu,G);

% Recover models for predicting interpolated values of random effects, in
% order to visualize responses as trends across days
randomVarStr = '';
randMdl = struct;
if isnumeric(pars.ID)
   rand_substr = sprintf('%s_r\%s',num2str(pars.ID));
else
   rand_substr = sprintf('%s_r\%s',pars.ID);
end
randVarName = cell(size(pars.RandomCovariates));
randResName = cell(size(pars.RandomCovariates));
for iR = 1:numel(pars.RandomCovariates)
   if ~ismember(pars.RandomCovariates{iR},data.Properties.VariableNames)
      data.(pars.RandomCovariates{iR}) = splitapply(@(x,id)utils.getUniqueTrialsAverage(x,id),...
         T.(pars.RandomCovariates{iR}),T.Trial_ID,G);
   end
   randMdl.(pars.RandomCovariates{iR}).tag = pars.Tag;
   randMdl.(pars.RandomCovariates{iR}).id = sprintf(rand_substr,pars.RandomCovariates{iR});
   randMdl.(pars.RandomCovariates{iR}).mdl = fitglme(data,...
      sprintf(pars.RandomModelFormula,pars.RandomCovariates{iR}),...
      'FitMethod','REMPL','DummyVarCoding','Effects');
   randVarName{iR} = sprintf('%s_pred',pars.RandomCovariates{iR});
   randResName{iR} = sprintf('%s_res',pars.RandomCovariates{iR});
   T.(randVarName{iR}) = predict(randMdl.(pars.RandomCovariates{iR}).mdl,T);
   T.(randResName{iR}) = T.(pars.RandomCovariates{iR})-T.(randVarName{iR});
   
%    randomVarStr = [randomVarStr, sprintf('+%s',pars.RandomCovariates{iR})]; %#ok<AGROW>
   randomVarStr = [randomVarStr, sprintf('+%s',randResName{iR})]; %#ok<AGROW>
   
end
mdlspec = string(sprintf(pars.ModelFormula,responseVar,randomVarStr));
if iscolumn(pars.FitOptions)
   pars.FitOptions = pars.FitOptions';
end

% data = outerjoin(data,B,'Keys',{'GroupID','AnimalID','PostOpDay','PostOpDay_Cubed'},...
%    'MergeKeys',true,...
%    'Type','left',...
%    'RightVariables',{'GroupID','AnimalID','PostOpDay','PostOpDay_Cubed','Performance_mu','Performance_hat_mu','Performance_hat_cb95'});
mdlTic = tic;
fprintf(1,'Fitting model: %s  ...',mdlspec);
mdl.id = pars.ID;
mdl.tag = pars.Tag;
% mdl.mdl = fitglme(data,mdlspec,pars.FitOptions{:},'BinomialSize',data.N_Total);
mdl.mdl = fitglme(T,mdlspec,pars.FitOptions{:},'BinomialSize',T.N_Total);
mdl.submodels = randMdl;
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
ax = [ ...
   axes(fig,'NextPlot','add','XColor','k','YColor','k','LineWidth',1.5,...
         'FontName','Arial','XLim',xLim,'YLim',yLim,'Units','Normalized',...
         'Position',[0.15 0.55 0.30 0.30],'Tag','Intact CFA - Successful'), ...
   axes(fig,'NextPlot','add','XColor','k','YColor','k','LineWidth',1.5,...
         'FontName','Arial','XLim',xLim,'YLim',yLim,'Units','Normalized',...
         'Position',[0.55 0.55 0.30 0.30],'Tag','Intact CFA - Unsuccessful'); ...
   axes(fig,'NextPlot','add','XColor','k','YColor','k','LineWidth',1.5,...
         'FontName','Arial','XLim',xLim,'YLim',yLim,'Units','Normalized',...
         'Position',[0.15 0.15 0.30 0.30],'Tag','Injured RFA - Successful'), ...
   axes(fig,'NextPlot','add','XColor','k','YColor','k','LineWidth',1.5,...
         'FontName','Arial','XLim',xLim,'YLim',yLim,'Units','Normalized',...
         'Position',[0.55 0.15 0.30 0.30],'Tag','Injured RFA - Unsuccessful')];
areaTags = ["Intact CFA"; "Injured RFA"];
sTags = ["Successful","Unsuccessful"];
for iAxRow = 1:2
   ylabel(ax(iAxRow,1),sprintf('%s (%s)',yLabel,areaTags(iAxRow)),...
      'FontName','Arial','Color','k');
end
for iAxCol = 1:2
   title(ax(1,iAxCol),sprintf('%s (%s)',yLabel,sTags(iAxCol)),'FontName','Arial','Color','k');
end
for iAxCol = 1:2
   xlabel(ax(2,iAxCol),pars.XLabel,'FontName','Arial','Color','k');
end

% [Gplot,TIDplot] = findgroups(data(:,{'GroupID','AnimalID','Area'}));
[Gplot,TIDplot] = findgroups(T(:,{'GroupID','AnimalID','Area','Outcome'}));

iMarker = struct('Intact',struct('CFA',struct('Successful',0,'Unsuccessful',0),...
                                 'RFA',struct('Successful',0,'Unsuccessful',0)),...
                 'Ischemia',struct('CFA',struct('Successful',0,'Unsuccessful',0),...
                                   'RFA',struct('Successful',0,'Unsuccessful',0)));
needsLegend = true(2,2);
Data = [];
hGroup = gobjects(size(TIDplot,1),1);
for ii = 1:size(TIDplot,1)
   gName = string(TIDplot.GroupID(ii));
   aName = string(TIDplot.Area(ii));
   oName = string(TIDplot.Outcome(ii));
   c = pars.Color.(gName).(aName);
   
   iAxRow = find(contains(areaTags,aName),1,'first');
   iAxCol = find(contains(sTags,oName),1,'first');
   
   iMarker.(gName).(aName).(oName) = iMarker.(gName).(aName).(oName) + 1;
%    theseData = data(Gplot==ii,:);
   theseData = T(Gplot==ii,:);
   if size(theseData,1) < 5
      fprintf(1,'Insufficient data: %s::%s (skipped)\n',string(TIDplot.AnimalID(ii)),aName);
      continue;
   end
   
   [gPred,tPred] = findgroups(theseData(:,{'GroupID','Area','AnimalID','Outcome',...
      pars.TimeTrendVar, cube_term, 'Performance_mu'}));
   tPred.N_Total = splitapply(@nansum,theseData.N_Total,gPred);
   tPred.N_Channels = splitapply(@(ch)numel(unique(ch)),theseData.ChannelID,gPred);
   tPred.N_Blocks = splitapply(@(bl)numel(unique(bl)),theseData.BlockID,gPred);
   tPred.N_Animals = splitapply(@(a)numel(unique(a)),theseData.AnimalID,gPred);
   tPred.N_Trials = splitapply(@(tr)numel(unique(tr)),theseData.Trial_ID,gPred);
   tPred.(responseVar) = splitapply(@nanmean,theseData.(responseVar),gPred);
%    Day = (min(theseData.(pars.TimeTrendVar)):max(theseData.(pars.TimeTrendVar)))';
%    Day_Cubed = Day.^3;
%    Day = theseData.(pars.TimeTrendVar);
%    Day_Cubed = theseData.(cube_term);
%    nDay = numel(Day);
%    GroupID = repmat(TIDplot.GroupID(ii),nDay,1);
%    Area = repmat(TIDplot.Area(ii),nDay,1);
%    AnimalID = repmat(TIDplot.AnimalID(ii),nDay,1);
%    N_Total = theseData.N_Total;
%    
%    Period = categorical(discretize(Day,0:11:33),...
%       [1,2,3],{'Early','Mid','Late'});
%    dayVec = 1:nDay;
%    mrkIndices = dayVec(ismember(Day,theseData.(pars.TimeTrendVar)));
%    mrkIndices = dayVec(~isnan(theseData.(responseVar)));

%    tPred = table(GroupID,AnimalID,Area,Period,Day,Day_Cubed,N_Total);
%    tPred.Properties.VariableNames{'Day'} = pars.TimeTrendVar;
%    tPred.Properties.VariableNames{'Day_Cubed'} = cube_term;
%    tPred.Performance_mu = theseData.Performance_mu;
%    tPred.Performance_hat_mu = theseData.Performance_hat_mu;
%    tPred.Performance_hat_cb95 = theseData.Performance_hat_cb95;
   for iR = 1:numel(pars.RandomCovariates)  
      if ~ismember(pars.RandomCovariates{iR},tPred.Properties.VariableNames)
%          tPred.(pars.RandomCovariates{iR}) = predict(randMdl.(pars.RandomCovariates{iR}).mdl,tPred);
         tPred.(randVarName{iR}) = predict(randMdl.(pars.RandomCovariates{iR}).mdl,tPred);
         if strcmpi(randMdl.(pars.RandomCovariates{iR}).mdl.Distribution,'binomial')
%             tPred.(pars.RandomCovariates{iR}) = tPred.(pars.RandomCovariates{iR}) .* tPred.N_Total;
            tPred.(randVarName{iR}) = tPred.(pars.RandomCovariates{iR}) .* tPred.N_Total ./ (tPred.N_Trials .* tPred.N_Channels);
         end
         tPred.(pars.RandomCovariates{iR}) = splitapply(@nanmean,theseData.(pars.RandomCovariates{iR}),gPred);
         tPred.(randResName{iR}) = tPred.(pars.RandomCovariates{iR}) - tPred.(randVarName{iR});
      end
   end
   
   [tPred.mu,tPred.cb95] = predict(mdl.mdl,tPred);
   if strcmpi(mdl.mdl.Distribution,'binomial')
%       tPred.mu = tPred.mu .* tPred.N_Total; 
%       tPred.cb95 = tPred.cb95 .* tPred.N_Total;
      tPred.mu = tPred.mu .* tPred.N_Total ./ (tPred.N_Trials .* tPred.N_Channels);
      tPred.cb95 = tPred.cb95 .* tPred.N_Total ./ (tPred.N_Trials .* tPred.N_Channels);
   end
   
   iBad = diff(tPred.cb95,1,2)>= pars.BadConfBand;
   tPred.cb95(iBad,:) = nan(sum(iBad),2);
   
   Data = [Data; tPred]; %#ok<AGROW>
   
   hGroup(ii) = gfx__.plotWithShadedError(ax(iAxRow,iAxCol),...
      tPred.(pars.TimeTrendVar),tPred.mu,tPred.cb95,...
      'FaceColor',c,...
      'FaceAlpha',pars.FaceAlpha,...
      'Marker',pars.MarkerOrder(iMarker.(gName).(aName).(oName)),...
      ... 'MarkerIndices',mrkIndices,...
      'MarkerEdgeColor','k',...
      'DisplayName',sprintf('%s (fit)',string(TIDplot.AnimalID(ii))),...
      'Annotation','on',...
      'Tag',sprintf('Trend::%s::%s',gName,aName),...
      'LineWidth',pars.LineWidth);
   hScatter = scatter(ax(iAxRow,iAxCol),...
      tPred.(pars.TimeTrendVar),...
      tPred.(responseVar),'filled',...
      'Marker',pars.MarkerOrder(iMarker.(gName).(aName).(oName)),...
      'MarkerFaceColor',c,...
      'MarkerEdgeColor','none',...
      'MarkerFaceAlpha',pars.MarkerFaceAlpha,...
      'Tag',sprintf('Scatter::%s::%s',gName,aName),...
      'DisplayName',sprintf('%s (observed)',string(TIDplot.AnimalID(ii))));
   eLineX = ([tPred.(pars.TimeTrendVar),tPred.(pars.TimeTrendVar),nan(size(tPred,1),1)])';
%    eLineY = ([theseData.(responseVar),tPred.mu(mrkIndices),nan(size(theseData,1),1)])';
   eLineY = ([tPred.(responseVar),tPred.mu,nan(size(tPred,1),1)])';
   hLine = line(ax(iAxRow,iAxCol),eLineX(:),eLineY(:),...
      'LineStyle',pars.ErrorLineStyle,...
      'LineWidth',pars.ErrorLineWidth,...
      'Color',c,...
      'DisplayName','Matched Observation');
   if strcmpi(pars.LegendStyle,'standard')
      if needsLegend(iAxRow,iAxCol)
         trendLine = hGroup(ii).Children(1);
         trendErr = hGroup(ii).Children(2);
         legend([trendLine,trendErr,hScatter,hLine],...
            pars.LegendLabels,...
            'TextColor','black',...
            'FontName','Arial',...
            'FontSize',9,...
            'EdgeColor','none',...
            'Color','white',...
            'AutoUpdate','off',...
            'Location',pars.LegendLocation);
         needsLegend(iAxRow,iAxCol) = false;
      end
   end
   drawnow;
end
if strcmpi(pars.LegendStyle,'animals')
   [~,iU] = unique(TIDplot.AnimalID);
   hGroup = hGroup(iU);
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
      'FontName','TimesNewRoman',...
      'FontSize',8,...
      'EdgeColor','none',...
      'NumColumns',1,...
      'Color','none',...
      'AutoUpdate','off',...
      ...'Location',pars.LegendLocation);
      'Parent',fig,...
      'Units','Normalized',...
      'Position',[0.80 0.35 0.15 0.30]);
end
Data = splitvars(Data,'cb95');
Data.Properties.VariableNames{'cb95_1'} = 'cb95_lb';
Data.Properties.VariableNames{'cb95_2'} = 'cb95_ub';
Data.cb95 = Data.cb95_ub - Data.cb95_lb;
Data.Week = ordinal(ceil(Data.(pars.TimeTrendVar)./7));

utils.displayModel(mdl);
suptitle(pars.Title);
end