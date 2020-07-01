function [G,modelspec] = get_glme_table(T,min_n_trials)
%GET_GLME_TABLE Return table for generalized linear mixed effect regression
%
%  G = analyze.stat.get_glme_table(T,min_n_trials);
%  [G,modelspec] = analyze.stat.get_glme_table(_);
%
% Inputs
%  T            - Main data table with rows of spike rates for each trial
%  min_n_trials - (Optional; default is 5) specify minimum # trials  
%
% Output
%  G            - Data table that is a subset of T
%  modelspec    - Char vector that is the model specification formula 
%                 -> Uses Wilkinson notation
%                 -> Also saved as one of the UserData fields of `G`
%
% See also: analyze.stat.fit_transfer_fcn, defaults.stat

if nargin < 1
   fprintf(1,'No input argument. Loading T (may take several minutes)...');
   T = getfield(load(defaults.files('rate_table_default_matfile'),'T'),'T');
   fprintf(1,',<strong>complete</strong>\n');
end

if nargin < 2
   min_n_trials = 5;
end

if nargin < 3
   modelspec = defaults.stat('modelspec_glme');
end

% Get subset of variables from main data table %
G = T(:,...
   {...
   'Group','AnimalID',...    % Animal-related identifiers (categorical predictors)
   'BlockID','Trial_ID',...  % Behaviorally-related identifiers (categorical predictors)
   'ProbeID','ChannelID',... % Channel-related identifiers (categorical predictors)
   'Alignment','ICMS','Area','Outcome',... % Categorical predictors
   'Duration','X','Y',... % Continuous predictors (random effects)
   'Rate'... % Continuous response
   }...
   );

% Update so that TrialID is categorical %
G.Trial_ID = categorical(G.Trial_ID);

% Reduce to subset of Blocks that have at least `min_n_trials` %
G = utils.filterByNTrials(G,min_n_trials,...
   'Alignment',{'Reach','Grasp'});

% Add `Time` variable to end of Variables list %
G.Time = repmat(T.Properties.UserData.t,size(G,1),1);
nVar = size(G,2);
% Move Time to second-to-last variable 
% G = movevars(G,'Time','Before','Rate'); % Only R2018a+
G = G(:,[1:(nVar-2),nVar,nVar-1]); 

% Modify the Variable Names for naming convention consistency %
G.Properties.VariableNames = ...
   {...
   'GroupID',     ...   % (main) Fixed Effect (Ischemia vs Intact)
   'AnimalID',    ...   % Random Effect of animal
   'BlockID',     ...   % Likely unused but could be a Random Effect
   'TrialID',     ...   % Likely unused
   'ProbeID',     ...   % Random Effect of a single probe
   'ChannelID',   ...   % Random Effect of a single channel
   'Alignment',   ...   % Fixed Effect (Reach, Grasp)
   'ICMS',        ...   % Fixed Effect (DF, PF, DF-PF, O, NR)
   'Area',        ...   % Fixed Effect (ipsilesion-RFA, contralesion-CFA)
   'Outcome',     ...   % Fixed Effect (successful, unsuccessful)
   'Duration',    ...   % Random Effect of trial duration
   'Position_ML', ...   % Random Effect of mediolateral location (mm)
   'Position_AP', ...   % Random Effect of anteroposterior location (mm)
   'Time'         ...   % Random Effect of Time (ms) relative to alignment
   'Rate',        ...   % (main) Response (norm/smooth spike rate on each trial)
   };

% Define the model specification formula and associate it with table %
G.Properties.UserData.modelspec = modelspec;
end