function sz = c2sizeData(c,cmu,cstd)
%C2SIZEDATA Change some value to scaled sizes
%
%  sz = utils.c2sizeData(c,cmu,cstd);
%
% Inputs
%  c     - Values to scale
%  cmu   - Average of those values
%  cstd  - Standard deviation of those values
%
% Output
%  sz    - Size data for use with ratskull_plot
%
% See also: ratskull_plot, make.fig, make.fig.skullPlot

% Load config params from defaults.group
if nargin < 2
%    cmu = defaults.group('skull_cmu_size');
   cmu = nanmean(c,1);
end
if nargin < 3
%    cstd = defaults.group('skull_cstd_size');
   cstd = nanstd(c,[],1);
end
mu = defaults.group('skull_mu_size');
sd = defaults.group('skull_std_size');

minsize = defaults.group('skull_min_size');
maxsize = defaults.group('skull_max_size');

% Normalize based on old empirical params
z = (c - cmu)./cstd;

% Scale to new empirical params
sz = (z * sd) + mu;
sz = max(sz,ones(size(sz))*minsize);
sz = min(sz,ones(size(sz))*maxsize);


end