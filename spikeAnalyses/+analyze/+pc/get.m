function [pc,tSub] = get(T,K,opts,t_start_stop)
%GET  Gets PCs by groupings
%
%  pc = analyze.pc.get(T);
%  pc = analyze.pc.get(T,K);
%  pc = analyze.pc.get(T,K,opts);
%  [pc,tSub] = analyze.pc.get(T,K,opts,t_start_stop);
%
%  -- Inputs --
%  T : Data table of rates (as uploaded to Tableau)
%     --> Obtained from `T = getRateTable(gData);`
%
%  K : Number of probabilistic principal components to use
%
%  opts : Options for PCA (`statset`)
%
%  t_start_stop : [tStart, tStop] (ms) If not provided, use whole rate
%                                      vector from each "trial row." Give
%                                      this to set a filter on the starting
%                                      and stopping times relative to the
%                                      event (e.g. relative to t == 0).
%
%  -- Output --
%  pc : struct containing PCA results, info about parameters, groupings...
%
%  tSub : (Optional) sub-table from `T` after exclusions

if nargin < 4
   t_start_stop = defaults.experiment('start_stop_bin');
end

if nargin < 3
   opts = defaults.experiment('pca_opts');
end

if nargin < 2
   K = defaults.experiment('pca_n');
end

% Apply exclusion (if associated)
e = T.Properties.UserData.PCA_Exclude_Fcn;
tSub = feval(e,T);

% Get groupings
[G,TID] = findgroups(tSub(:,T.Properties.UserData.GroupVarIndices));

% Get restrictions on time vector (if any)
t = T.Properties.UserData.t;
t_idx = (t >= t_start_stop(1)) & (t <= t_start_stop(2));

% Create output struct
pc = struct(...
   'info',struct('state','dev','run',datetime,'exclusion',e),...
   'coeff',[],...
   'score',[],...
   'explained',[],...
   'mu',[],...
   'rate',[],...
   't',t,...
   't_idx',t_idx,...
   'groups',struct('index',G,'table',TID,'n',size(TID,1)),...
   'pars',struct('opts',opts,'K',K));

% Apply PCA by grouping
Y = tSub.Rate - median(tSub.Rate(:,t_idx),2);
[pc.coeff,pc.score,pc.explained,pc.mu] = ...
   splitapply(@(X)analyze.pc.apply(X,K,opts,t_idx),Y,G);

% Aggregate rates in same way as PCA
pc.rate = splitapply(@(X){X},tSub.Rate,G);

end