function [T_M,fig,mdl_mu] = groupLevelTests(rWeek,mdl,fullData,origFcn,origVars)
%GROUPLEVELTESTS Get statistical test for each {'Group','Area','Week'}level
%
%  T = analyze.stat.groupLevelTests(rWeek,mdl,fullData,origFcn,origVars);
%
% Inputs
%  rWeek - Table with grouped data by week
%  mdl   - GeneralizedLinearMixedModel fit to rWeek 
%  fullData - The individual observations used to create means fit by mdl.
%  origFcn - Function handle to recover original response observations
%              -> Struct with two fields: 'mu' (for mean) and 'sigma' (for
%                    standard deviation)
%  origVars - Table variables used in combination with origFcn (cell array)
%
% Output
%  T - Aggregated output table from rWeek with new variables
%           * [mdl.ResponseName]_p (p-value)
%           * [mdl.ResponseName]_DF_num (numerator degrees of freedom)
%           * [mdl.ResponseName]_DF_den (denominator degrees of freedom)
%           * [mdl.ResponseName]_f (from f-tests)
%
% See also: analyze.stat, analyze.stat.parseLevelTests, 
%           unit_learning_stats

fullData.Week_Sigmoid = exp(3.*(fullData.Week-2.5))./(1+exp(3.*(fullData.Week-2.5)))-0.5;
fullData.Properties.VariableNames{'Performance_mu'} = 'Performance';
fullData.Performance(isnan(fullData.Performance)) = ...
   fullData.Performance_hat_mu(isnan(fullData.Performance));

resp = strrep(mdl.ResponseName,'_mean','');
pVar = sprintf('%s_p',resp);
numVar = sprintf('%s_DF_num',resp);
denVar = sprintf('%s_DF_den',resp);
fVar = sprintf('%s_f',resp);

[G_M,T_M] = findgroups(rWeek(:,{'GroupID','Area','Week'}));
[G_m,~] = findgroups(fullData(:,{'GroupID','Area','Week'}));


nRow = size(T_M,1);
T_M.(pVar) = nan(nRow,1);
T_M.(numVar) = nan(nRow,1);
T_M.(denVar) = nan(nRow,1);
T_M.(fVar) = nan(nRow,1);

isCategorical = mdl.VariableInfo.IsCategorical(mdl.Formula.FELinearFormula.InModel) ...
   | strcmpi(mdl.VariableInfo.Properties.RowNames(mdl.Formula.FELinearFormula.InModel),'Week');

conName = mdl.Formula.FELinearFormula.PredictorNames(~isCategorical);
catNames = mdl.Formula.FELinearFormula.PredictorNames(isCategorical);
feNames = mdl.Formula.FELinearFormula.TermNames';
iZero = true(1,numel(feNames)); % Final Interaction term is never zeroed

iCat = false(numel(catNames),numel(iZero));
for ii = 1:size(iCat,1)
   iCat(ii,:) = contains(feNames,catNames{ii});
end

iZero(all(iCat,1)) = false; % Get the main interaction "categorical" grouping
iZero(contains(feNames,conName)) = false; % All continuous terms should be kept
% H = mdl.designMatrix;
% H(:,iZero) = 0; % Set everything except for the full-way interaction term to zero
[~,~,stats] = randomEffects(mdl);
q = size(stats,1);
names = cellstr(stats.Name);
randVars = [];
% groupVars = [];
for iF = 1:numel(mdl.Formula.RELinearFormula)
   randVars = [randVars; mdl.Formula.RELinearFormula{iF}.TermNames]; %#ok<AGROW>
%    groupVars = [groupVars; repmat(mdl.Formula.GroupingVariableNames{iF},numel(mdl.Formula.RELinearFormula{iF}.TermNames),1)]; %#ok<AGROW>
end

% groupVars(contains(randVars,'Intercept')) = [];
randVars(contains(randVars,'Intercept')) = [];

groupNames = cellstr(stats.Level);

