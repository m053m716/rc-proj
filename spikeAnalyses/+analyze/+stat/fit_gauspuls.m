function f = fit_gauspuls(r,t,p)
%FIT_GAUSPULS Function that goes to the fmincon procedure for gauspuls fit
%
%  f = analyze.stat.fit_gauspuls(r,t,p);
%
% Inputs
%  r - Rate for individual trial
%  t - Times of observations
%  p - 3-element vector: ['tau','sigma','omega']
%
% Output
%  f - Cost function value (trying to minimize this)
%     -> Estimated as sum-of-squares between the observed data in
%        `rate` and estimated data using `p` and `t`
%
% See also: analyze.stat.fit_transfer_fcn, analyze.stat.get_fitted_table,
%           gauspuls

% Reconstruct using median offset and maximum deviation for scaling
r_hat = analyze.stat.reconstruct_gauspuls(r,t,p,false);
f = sum((r - r_hat).^2); % Time-samples are matched (to use `tau`)

% function [f,g] = fit_gauspuls(r,t,p,G)
%FIT_GAUSPULS Function that goes to the fmincon procedure for gauspuls fit
%
%  [f,g] = analyze.stat.fit_gauspuls(r,t,p,G);
%
% Inputs
%  r - Rate for individual trial
%  t - Times of observations
%  p - 3-element vector: ['tau','sigma','omega']
%  G - Struct with originally-recovered Gradient matrix
%        for computing `g`
%
% Output
%  f - Cost function value (trying to minimize this)
%     -> Estimated as sum-of-squares between the observed data in
%        `rate` and estimated data using `p` and `t`
%  g - Gradient evaluated for array p
%
% See also: analyze.stat.fit_transfer_fcn, analyze.stat.get_fitted_table,
%           gauspuls
% 
% % Reconstruct using median offset and maximum deviation for scaling
% r_hat = analyze.stat.reconstruct_gauspuls(r,t,p,false);
% f = sum((r - r_hat).^2); % Time-samples are matched (to use `tau`)
% 
% if nargin < 4
%    g = [];
%    return;
% end
% 
% [~,tauIdxG] = min(abs(p(1) - G.tau));
% dTauG = p(1) - G.tau(tauIdxG);
% [~,sigIdxG] = min(abs(p(2) - G.sigma));
% dSigG = p(2) - G.sigma(sigIdxG);
% [~,omgIdxG] = min(abs(p(3) - G.omega));
% dOmgG = p(3) - G.omega(omgIdxG);
% g = [(f - G.cost(tauIdxG)) / max(dTauG,1e-2); ...
%    (f - G.cost(sigIdxG)) / max(dSigG,1e-2); ...
%    (f - G.cost(omgIdxG)) / max(dOmgG,1e-2)];
end