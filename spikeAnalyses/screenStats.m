function s = screenStats(stats,ratName,postOpDay)
%% SCREENSTATS    Screen subset of table STATS (returned by GETCHANNELWISERATESTATS method of GROUP class object)
%
%  s = SCREENSTATS(stats);
%  s = SCREENSTATS(stats,ratName);
%  s = SCREENSTATS(stats,ratName,postOpDay);
%
% By: Max Murphy  v1.0  2019-06-21  Original version (r2017a)

%%
if ~istable(stats)
   error('stats (first input) must be a TABLE returned by GETCHANNELWISERATESTATS method of GROUP class object.');
end   

s = stats(stats.nTrial >= 5,:); % remove low # of trials
% s(s.medRate>0.5,:) = []; % outliers
s(any(isinf(stats.NV),2),:) = [];

if nargin > 1
   s = s(ismember(s.Rat,ratName),:);
end

if nargin > 2
   s = s(ismember(s.PostOpDay,postOpDay),:);
end

end