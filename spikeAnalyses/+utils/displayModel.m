function R = displayModel(mdl,alpha,type,tag)
%DISPLAYMODEL Display formatted model summary to Command Window
%
%  utils.displayModel(mdl);
%  utils.displayModel(mdl,alpha);
%  utils.displayModel(mdl,alpha,type);
%  R = utils.displayModel(mdl,alpha,type,tag);
%
% Inputs
%  mdl  - GeneralizedLinearMixedModel
%  alpha - Default is 0.05. Sets threshold for p-values on random coeffs to
%              show (always show all fixed effects)
%  type - Char array indicating "type" (cosmetic)
%  tag  - Char array that identifies something about model
%
% Output
%  R    - Formatted random effects coefficient information
%  Formatted string printed to Command Window
%
% See also: utils, analyze.behavior,
%           analyze.behavior.per_animal_area_mean_rates,
%           analyze.behavior.per_animal_area_mean_trends

if nargin < 2
   alpha = 0.05;
end

if nargin < 3
   if isfield(mdl,'tag')
      type = mdl.tag;
   elseif isfield(mdl,'type')
      type = mdl.type;
   else
      type = 'GLME';
   end
end

if nargin < 4
   if isstruct(mdl)
      if ~isfield(mdl,'id')
         fn = fieldnames(mdl);
         R = struct;
         for iF = 1:numel(fn)
            R.(fn{iF}) = utils.displayModel(mdl.(fn{iF}),alpha,type);
         end
         return;
      end
      if isnumeric(mdl.id)
         tag = sprintf('MODEL-%02d',mdl.id);
      else
         tag = sprintf('MODEL-%s',string(mdl.id));
      end
      mdl = mdl.mdl;
   else
      tag = 'Summary';
   end
else
   if isstruct(mdl)
      if ~isfield(mdl,'mdl')
         fn = fieldnames(mdl);
         R = struct;
         for iF = 1:numel(fn)
            R.(fn{iF}) = utils.displayModel(mdl.(fn{iF}),alpha,type);
         end
         return;
      else
         mdl = mdl.mdl;
      end
   end
end
[~,~,rStats] = randomEffects(mdl);
tmp = string(cellstr(rStats(:,1)));
rStats(~strcmpi(tmp,'AnimalID'),:) = [];

idx = rStats.pValue < alpha;
rStats = rStats(idx,[1:4,8]);

[~,iSort] = sort(rStats.pValue,'ascend');
rStats = rStats(iSort,:);
[coefVal,coefName,fStats] = fixedEffects(mdl);
[~,iSort] = sort(fStats.pValue,'ascend');
tmp = rStats(:,2);
Rat = string(cellstr(tmp));
Group = categorical(Rat,...
   ["RC-02","RC-04","RC-05","RC-08","RC-14","RC-18","RC-21","RC-26","RC-30","RC-43"],...
   ["Ischemia","Ischemia","Ischemia","Ischemia","Intact","Intact","Intact","Ischemia","Ischemia","Intact"]);

tmp = rStats(:,3);
Name = string(cellstr(tmp));
tmp = rStats(:,4);
Estimate = double(tmp);
tmp = rStats(:,5);
p = double(tmp);
fStats = fStats(iSort,[1,2,4,5,6]);

fprintf(1,'--------------------------------------------------------------------\n');
fprintf(1,'<strong>%s MODEL:</strong> %s (%s)\t\t<strong>N</strong> = %d\n',...
   upper(type),tag,mdl.ResponseName,mdl.NumObservations);
disp(mdl.Formula);
fprintf(1,'--------------------------------------------------------------------\n');
fprintf(1,'\t\t<strong>%s (%s link)</strong> Fit Method: %s\n',...
   mdl.Distribution,mdl.Link.Name,upper(mdl.FitMethod));
fprintf(1,'--------------------------------------------------------------------\n');
disp(fStats);
if strcmpi(mdl.Link.Name,'logit')
   fprintf(1,'\n<strong>Coefficient Log-odds</strong>:\n\n');
   coefName = coefName(iSort,:);
   LogOdds = exp(coefVal(iSort));
   pValue = double(fStats.pValue);
   le_tab = [coefName,table(LogOdds,pValue)];
   disp(le_tab);
end
disp(anova(mdl));
fprintf(1,'\n<strong>FIT (R^2):</strong> %s (%s)\n\n',tag,mdl.ResponseName);
disp(mdl.Rsquared);
fprintf(1,'\n\t<strong>%6s</strong>  |  <strong>%-6s</strong>\n','AIC','BIC');
fprintf(1,'\t%6.2f  |  %-6.2f\n',mdl.ModelCriterion.AIC,mdl.ModelCriterion.BIC);
R = table(Group,Rat,Name,Estimate,p);

if isempty(R)
   fprintf(1,'\n<strong>NO SIGNIFICANT RANDOM EFFECTS</strong> (alpha: %6.2f)\n\n',alpha);
else
   fprintf(1,'\n(<strong>N</strong> = %d) <strong>SIGNIFICANT RANDOM EFFECTS:</strong> %s (%s)\n\n',...
      size(R,1),tag,mdl.ResponseName);
   disp(R);
end
end