% Get design matrix for fixed effects
D = logical(mdl.Formula.FELinearFormula.Terms(:,mdl.Formula.FELinearFormula.InModel));
X = nan(size(fullData,1),mdl.Formula.FELinearFormula.NPredictors);
pn = mdl.Formula.FELinearFormula.PredictorNames;
for iX = 1:size(X,2)
   if iscategorical(fullData.(pn{iX}))
      iCat = fullData.(pn{iX})==fullData.(pn{iX})(1);
      X(iCat,iX) = 1;
      X(~iCat,iX) = -1;
   else
      X(:,iX) = fullData.(pn{iX});
   end
end
% Fixed effects hypothesis test design matrix:
% H = X * D;
nTotal = size(X,1);
H = ones(nTotal,size(D,1));
for iH = 2:size(H,2)
   H(:,iH) = prod(X(:,D(iH,:)),2);
end

% H(:,iZero) = 0; % Set everything except for the full-way interaction term to zero



for iRow = 1:nRow
   iFull = G_m == iRow;
   m = sum(iFull);
   C = nanmean(fullData.(origVars{1})((fullData.Area==T_M.Area(iRow))&(fullData.GroupID==T_M.GroupID(iRow))));
   thisData = fullData(iFull,:);
   thisAnimal = string(rWeek.AnimalID(G_M==iRow));
   M = numel(thisAnimal);
   % Random effects contrasts
   h = zeros(m,q);
   
   for iU = 1:M
      theseChannels = unique(thisData.ChannelID(thisData.AnimalID==thisAnimal(iU)));
      iFull_Animal = thisData.AnimalID==thisAnimal(iU);
      iAnimal = strcmpi(groupNames,thisAnimal(iU)) | ismember(groupNames,string(theseChannels));      
      
      for iV = 1:numel(randVars) 
         if contains(randVars{iV},'Intercept')
            continue; % Always skip Intercept terms
         end
         if endsWith(randVars{iV},'_Cubed')
            varName = strsplit(randVars{iV},'_');
            varName = strjoin(varName(1:(end-1)),'_');
            randCoeffIdx = (iAnimal & strcmpi(names,randVars{iV}))';
            if sum(randCoeffIdx)==0
               continue;
            end
            h(iFull_Animal,randCoeffIdx) = rWeek.(varName)(iRow).^3;
         elseif endsWith(randVars{iV},'_Sigmoid')
            varName = strsplit(randVars{iV},'_');
            varName = strjoin(varName(1:(end-1)),'_');
            randCoeffIdx = (iAnimal & strcmpi(names,randVars{iV}))'; 
            if sum(randCoeffIdx)==0
               continue;
            end
            h(iFull_Animal,randCoeffIdx)  = ...
               exp(3.*(rWeek.(varName)(iRow)-2.5))./...
                  (1 + exp(3.*(rWeek.(varName)(iRow)-2.5))) - 0.5;
         elseif strcmpi(randVars{iV},'Week')
            randCoeffIdx = (iAnimal & strcmpi(names,randVars{iV}))';
            if sum(randCoeffIdx)==0
               continue;
            end
            h(iFull_Animal,randCoeffIdx) = thisData.(randVars{iV})(iFull_Animal);
         end
      end
   end
   
   try
%       [T_M.(pVar)(iRow),T_M.(fVar)(iRow),T_M.(numVar)(iRow),T_M.(denVar)(iRow)] = ...
%          coefTest(mdl,H(iFull,:),zeros(m,1),'REContrast',h);
      [T_M.(pVar)(iRow),T_M.(fVar)(iRow),T_M.(numVar)(iRow),T_M.(denVar)(iRow)] = ...
         coefTest(mdl,H(iFull,:),ones(m,1).*C,'REContrast',h);
   catch
      continue;
   end


%    try 
%       [T_M.(pVar)(iRow),T_M.(fVar)(iRow),T_M.(numVar)(iRow),T_M.(denVar)(iRow)] = ...
%          coefTest(mdl,H(iFull,:),zeros(m,1));
%    catch
%       continue;
%    end
   
end

randVars = setdiff(randVars,T_M.Properties.VariableNames);

T_M.Performance = nan(nRow,1);
T_M.mean = nan(nRow,1);
T_M.sd   = nan(nRow,1);
T_M.nObs = nan(nRow,1);
for iV = 1:numel(randVars)
   T_M.(randVars{iV}) = nan(nRow,1);
end
T_M.Weights = nan(nRow,1);

