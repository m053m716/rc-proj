function c = makeTrialCondition(data,times,allTimes,PCs,jPCs_highD,mu,norms)

if nargin < 6
   mu = zeros(size(data,2));
end

if nargin < 7
   norms = ones(size(data,2));
end

if isempty(data)
   c = [];
   return;
end

if ~isnan(defaults.jPCA('fc'))
   b = defaults.jPCA('b');
   a = defaults.jPCA('a');
   x = filtfilt(b,a,data);
end

c = struct(...
   'proj',{(data./norms-mu) * jPCs_highD},...
   'times',{times},...
   'projAllTimes',{(data./norms-mu) * jPCs_highD},...
   'allTimes',{allTimes},...
   'tradPCAproj',{(data./norms-mu)*PCs},...
   'tradPCAprojAllTimes',{(data./norms-mu)*jPCs_highD});
