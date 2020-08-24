function rWeek = parseLevelTests(rWeek,mdl)
%PARSELEVELTESTS Get statistical test for each row of `rWeek`
%
%  rWeek = analyze.stat.parseLevelTests(rWeek,mdl);
%
% Inputs
%  rWeek    - Table with grouped data by week
%  mdl      - GeneralizedLinearMixedModel fit to rWeek
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
iZero(contains(feNames,conName)) = false; % All continuous terms should be retained

H = mdl.designMatrix;


H(:,iZero) = 0; % Set everything except for the full-way interaction term to zero
[~,~,stats] = randomEffects(mdl);
q = size(stats,1);

names = cellstr(stats.Name);

randVars = mdl.Formula.RELinearFormula{1}.TermNames;

for iRow = 1:nRow
   h = zeros(1,q);
   iAnimal = strcmpi(cellstr(stats.Level),string(rWeek.AnimalID(iRow)));
   for iV = 2:numel(randVars) % 1 is always intercept; skip it.
      if endsWith(randVars{iV},'_Cubed')
         varName = strsplit(randVars{iV},'_');
         varName = strjoin(varName(1:(end-1)),'_');
         h(1,iAnimal & strcmpi(names,randVars{iV})) = rWeek.(varName)(iRow).^3;
      elseif endsWith(randVars{iV},'_Sigmoid')
         varName = strsplit(randVars{iV},'_');
         varName = strjoin(varName(1:(end-1)),'_');
         h(1,iAnimal & strcmpi(names,randVars{iV})) = ...
            exp(3.*(rWeek.(varName)(iRow)-2.5))./...
               (1 + exp(3.*(rWeek.(varName)(iRow)-2.5))) - 0.5;
      else
         h(1,iAnimal & strcmpi(names,randVars{iV})) = rWeek.(randVars{iV})(iRow);
      end
   end
   
   try
      [rWeek.(pVar)(iRow),rWeek.(fVar)(iRow),rWeek.(numVar)(iRow),rWeek.(denVar)(iRow)] = ...
         coefTest(mdl,H(iRow,:),0,'REContrast',h);
   catch
%       fprintf(1,'\n<strong>Row</strong>: %d\n',iRow);
%       fprintf(1,'<strong>H</strong>: ');
%       disp(H(iRow,:));
%       fprintf(1,'<strong>h</strong>: ');
%       disp(h);
%       fprintf(1,'<strong>rWeek(iRow,:)</strong>: ');
%       disp(rWeek(iRow,:));
      continue;
   end
   
end

end