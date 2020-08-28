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
% pars.DeviationType = '1 SD'; % '1 SD' | 'SEM'
pars.DeviationType = 'SEM';
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
pars.LegendLocation = 'eastoutside';
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
pars.ModelFormula = '%s~GroupID*Area+(1+%s|AnimalID)';
pars.Offset = struct('Ischemia',...
      struct('RFA',0.1,...
             'CFA',0.2), ...
          'Intact',...
       struct('RFA',-0.2,...
              'CFA',-0.1));
pars.SimpleModelFormula = '%s~%s+1+(1+Duration+Performance_mu+PostOpDay|AnimalID)';
pars.Tag = '';
pars.TimeTrendVar = 'PostOpDay';
pars.Title = '';
pars.XLabel = 'Day';
pars.XLim = [nan nan];
pars.YLabel = '';
pars.YLim = [nan nan];
pars.YLim_Duration = [0 1.0];

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
T.Properties.UserData.Excluded(T.Outcome=="Unsuccessful") = [];
T(T.Outcome=="Unsuccessful",:) = [];

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
% T.PostOpDayc = ordinal(T.PostOpDay);
[G,data] = findgroups(T(:,{'GroupID','AnimalID','Area','PostOpDay','PostOpDay_Cubed'}));
data.(responseVar) = splitapply(@(x)round(nanmean(x)),T.(responseVar),G);
data.N_Total = splitapply(@(x)round(nanmean(x)),T.N_Total,G);
data.Duration = splitapply(@(x)nanmean(x),T.Duration,G);
data.Reach_Epoch_Duration = splitapply(@(x)nanmean(x),T.Reach_Epoch_Duration,G);
data.Retract_Epoch_Duration = splitapply(@(x)nanmean(x),T.Retract_Epoch_Duration,G);
data.Performance_mu = splitapply(@(x)nanmean(x),T.Performance_mu,G);

if isempty(pars.DurationTrendVar) || strcmpi(pars.DurationTrendVar,'Duration')
   pars.SimpleModelFormula = strrep(pars.SimpleModelFormula,'%s~%s+','%s~');
   simpleModelSpec = sprintf(pars.SimpleModelFormula,responseVar);
else
   simpleModelSpec = sprintf(pars.SimpleModelFormula,responseVar,pars.DurationTrendVar);
end
fprintf(1,'<strong>(MODEL-%s: %s)</strong> Fitting simple model:\n',...
   string(pars.ID),pars.Tag);
fprintf(1,'\t->\t"%s"\n\n',simpleModelSpec);
if isnumeric(pars.ID)
   mdl.simple.id = sprintf('%s_s',num2str(pars.ID));
else
   mdl.simple.id = sprintf('%s_s',pars.ID);
end
mdl.simple.tag = sprintf('Simple Detrending: %s',pars.Tag);
mdl.simple.mdl = fitglme(data,simpleModelSpec,pars.FitOptions{:},...
   'BinomialSize',data.N_Total);
predName = sprintf('%s_pred',responseVar);
T.(predName) = predict(mdl.simple.mdl,T).*T.N_Total;
residName = sprintf('%s_res',responseVar);
T.(residName)= T.(responseVar)-T.(predName);

mdlspec = string(sprintf(pars.ModelFormula,responseVar,residName));
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

fig = figure('Name',sprintf('%s by Day (Average Grouped Trends)',responseVar),...
   'Units','Normalized','Position',[0.545 0.125 0.323 0.750],'Color','w');
ax_spikes = subplot(2,1,2);
set(ax_spikes,'Parent',fig,'NextPlot','add',...
   'XColor','k','YColor','k','LineWidth',1.5,'Tag','DurationAxes',...
   'FontName','Arial','XLim',xLim,'YLim',yLim);
ylabel(ax_spikes,sprintf('%s (mean \\pm %s)',yLabel,pars.DeviationType),...
      'FontName','Arial','Color','k','FontWeight','bold');