[G_M,tMatch] = findgroups(fullData(:,{'GroupID','Area','Week'}));
mu = splitapply(origFcn.mu,fullData(:,origVars),G_M);
sigma = splitapply(origFcn.sigma,fullData(:,origVars),G_M);
perf = splitapply(@nanmean,fullData.Performance,G_M);
nObs = splitapply(@(x)sum(~isnan(x)),fullData.Performance,G_M);
[gWeight,wMatch] = findgroups(mdl.Variables(:,{'GroupID','Area','Week'}));
weights = splitapply(@(x)sum(x),mdl.ObservationInfo.Weights,gWeight);
val = nan(numel(nObs),numel(randVars));
for iV = 1:numel(randVars)
   if strcmpi(randVars{iV},'n_Pre_mean')
      val(:,iV) = splitapply(@nanmean,fullData.N_Pre_Grasp,G_M);
   else
      val(:,iV) = splitapply(@nanmean,fullData.(randVars{iV}),G_M);
   end
end

for iRow = 1:size(tMatch,1)
   iOut = find(T_M.GroupID==tMatch.GroupID(iRow) & ...
               T_M.Area==tMatch.Area(iRow) & ...
               T_M.Week==tMatch.Week(iRow),1,'first');
   if isempty(iOut)
      continue;
   end
   T_M.Performance(iOut) = perf(iRow);
   T_M.mean(iOut) = mu(iRow);
   T_M.sd(iOut) = sigma(iRow);
   T_M.nObs(iOut) = nObs(iRow);
   for iV = 1:numel(randVars)
      T_M.(randVars{iV})(iOut) = val(iRow,iV);
   end
   
   if iRow <= size(wMatch,1)
      iOut = find(T_M.GroupID==wMatch.GroupID(iRow) & ...
                  T_M.Area==wMatch.Area(iRow) & ...
                  T_M.Week==wMatch.Week(iRow),1,'first');
      if isempty(iOut)
         continue;
      end
      T_M.Weights(iOut) = weights(iRow);
   end
end

if nargout < 2
   fig = [];
   return;
end

fig = figure('Name',sprintf('Weekly Spike Trends: %s',resp),...
   'Color','w','Units','Normalized','Position',[0.1 0.1 0.35 0.6],...
   'NumberTitle','off');
utils.addHelperRepos();
[~,TID] = findgroups(T_M(:,{'GroupID','Area'}));
ax = axes(fig,'XColor','k','YColor','k','LineWidth',1.5,...
   'NextPlot','add','FontName','Arial',...
   'XLim',[0 5],'XTick',1:4);
title(ax,strrep(upper(resp),'_',' '),'FontName','Arial','Color','k');
xlabel(ax,'Week','FontName','Arial','Color','k');
h = gobjects(size(TID,1),1);
mdlspec = sprintf('%s~Week*Area*GroupID',mdl.ResponseName);
mdl_mu = fitglme(rWeek,mdlspec,...
   'DummyVarCoding','effects',...
   'FitMethod','REMPL',...
   'Distribution','normal',...
   'Link','identity');
Week = (1:4)';
MRK = struct('CFA','o','RFA','s');
C = struct('Ischemia',[0.9 0.1 0.1],'Intact',[0.1 0.1 0.9]);

for iRow = 1:size(TID,1)
   lab = sprintf('%s::%s',string(TID.GroupID(iRow)),string(TID.Area(iRow)));
   rPred = repmat(TID(iRow,:),4,1);
   rPred.Week = Week;
   [Value,CB95] = predict(mdl_mu,rPred);
   c = C.(string(TID.GroupID(iRow)));
   mrk = MRK.(string(TID.Area(iRow)));
   
   h(iRow) = gfx__.plotWithShadedError(ax,...
      Week,Value,CB95,...
      'FaceColor',c,...
      'FaceAlpha',0.5,...
      'Marker',mrk,...
      'MarkerEdgeColor','k',...
      'DisplayName',lab,...
      'Annotation','on',...
      'Tag',lab,...
      'LineWidth',2.0);
   
end
legend(h,'TextColor','black','FontName','Arial','Color','none',...
   'Location','eastoutside','EdgeColor','none');

end