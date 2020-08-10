function [Index,K,varargout] = random_levels_2_double(glme,varargin)
%RANDOM_LEVELS_2_DOUBLE Helper to convert levels of random effects to numeric double to help match with original data
%
%  [Index,K,ChannelID,PostOpDay] = analyze.stat.random_levels_2_double(glme);
%  s = analyze.stat.random_levels_2_double(glme,'Variable',value,...);
%
% Inputs
%  glme      - GeneralizedLinearMixedEffects model object
%  varargin  - <'Variable',VariableValue> 'Name',value pairs
%
% Output
%  Index     - Corresponding rows of `stats` for other 2 output vectors
%  K         - Design matrix for random effect hypothesis tests, according
%                 to recovered indices in `Index` output
%  varargout - Corresponding identifiers. Defaults:
%     ChannelID - Vector of channel identifier numbers
%     PostOpDay - Vector of corresponding PostOpDay (from 1|ChannelID:Day grouping)
%
%  varargout can be changed by setting the 'GroupVars' and 
%  'GroupParseFunction' <'Name',value> parameters.
%
%  If 3 or more inputs given, then outputs are subset corresponding to
%  specified 'Variable',value filters using table `S`.
%
% See also: analyze.stat, analyze.stat.fit_spike_count_glme

pars = struct;
pars.DesignWeight = 1;
pars.GroupParseFunction = {@(G)str2double(string(G)), @(G)G};
pars.GroupVars = {'ChannelID','PostOpDay'};
pars.ParseFunction = @(C)str2double(strsplit(C,' '));
pars.RandomGrouping = "ChannelID:Day";
fn = fieldnames(pars);
if numel(varargin) > 0
   if isstruct(varargin{1})
      pars = varargin{1};
      varargin(1) = [];
   end
end

if numel(varargin) > 0
   iRemove = false(size(varargin));
   for iV = 1:2:numel(varargin)
      idx = strcmpi(fn,varargin{iV});
      if sum(idx)==1
         pars.(fn{idx}) = varargin{iV+1};
         iRemove([iV,iV+1]) = true;
      end
   end
   varargin(iRemove) = [];
end

[~,~,stats] = randomEffects(glme);
Index = find(stats.Group==pars.RandomGrouping);
lev = cell2mat(cellfun(pars.ParseFunction,stats.Level(Index),...
   'UniformOutput',false));
   
% Assign outputs depending on parameter configuration
varargout = cell(1,size(lev,2));
for iV = 1:numel(varargout)
   varargout{iV} = lev(:,iV);
end
if numel(varargin) < 2
   return;
end

S = glme.Variables(~glme.ObservationInfo.Excluded,:);
s = analyze.slice(S,varargin{:});

groupLevels = cell(1,numel(pars.GroupVars));
iKeep = true(size(Index));
for iG = 1:numel(pars.GroupVars)
   groupLevels{iG} = pars.GroupParseFunction{iG}(s.(pars.GroupVars{iG}));
   iKeep = iKeep & ismember(varargout{iG},groupLevels{iG});
end

% Reduce excluded output rows
Index = Index(iKeep);
for iV = 1:numel(varargout)
   varargout{iV} = varargout{iV}(Index);
end

K = zeros(numel(Index),size(stats,1));
for ii = 1:numel(Index)
   K(ii,Index(ii)) = pars.DesignWeight;
end

end