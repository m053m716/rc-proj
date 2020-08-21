function T = groupLevelTests(rWeek,mdl,fullData,origFcn,origVars)
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

resp = strrep(mdl.ResponseName,'_mean','');
pVar = sprintf('%s_p',resp);
numVar = sprintf('%s_DF_num',resp);
denVar = sprintf('%s_DF_den',resp);
fVar = sprintf('%s_f',resp);

[G,T] = findgroups(rWeek(:,{'Group','Area','Week'}));

nRow = size(T,1);
T.(pVar) = nan(nRow,1);
T.(numVar) = nan(nRow,1);
T.(denVar) = nan(nRow,1);
T.(fVar) = nan(nRow,1);

H = mdl.designMatrix;
H(:,1:(end-1)) = 0; % Set everything except for the full-way interaction term to zero
[~,~,stats] = randomEffects(mdl);
q = size(stats,1);

for iRow = 1:nRow
   thisAnimal = string(rWeek.AnimalID(G==iRow));
   m = numel(thisAnimal);
   h = zeros(m,q);
   for iU = 1:m
      iAnimal = strcmpi(cellstr(stats.Level),thisAnimal(iU));
      h(1,iAnimal & strcmpi(cellstr(stats.Name),'Week')) = T.Week(iRow);
      h(1,iAnimal & strcmpi(cellstr(stats.Name),'Week_Cubed')) = T.Week(iRow).^3;
   end
         
   [T.(pVar)(iRow),T.(fVar)(iRow),T.(numVar)(iRow),T.(denVar)(iRow)] = ...
      coefTest(mdl,H(G==iRow,:),zeros(m,1),'REContrast',h);
   
end

T.mean = nan(nRow,1);
T.sd   = nan(nRow,1);
[G,tMatch] = findgroups(fullData(:,{'Group','Area','Week'}));
mu = splitapply(origFcn.mu,fullData(:,origVars),G);
sigma = splitapply(origFcn.sigma,fullData(:,origVars),G);
for iRow = 1:size(tMatch,1)
   iOut = find(T.Group==tMatch.Group(iRow) & ...
               T.Area==tMatch.Area(iRow) & ...
               T.Week==tMatch.Week(iRow),1,'first');
   if isempty(iOut)
      continue;
   end
   T.mean(iOut) = mu(iRow);
   T.sd(iOut) = sigma(iRow);
end

end