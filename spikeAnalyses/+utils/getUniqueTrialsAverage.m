function [x_mu_bar,x_sd_bar,n] = getUniqueTrialsAverage(x,id)
%GETUNIQUETRIALSAVERAGE Return average from unique trials only
%
%  [x_mu_bar,x_sd_bar,n] = utils.getUniqueTrialsAverage(x,id);
%
%  For example, if you have all the rows as channel-related data, then some
%  exclusions are applied that remove a subset of the channels from a given
%  trial such that now there is an imbalance in the quantity of interest;
%  you sould only take average from unique trial-related values in this
%  case.
%
% Inputs
%  x  - Variable aggregated for example using splitapply workflow
%  id - Trial identifiers (categorical or string)
%
% Output
%  x_mu_bar - Average of x over unique trials
%  x_sd_bar - Standard deviation of x over unique trials
%  n        - Number of unique trials used
%
% See also: utils, analyze.behavior,
%           analyze.behavior.per_animal_area_mean_rates

[~,iUnique] = unique(id);
x = x(iUnique);
x_mu_bar = nanmean(x);
x_sd_bar = nanstd(x);
n = numel(x);
end