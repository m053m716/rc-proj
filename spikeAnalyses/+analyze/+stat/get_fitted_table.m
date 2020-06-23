function [G,modelspec] = get_fitted_table(T,min_n_trials,modelspec)
%GET_FITTED_TABLE Return table for statistics after consolidating Rate using fmincon and gauspuls using fit_transfer_fcn
%
%  G = analyze.stat.get_fitted_table(T,min_n_trials,modelspec);
%  [G,modelspec] = analyze.stat.get_fitted_table(_);
%
% Inputs
%  T            - Main data table with rows of spike rates for each trial
%  min_n_trials - (Optional; default is 5) specify minimum # trials  
%  modelspec    - (Optional; default is in
%                    defaults.stat('modelspec_fitted'))
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
   modelspec = defaults.stat('modelspec_fitted');
end

% Get subset of variables from main data table %
G = T(:,...
   {...
   'RowID', ...              % Indexing key
   'Group','AnimalID',...    % Animal-related identifiers (categorical predictors)
   'BlockID','Trial_ID',...  % Behaviorally-related identifiers (categorical predictors)
   'ProbeID','ChannelID',... % Channel-related identifiers (categorical predictors)
   'Alignment','ICMS','Area','Outcome',... % Categorical predictors
   'PostOpDay', ...       % Continuous predictor (main continuous effect)
   'Duration','X','Y',... % Continuous predictors (random effects)
   'Rate'... % Continuous response
   }...
   );

% Update so that TrialID is categorical %
G.Trial_ID = categorical(G.Trial_ID);

% Reduce to subset of Blocks that have at least `min_n_trials` %
G = utils.filterByNTrials(G,min_n_trials,'Alignment',{'Reach','Grasp'});
if size(G,1) < 1
   error(['RC:' mfilename ':BadFilter'],...
      ['\n\t->\t<strong>[GET_FITTED_TABLE]:</strong> ' ...
       'Filter returned zero rows. Check filter arguments.\n']);
end
G(~any(abs(G.Rate) > eps,2),:) = []; % Remove trials with no spikes
t = G.Properties.UserData.t * 1e-3; % Scale relative time to seconds
[tau,sigma,omega,a,b,w] = analyze.stat.fit_transfer_fcn(G.Rate,t);
G.Rate = [];
G.PeakOffset = tau;
G.EnvelopeBW = sigma .* omega; % Sigma is scalar factor based on omega
G.PeakFreq = omega;
G.LinearTrendCoeff = a;
G.LinearTrendOffset = b;
G.Error_SS = w;
G.Properties.UserData.t = t;

% Modify the Variable Names for naming convention consistency %
G.Properties.VariableNames = ...
   {...
   'RowID',       ...   % Indexing key
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
   'PostOpDay',   ...   % Random Effect of post-operative day
   'Duration',    ...   % Random Effect of trial duration
   'Position_ML', ...   % Random Effect of mediolateral location (mm)
   'Position_AP', ...   % Random Effect of anteroposterior location (mm)
   'PeakOffset',  ...   % Offset of peak (sec)
   'EnvelopeBW',  ...   % Bandwidth of "decay" Gaussian envelope (Hz)
   'PeakFreq',    ...   % Center frequency for oscillation fit (Hz)
   'LinearTrendCoeff',  ...   % Linear constant representing time-dependent bias
   'LinearTrendOffset', ...   % Linear constant representing offset at time t0
   'Error_SS'     ...   % Sum of square errors in reconstruction for gauspuls fit
   };
G.Properties.RowNames = G.RowID;

% Define the model specification formula and associate it with table %
G.Properties.UserData.modelspec = modelspec;
G.Properties.UserData.exclusions_removed = false;
end