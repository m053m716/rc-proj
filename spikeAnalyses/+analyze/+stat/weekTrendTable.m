function T = weekTrendTable(mdl)
%WEEKTRENDTABLE Return summary trend table by week 
%
%  T = analyze.stat.weekTrendTable(mdl);
%
% Inputs
%  mdl   - GeneralizedLinearMixedModel fit to rWeek )
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

if ismember('Weekc',mdl.PredictorNames)
   wkType = 'Weekc';
else
   wkType = 'Week';
end

rWeek = mdl.Variables;
[G,T] = findgroups(rWeek(:,{'GroupID','Area',wkType}));

cn = mdl.CoefficientNames;
iTerm = contains(cn,'GroupID') & contains(cn,wkType) & contains(cn,'Area');

n = size(T,1);
T.p = nan(n,1);
T.df_num = nan(n,1);
T.df_den = nan(n,1);
T.F = nan(n,1);
T.Performance = splitapply(@nanmean,rWeek.Performance,G);
T.(mdl.ResponseName) = splitapply(@(x,nC,nT)nansum(x.*nC.*nT./(nansum(nC.*nT))),rWeek.(mdl.ResponseName),rWeek.n_Channels,rWeek.n_Trials,G);
sdvar = strrep(mdl.ResponseName,'_mean','_std');
T.sd = splitapply(@nanmean,rWeek.(sdvar),G); % Crude way but it's not used for anything else here
T.N = splitapply(@(x)sum(~isnan(x)),rWeek.(mdl.ResponseName),G); % Number of animal/area/week combos with non-NaN values
T.Duration = splitapply(@nanmean,rWeek.Duration,G);
T.Reach_Epoch_Duration = splitapply(@nanmean,rWeek.Reach_Epoch_Duration,G);
T.Retract_Epoch_Duration = splitapply(@nanmean,rWeek.Retract_Epoch_Duration,G);
T.Weights = splitapply(@nansum,mdl.ObservationInfo.Weights,G);
T.N_Trials = splitapply(@nansum,rWeek.n_Trials,G);
T.N_Channels = splitapply(@nansum,rWeek.n_Channels,G);
T.N_Recordings = splitapply(@nansum,rWeek.n_Blocks,G);

D = designMatrix(mdl);
D = mat2cell(D,ones(1,size(D,1)),size(D,2));
d = cell2mat(splitapply(@(x)x(1),D,G));
d(:,~iTerm) = 0;

for iRow = 1:n
   try
      [T.p(iRow),T.F(iRow),T.df_num(iRow),T.df_den(iRow)] = ...
         coefTest(mdl,d(iRow,:),0);
   catch
      continue; % For example if there are too few animals in a group to properly estimate coeffs
   end
end

T.(wkType) = double(T.(wkType));
T.Properties.VariableNames{wkType} = 'Week';
T.Properties.UserData = struct('Response',mdl.ResponseName,'SD',sdvar);

end