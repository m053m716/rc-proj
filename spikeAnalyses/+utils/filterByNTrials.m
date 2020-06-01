function T = filterByNTrials(T,N,outcome,varargin)
%FILTERBYNTRIALS Get subset of T based on minimum `N` trials by `BlockID`
%
% T = utils.filterByNTrials(T);
% T = utils.filterByNTrials(T,N,outcome);
% T = utils.filterByNTrials(T,N,outcome,'SliceFilter1',SliceVal1,...);
%
% Inputs
%  T        -  Table, such as `T = getRateTable(gData);`
%  N        -  Minimum # trials (default: 10)
%  outcome  -  Trial outcomes to include 
%              (default: {'Successful','Unsuccessful'})
%
%  varargin - (Optional) Filter 'Name',value pairs for `analyze.slice`
%
% Output
%  T        -  Filtered table, screened by criteria defined by inputs.

if nargin < 3
   outcome = {'Successful','Unsuccessful'};
elseif ~iscell(outcome)
   outcome = {outcome};
end

if nargin < 2
   N = 10;
end

if nargin > 3
   T = analyze.slice(T,varargin{:});
end

[G,TID] = findgroups(T(:,{'Alignment','BlockID','ChannelID'}));
n = splitapply(@(o)sum(ismember(o,outcome)),T.Outcome,G);
[~,iLeft,iRight] = outerjoin(T,TID);
nTotal = n(iRight);
iRemove = nTotal < N;
iLeft(iRemove) = [];
T = T(sort(iLeft,'ascend'),:);
if numel(outcome) > 1
   processing_str = sprintf('Keep-Min-%g-All',N);
else
   processing_str = sprintf('Keep-Min-%g-%s',N,outcome{:});
end
T = utils.addProcessing(T,processing_str);
end