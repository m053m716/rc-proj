function [X,t] = concatChildRate_trials(obj,align,includeStruct,area,tIdx)
%% CONCATCHILDRATE_TRIALS  Concatenate child normalized trial rates
%
%  X = obj.CONCATCHILDRATE_TRIALS;
%  X = obj.CONCATCHILDRATE_TRIALS(align);
%  X = obj.CONCATCHILDRATE_TRIALS(align,includeStruct);
%  X = obj.CONCATCHILDRATE_TRIALS(align,includeStruct,area);
%  X = obj.CONCATCHILDRATE_TRIALS(align,includeStruct,area,tIdx);
%  [X,t] = ...
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
%     objects, along "trials" axis (so all the days get lumped together)

%% PARSE INPUT
if nargin < 2
   align = defaults.block('alignment');
end

if nargin < 3
   includeStruct = utils.makeIncludeStruct([],[]);
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
   t = [];
   for ii = 1:numel(obj)
      [X{ii},ttmp] = concatChildRate_trials(obj(ii),align,includeStruct,area,tIdx);
      if ~isempty(ttmp)
         t = ttmp;
      end
   end
   return;
end
%% INITIALIZE OUTPUT
t = [];
X = [];

%% FOR EACH CHILD, GET THE RIGHT TRIALS
x = cell(size(obj.Children));
nTrialTotal = 0;
t_is_set_flag = false;
t = [];
for ii = 1:numel(obj.Children)
   [xtmp,~,flag_isempty,ttmp] = getRate(obj.Children(ii),align,'All',area,includeStruct);

   if isnan(tIdx(1))
      if ~t_is_set_flag
         if ~flag_isempty
            t = ttmp;
            t_is_set_flag = true;
         end
      end
      x{ii} = xtmp;
   else
      if ~t_is_set_flag
         if ~flag_isempty
            t = ttmp(tIdx);
            t_is_set_flag = true;
         end
      end
      x{ii} = xtmp(:,tIdx,:);
   end

end
removeBlock = cellfun(@(c)isempty(c),x,'UniformOutput',true);
x(removeBlock) = [];
nTrialTotal = sum(cellfun(@(c)size(c,1),x,'UniformOutput',true));
nT = numel(t);

if nTrialTotal == 0
   return;
end

%% FORMAT OUTPUT MATRIX FROM INPUT TENSORS
X = zeros(nTrialTotal,nT,sum(obj.ChannelMask));

iTrial = 1;
for ii = 1:numel(x)
   vec = iTrial:(iTrial + size(x{ii},1) - 1);
   X(vec,:,:) = x{ii};
   iTrial = iTrial + size(x{ii},1);
end


end