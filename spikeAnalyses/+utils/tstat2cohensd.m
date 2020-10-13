function d = tstat2cohensd(t,n_t,n_c)
%TSTAT2COHENSD Convert t-test statistic to Cohen's d value
%
%  d = utils.tstat2cohensd(t,n); -> "tStat" value & total number of observations
%  d = utils.tstat2cohensd(t,n_t,n_c); -> Number "treatment" and "control" group observations, respectively
%
% See also: Contents

if nargin < 3
   n = n_t;
   d = 2.*t ./ sqrt(n - 2);
else
   d = t .* sqrt(((n_t + n_c)./(n_t.*n_c)).*((n_t + n_c)./(n_t + n_c - 2)));
end

end