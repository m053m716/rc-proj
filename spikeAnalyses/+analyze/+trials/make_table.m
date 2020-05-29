function Y = make_table(X,event,outcome)
%MAKE_TABLE Create table where each row represents a trial
%
%  Y = analyze.trials.make_table(X,event,outcome);
%
%  -- Inputs --
%  X : Table with rate data, such as returned by 
%        ```
%           gData = group.loadGroupData;
%           T = getRateTable(gData);
%           X = analyze.nullspace.get_subset(T);
%        ```
%  event : Name of alignment for trials to include.
%  outcome : char or cell array of outcomes to include.

if nargin < 3
   outcome = {'Successful','Unsuccessful'};
end

x = analyze.slice(X,'Alignment',event,'Outcome',outcome);
v = x.Properties.VariableNames; 

% Find groupings based on individual Trials
G = findgroups(x(:,'Trial_ID'));

% Get metadata variables using only first row from every trial
argsOut = cell(1,size(X,2));
[argsOut{:}] = splitapply(...
   @(varargin)utils.get_first_n_rows(1,varargin{:}),x,G);
Y = table(argsOut{:},'VariableNames',v);

% Get all rates
Y.Rate = splitapply(@(rates){rates},x.Rate,G);

% Remove channel-related metadata from main table variables
Y = utils.remove_cols(Y,...
   'ML','ICMS','Area',... % Remove qualitative location metadata
   'ProbeID','Probe','ChannelID','Channel',... % Remove channel/probe data
   'X','Xc','Y','Yc'... % Location-related data is probe-specific
   );

% Get separate table for ChannelInfo that will go into UserData property
argsOut = cell(1,size(X,2));
[argsOut{:}] = splitapply(...
   @(varargin)utils.get_first_n_rows(inf,varargin{:}),x,G);
ChannelInfo = table(argsOut{:},'VariableNames',v);
ChannelInfo = utils.remove_cols(ChannelInfo,...
   'RowID','Group','Trial_ID','Rat',...
   'Alignment','Reach','Grasp','Support','Complete','PelletPresent',...
   'Outcome','Rate'...
   );
[a,b,d] = cellfun(@(A,B,D)utils.get_first_n_rows(1,A,B,D),...
   ChannelInfo.AnimalID,ChannelInfo.BlockID,ChannelInfo.PostOpDay);
[~,iBlock] = unique(b);
ChannelInfo = ChannelInfo(iBlock,:);
ChannelInfo.AnimalID = a(iBlock);
ChannelInfo.BlockID = b(iBlock);
ChannelInfo.PostOpDay = d(iBlock);

ChannelInfo.Properties.UserData.Type = 'channelinfo';

Y.Properties.RowNames = Y.Trial_ID;
Y.Properties.DimensionNames{1} = 'Trial';
Y.Properties.UserData.t = x.Properties.UserData.t;
Y.Properties.UserData.IsTransformed = x.Properties.UserData.IsTransformed;
Y.Properties.UserData.Transform = x.Properties.UserData.Transform;
Y.Properties.UserData.ChannelInfo = ChannelInfo;
Y.Properties.UserData.Type = 'trials';

end