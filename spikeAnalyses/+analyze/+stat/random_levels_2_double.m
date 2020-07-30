function [Index,ChannelID,PostOpDay] = random_levels_2_double(glme,varargin)
%RANDOM_LEVELS_2_DOUBLE Helper to convert levels of random effects to numeric double to help match with original data
%
%  [Index,ChannelID,PostOpDay] = analyze.stat.random_levels_2_double(glme);
%  s = analyze.stat.random_levels_2_double(glme,'Variable',value,...);
%
% Inputs
%  glme      - GeneralizedLinearMixedEffects model object
%  varargin  - <'Variable',VariableValue> 'Name',value pairs
%
% Output
%  Index     - Corresponding rows of `stats` for other 2 output vectors
%  ChannelID - Vector of channel identifier numbers
%  PostOpDay - Vector of corresponding PostOpDay (from 1|ChannelID:Day grouping)
%
%  If 3 or more inputs given, then outputs are subset corresponding to
%  specified 'Variable',value filters using table `S`.
%
% See also: analyze.stat, analyze.stat.fit_spike_count_glme

[~,~,stats] = randomEffects(glme);
Index = find(stats.Group=="ChannelID:Day");
lev = cell2mat(cellfun(@(C)str2double(strsplit(C,' ')),...
               stats.Level(Index),...
               'UniformOutput',false));
ChannelID = lev(:,1);
PostOpDay = lev(:,2);

if nargin < 3
   return;
end

s = analyze.slice(glme.Variables(~glme.ObservationInfo.Excluded,:),varargin{:});
c = str2double(string(s.ChannelID));
p = s.PostOpDay;

Index = Index(ismember(ChannelID,c) & ismember(PostOpDay,p));
ChannelID = ChannelID(Index);
PostOpDay = PostOpDay(Index);

end