title(ax_spikes,pars.Title,'FontName','Arial','Color','k','FontWeight','bold');
xlabel(ax_spikes,pars.XLabel,'FontName','Arial','Color','k','FontWeight','bold');
[G,Data] = findgroups(T(:,{'GroupID','Area','PostOpDay'}));
sdVar = sprintf('%s_sd',responseVar);
semVar = sprintf('%s_sem',responseVar);
Data.(responseVar) = splitapply(@(x)round(nanmean(x)),T.(responseVar),G);
Data.(sdVar) = splitapply(@(x)nanstd(x),T.(responseVar),G);
Data.(semVar) = splitapply(@(x,tr)nanstd(x)/sqrt(numel(unique(tr))),T.(responseVar),T.Trial_ID,G);
Data.N_Total = splitapply(@(x)round(nanmean(x)),T.N_Total,G);
Data.N_Trials = splitapply(@(x)numel(unique(x)),T.Trial_ID,G);
Data.N_Channels = splitapply(@(x)numel(unique(x)),T.ChannelID,G);
Data.N_Blocks = splitapply(@(x)numel(unique(x)),T.BlockID,G);
Data.N_Animals = splitapply(@(x)numel(unique(x)),T.AnimalID,G);
Data.Duration = splitapply(@(x)nanmean(x),T.Duration,G);
Data.Reach_Epoch_Duration = splitapply(@(x)nanmean(x),T.Reach_Epoch_Duration,G);
Data.Retract_Epoch_Duration = splitapply(@(x)nanmean(x),T.Retract_Epoch_Duration,G);
Data.Performance_mu = splitapply(@(x)nanmean(x),T.Performance_mu,G);

durVar = strrep(pars.DurationTrendVar,'_',' ');
% durVar_s = strsplit(durVar,'_');

ax_duration = subplot(2,1,1);
set(ax_duration,'Parent',fig,'NextPlot','add',...
   'XColor','k','YColor','k','LineWidth',1.5,'Tag','DurationAxes',...
   'FontName','Arial','XLim',xLim,'YLim',pars.YLim_Duration);
ylabel(ax_duration,sprintf('%s (mean \\pm SEM)',T.Properties.VariableUnits{pars.DurationTrendVar}),...
   'FontName','Arial','Color','k','FontWeight','bold');
title(ax_duration,durVar,'FontName','Arial','Color','k','FontWeight','bold');
Data.(pars.DurationTrendVar) = splitapply(@(x)nanmean(x),T.(pars.DurationTrendVar),G);
durSEM = sprintf('%s_sem',pars.DurationTrendVar);
Data.(durSEM) = splitapply(@(x,b)nanstd(x)./sqrt(numel(unique(b))),T.(pars.DurationTrendVar),T.BlockID,G);
utils.addHelperRepos();

[G,TID] = findgroups(Data(:,{'GroupID','Area'}));

for ii = 1:size(TID,1)
   gName = string(TID.GroupID(ii));
   aName = string(TID.Area(ii));
   c = pars.Color.(gName).(aName);
   o = pars.Offset.(gName).(aName);
   [Day,iSort] = sort(Data.PostOpDay(G==ii),'ascend');
   mu = Data.(responseVar)(G==ii);
   mu = mu(iSort);
   if strcmpi(pars.DeviationType,'SEM')
      dev = Data.(semVar)(G==ii);
      dev = dev(iSort);
      out_thresh = nanmean(mu)+15*nanmean(dev);
   else
      dev = Data.(sdVar)(G==ii);
      dev =dev(iSort);
      out_thresh = nanmean(mu)+4*nanmean(dev);
   end
   
   
   
   
   dev(mu > out_thresh) = nan;
   mu(mu > out_thresh) = nan;
   
   errorbar(ax_spikes,...
      Day+o,mu,dev,...
      'Color',c,...
      'Marker',pars.Marker.(gName).(aName),...
      'MarkerFaceColor','k',...
      'DisplayName',sprintf('%s_{%s}',gName,aName),...
      'Tag',sprintf('Trend::%s::%s',gName,aName),...
      'LineStyle',pars.LineStyle.(gName).(aName),...
      'LineWidth',pars.LineWidth);


   mu_t = Data.(pars.DurationTrendVar)(G==ii);
   sem_t = Data.(durSEM)(G==ii);
%    mu_t = sgolayfilt(mu_t,3,7);
%    sem_t = sgolayfilt(sem_t,3,7);
   if aName=="RFA"
      gfx__.plotWithShadedError(ax_duration,...
         Day+o,mu_t,sem_t,...
         'Color',c,...
         'FaceColor',c,...
         'DisplayName',sprintf('%s',gName),...
         'LineWidth',2.5,...
         'LineStyle',':',...
         'Tag','DurationTrend',...
         'Annotation','on');   
   end
   drawnow;
end
legend(ax_duration,...
   'TextColor','black',...
   'Location',pars.LegendLocation,...
   'FontSize',11,...
   'FontName','TimesNewRoman');
legend(ax_spikes,...
   'TextColor','black',...
   'Location',pars.LegendLocation,...
   'FontName','TimesNewRoman');

Data.Properties.UserData.Response = responseVar;
Data.Properties.UserData.Predictions = predName;
Data.Properties.UserData.Residuals = residName;
Data.Properties.UserData.Duration = pars.DurationTrendVar;
Data.Properties.UserData.SD = sdVar;
Data.Properties.UserData.SEM = semVar;


end