function xcmean = getCrossCondMean(obj,align,includeStruct,area)
%% GETCROSSCONDMEAN  Get cross-condition mean for a set of conditions
%
%  xcmean = obj.GETCROSSCONDMEAN(align,includeStruct);
%  xcmean = obj.GETCROSSCONDMEAN(align,includeStruct,area);
%
%  xcmean : nTimesteps x nChannels array
%
% By: Max Murphy  v1.0  2019-10-18  Original version (R2017a)

%% Constants
FIELDS_TO_CHECK = {'Include','Exclude'};

%% Check input
if numel(obj) > 1
   error('This method is only applicable to scalar BLOCK objects.');
end

%% Parse arguments
if nargin < 5
   area = 'Full';
end

%% Get channel indices (if applicable)
if strcmpi(area,'RFA') || strcmpi(area,'CFA')
   ch_idx = contains({obj.ChannelInfo(obj.ChannelMask).area},area);
else
   ch_idx = 1:sum(obj.ChannelMask);
end

%% Get "key" for what each 'Include' 'Exclude or 'All' corresponds to
[strKey,flag_exists,flag_isempty] = parseStruct(obj.XCMean,'XCMean.key');
if (~flag_exists) || (flag_isempty)
   xcmean = [];
   fprintf(1,'No cross-condition key intialized for %s.\n',obj.Name);
   return;
end
key = strsplit(strKey,{'(','.',')'});
key([1,2,end]) = []; % discard empty cells and "align" cell

%% Parse expression from includeStruct
str = ['XCMean.' align];
for ii = 1:numel(key)
   flag = false;
   for ij = 1:numel(FIELDS_TO_CHECK)
      if isempty(includeStruct.(FIELDS_TO_CHECK{ij}))
         continue;
      end
      if any(contains(lower(includeStruct.(FIELDS_TO_CHECK{ij})),key{ii}))
         flag = true;
         str = [str '.' FIELDS_TO_CHECK{ij}]; %#ok<*AGROW>
      end
   end
   if ~flag
      str = [str '.All'];
   end
end

%% Return the cross-condition mean
[xcmean,flag_exists,flag_isempty] = parseStruct(obj.XCMean,str);
if (~flag_exists) || (flag_isempty)
   xcmean = [];
   fprintf(1,'No cross-condition mean set for %s.%s\n',obj.Name,str);
   return;
else
   xcmean = xcmean(:,ch_idx);
end

end