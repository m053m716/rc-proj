function pc = get(T,K,opts)
%GET  Gets PCs by groupings
%
%  pc = analyze.pc.get(T);
%  pc = analyze.pc.get(T);
%  pc = analyze.pc.get(T,K);
%  pc = analyze.pc.get(T,K,opts);
%
%  -- Inputs --
%  T : Data table of rates (as uploaded to Tableau)
%     --> Obtained from `T = getRateTable(gData);`
%
%  K : Number of probabilistic principal components to use
%
%  opts : Options
%
%  -- Output --
%  pc : struct containing PCA results, info about parameters, groupings...


if nargin < 3
   opts = defaults.experiment('pca_opts');
end

if nargin < 2
   K = defaults.experiment('pca_n');
end


tSub = T(T.PelletPresent=={'Present'},:);

% Get groupings
[G,TID] = findgroups(tSub(:,T.Properties.UserData.GroupVarIndices));

% Create output struct
pc = struct(...
   'info',struct('state','dev','run',datetime),...
   'coeff',[],...
   'score',[],...
   'explained',[],...
   'mu',[],...
   'rate',[],...
   't',T.Properties.UserData.t,...
   'groups',struct('index',G,'table',TID),...
   'pars',struct('opts',opts,'K',K));

% Apply PCA by grouping
[pc.coeff,pc.score,pc.explained,pc.mu] = ...
   splitapply(@(X)analyze.pc.apply(X,K,opts),tSub.Rate,G);

% Aggregate rates in same way as PCA
pc.rate = splitapply(@(X){X},tSub.Rate,G);

end