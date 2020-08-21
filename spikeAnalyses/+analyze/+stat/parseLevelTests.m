function rWeek = parseLevelTests(rWeek,mdl)
%PARSELEVELTESTS Get statistical test for each row of `rWeek`
%
%  rWeek = analyze.stat.parseLevelTests(rWeek,mdl);
%
% Inputs
%  rWeek - Table with grouped data by week
%  mdl   - GeneralizedLinearMixedModel fit to rWeek 
%
% Output
%  rWeek - Updated table with new variables
%           * [mdl.ResponseName]_p (p-value)
%           * [mdl.ResponseName]_DF_num (numerator degrees of freedom)
%           * [mdl.ResponseName]_DF_den (denominator degrees of freedom)
%           * [mdl.ResponseName]_f (from f-tests)
%
% See also: analyze.stat, unit_learning_stats

resp = strrep(mdl.ResponseName,'_mean','');
nRow = size(rWeek,1);
pVar = sprintf('%s_p',resp);
numVar = sprintf('%s_DF_num',resp);
denVar = sprintf('%s_DF_den',resp);
fVar = sprintf('%s_f',resp);

rWeek.(pVar) = nan(nRow,1);
rWeek.(numVar) = nan(nRow,1);
rWeek.(denVar) = nan(nRow,1);
rWeek.(fVar) = nan(nRow,1);

H = mdl.designMatrix;
H(:,1:(end-1)) = 0; % Set everything except for the full-way interaction term to zero
[~,~,stats] = randomEffects(mdl);
q = size(stats,1);

for iRow = 1:nRow
   h = zeros(1,q);
   iAnimal = strcmpi(cellstr(stats.Level),string(rWeek.AnimalID(iRow)));
   h(1,iAnimal & strcmpi(cellstr(stats.Name),'Week')) = rWeek.Week(iRow);
   h(1,iAnimal & strcmpi(cellstr(stats.Name),'Week_Cubed')) = rWeek.Week_Cubed(iRow);
         
   [rWeek.(pVar)(iRow),rWeek.(fVar)(iRow),rWeek.(numVar)(iRow),rWeek.(denVar)(iRow)] = ...
      coefTest(mdl,H(iRow,:),0,'REContrast',h);
   
end

end