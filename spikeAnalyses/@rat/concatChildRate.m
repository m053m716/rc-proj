function X = concatChildRate(obj,align,includeStruct,area,tIdx)
%% CONCATCHILDRATE  Concatenate child normalized trial rates
%
%  X = obj.CONCATCHILDRATE;
%  X = obj.CONCATCHILDRATE(align);
%  X = obj.CONCATCHILDRATE(align,includeStruct);
%  X = obj.CONCATCHILDRATE(align,includeStruct,area);
%  X = obj.CONCATCHILDRATE(align,includeStruct,area,tIdx);
%
%  --------
%   INPUTS
%  --------
%     obj      :     RAT class object.
%
%     align    :     Char vector: 'Grasp' 'Reach' 'Support' or 'Complete'
%                       By default, uses 'Grasp'
%
%     includeStruct :  To refine what kind of alignment trials are
%                       gathered, optionally include this struct. Has two
%                       fields: 'Include' and 'Exclude' that each take cell
%                       arrays of char vectors indicating elements of
%                       BEHAVIORDATA (table) that are used to include or
%                       exclude trials.
%                          (e.g. includeStruct.Include = {'PelletPresent',
%                          'Outcome'} would only include successful 
%                          (Outcome == 1) and trials with pellet on
%                          the platform (PelletPresent == 1).
%                          includeStruct.Exclude = {'Outcome'} would only
%                          include unsuccessful trials.)
%
%     area     :     Char vector: 'Full' (default) 'CFA' or 'RFA'
%
%
%     tIdx     :     Indexing vector for times to include (default: include
%                       all times)
%
%     Concatenate rates for a given condition across all children BLOCK
%     objects, along time-axis (concatenating trials together), through
%     days.

%% PARSE INPUT
if nargin < 2
   align = defaults.block('alignment');
end

if nargin < 3
   includeStruct = struct('Include',[],'Exclude',[]);
end

if nargin < 4
   area = 'Full';
end

if nargin < 5
   tIdx = nan;
end

%% HANDLE OBJECT ARRAY INPUT
if numel(obj) > 1
   X = cell(numel(obj),1);
   for ii = 1:numel(obj)
      X{ii} = concatChildRate(obj(ii),align,includeStruct);
   end
   return;
end

%% FOR EACH CHILD, GET THE RIGHT TRIALS
x = cell(size(obj.Children));
nTrialTotal = 0;
for ii = 1:numel(obj.Children)
   [xtmp,~,~,ttmp] = getRate(obj.Children(ii),align,'All',area,includeStruct);
   if isnan(tIdx(1))
      t = ttmp;
      x{ii} = xtmp;
   else
      t = ttmp(tIdx);
      x{ii} = xtmp(:,tIdx,:);
   end
end
removeBlock = cellfun(@(c)isempty(c),x,'UniformOutput',true);
x(removeBlock) = [];
nTrialTotal = sum(cellfun(@(c)size(c,1),x,'UniformOutput',true));
nT = numel(t);

%% FORMAT OUTPUT MATRIX FROM INPUT TENSORS
X = zeros(nTrialTotal*numel(t),sum(obj.ChannelMask));
vec = 1:nT;
for ii = 1:numel(x)
   for ik = 1:size(x{ii},1)
      X(vec,:) = squeeze(x{ii}(ik,:,:));
      vec = vec + nT;
   end
end


end