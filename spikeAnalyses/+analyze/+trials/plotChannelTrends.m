function [fig,P] = plotChannelTrends(mdl,duration,doExtrapolation)
%PLOTCHANNELTRENDS Plot model fit per-channel trends across weeks
%
%  fig = analyze.trials.plotChannelTrends(mdl);
%  fig = analyze.trials.plotChannelTrends(mdl,duration);
%  fig = analyze.trials.plotChannelTrends(mdl,duration,doExtrapolation);
%
% Inputs
%  mdl   - GeneralizedLinearMixedModel object fit using data grouped by
%           Channel/Week
%  duration - Scalar duration of epoch or vector that is the same size as
%              the input data table used to fit `mdl`, where each row is
%              the trial duration of the corresponding trial in `mdl`
%              observations.
%
% Output
%  fig - Figure handle
%  P   - Table of predicted output
%
% See also: unit_learning_stats, analyze.trials

if nargin < 2
   duration = 0.6; % Fixed epoch duration (PRE)
elseif isempty(duration)
   duration = 0.6;
end

if nargin < 3
   doExtrapolation = false;
end

C = struct('Ischemia',[0.9 0.1 0.1],...
           'Intact',[0.1 0.1 0.9]);
YLIM = [0 125];
utils.addHelperRepos();

T = mdl.Variables;
resp = strsplit(mdl.ResponseName,'_');
resp = resp{2};

fig = figure('Name',sprintf('Channel Trends: %s epoch',resp),...
   'Color','w','Units','Normalized','Position',[0.1 0.1 0.5 0.7]);
ax = struct('Intact',struct('CFA',gobjects(1),'RFA',gobjects(1)),...
            'Ischemia',struct('CFA',gobjects(1),'RFA',gobjects(1)));
groups = fieldnames(ax);
ii = 0;
for iGroup = 1:numel(groups)
   areas = fieldnames(ax.(groups{iGroup}));
   for iArea = 1:numel(areas)
      ii = ii + 1;
      ax.(groups{iGroup}).(areas{iArea}) = subplot(2,2,ii);
      areaTag = sprintf('%s %s',groups{iGroup},areas{iArea});
      set(ax.(groups{iGroup}).(areas{iArea}),'NextPlot','add',...
         'XColor','k','YColor','k','LineWidth',1.5,...
         'FontName','Arial','XLim',[0 5],'YLim',YLIM,'Tag',areaTag,...
         'Parent',fig);
      if rem(ii,2)==1
         ylabel(ax.(groups{iGroup}).(areas{iArea}),...
            sprintf('%s (spikes/sec)',groups{iGroup}),...
            'FontName','Arial','Color','k','FontWeight','bold');
      end
      if ii <= 2
         title(ax.(groups{iGroup}).(areas{iArea}),...
            sprintf('%s (%s)',areas{iArea},resp),...
            'FontName','Arial','Color','k','FontWeight','bold');
      end
      if ii > 2
         xlabel(ax.(groups{iGroup}).(areas{iArea}),'Post-Op Week',...
            'FontName','Arial','Color','k','FontWeight','bold');
      end
   end
end

fixedVars = {'ChannelID','GroupID','Area','AnimalID','Week'};
freeVars = setdiff(mdl.PredictorNames,fixedVars);
catVars = mdl.PredictorNames(mdl.VariableInfo.IsCategorical(mdl.VariableInfo.InModel));

[G,TID] = findgroups(T(:,{'ChannelID','GroupID','AnimalID','Area'}));
for iVar = 1:numel(freeVars)
   thisVar = freeVars{iVar};
   if ismember(thisVar,catVars)
      TID.(thisVar) = splitapply(@(x)x(1),T.(thisVar),G);
   else
      TID.(thisVar) = splitapply(@(x)nanmean(x),T.(thisVar),G);
   end
end
TID.n_Total = splitapply(@(x)round(nanmean(x)),T.n_Total,G);
nRow = size(TID,1);

if isscalar(duration)
   TID.duration = repmat(duration,nRow,1);
else
   TID.duration = splitapply(@(x)nanmedian(x),duration,G);
end

mu_out = sprintf('%s_mean',resp);
lb95_out = sprintf('%s_lb95',resp);
ub95_out = sprintf('%s_ub95',resp);

P = [];


Week = (0:5)';
Week_Sigmoid = exp(3.*(Week-2.5))./(1+exp(3.*(Week-2.5))) - 0.5;
for iRow = 1:nRow

   if doExtrapolation
      nWeek = numel(Week);
   else
      Week = (min(T.Week(T.ChannelID==TID.ChannelID(iRow))):max(T.Week(T.ChannelID==TID.ChannelID(iRow))))';
      if nWeek < 2
         continue;
      end
   end
   tPred = repmat(TID(iRow,:),nWeek,1);
   tPred.Week = Week;
   tPred.Week_Sigmoid = Week_Sigmoid;
   [mu,cb95] = predict(mdl,tPred);
   mu = mu.*TID.n_Total(iRow)./TID.duration(iRow);
   cb95 = cb95 .* TID.n_Total(iRow)./TID.duration(iRow);
   
%    if any((cb95(:,2) > 100) | (cb95(:,1) < 0))
%       continue;
%    end
   tPred.(mu_out) = mu;
   tPred.(lb95_out) = cb95(:,1);
   tPred.(ub95_out) = cb95(:,2);
   
   c = C.(string(TID.GroupID(iRow)));
   
   gfx__.plotWithShadedError(ax.(string(TID.GroupID(iRow))).(string(TID.Area(iRow))),...
      Week,tPred.(mu_out),cb95,...
      'FaceColor',c,...
      'FaceAlpha',0.05,...
      'DisplayName',sprintf('%s::%s',string(TID.GroupID(iRow)),string(TID.Area(iRow))),...
      'Annotation','on',...
      ... 'LineWidth',0.5,...
      'LineStyle','none'); 
   if nargout > 1
      P = [P; tPred]; %#ok<AGROW>
   end
   drawnow;
end


end