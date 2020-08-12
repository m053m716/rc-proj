function [n,duration] = countSpikes(x,ts,t1,t2)
%COUNTSPIKES Count spikes in binned vector x, given ts & interval (t1, t2]
%
%  n = analyze.trial.countSpikes(x,ts,t1,t2);
%  [n,duration] = analyze.trial.countSpikes(x,ts,t1,t2);
%
% Inputs
%  x  - Binned spike histogram vector: bins are counts of spikes
%  ts - Time vector of center times for each "sample" bin in `x`
%  t1 - Start of bins (non-inclusive) to sum counts
%  t2 - End of bins (inclusive) to sum counts
%
% Output
%  n  - Sum of total number of spikes occurring this trial on interval 
%           (t1, t2] (excludes t1, includes t2).
%  duration - Total duration (t2 - t1).
%
% See also: analyze.trials, unit_learning_stats.mlx, arrayfun

if size(x,2) ~= numel(ts)
   error('Number of elements in `ts` must match columns of `x`');
end

idx = (ts > t1) & (ts <= t2);
n = nansum(x(:,idx),2);
duration = t2 - t1;

end