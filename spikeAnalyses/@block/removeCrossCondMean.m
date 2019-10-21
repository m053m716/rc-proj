function rate = removeCrossCondMean(obj,rate,align,includeStruct,area)
%% REMOVECROSSCONDMEAN  Remove cross-condition mean from a set of rates
%
%  rate = obj.REMOVECROSSCONDMEAN(rate,align,includeStruct);
%  rate = obj.REMOVECROSSCONDMEAN(rate,align,includeStruct,area);
%
% By: Max Murphy  v1.0  2019-10-18  Original version (R2017a)

%% Check input
if numel(obj) > 1
   error('This method is only applicable to scalar BLOCK objects.');
end

%% Parse arguments
if nargin < 3
   align = defaults.block('alignment');
end

if nargin < 4
   includeStruct = utils.makeIncludeStruct();
end

if nargin < 5
   area = 'Full';
end

%% Get correct cross-condition mean to apply
% xcmean : nTimesteps x nChannels
xcmean = getCrossCondMean(obj,align,includeStruct,area);
if isempty(xcmean)
   rate = [];
end
xcmean = reshape(xcmean,1,size(xcmean,1),size(xcmean,2));

rate = rate - xcmean;

end