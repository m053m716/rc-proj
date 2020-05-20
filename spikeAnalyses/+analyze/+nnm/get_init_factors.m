function h0 = get_init_factors(T,K,slice_pairs)
%GET_INIT_FACTORS  Get factor estimates for K factors
%
%  h0 = analyze.nnm.get_init_factors(T);
%     -> Default K = defaults.nnmf_factors('n_factors');
%     -> Default slice_pairs = defaults.nnmf_factors('slice_pairs');
%  h0 = analyze.nnm.get_init_factors(T,K,slice_pairs);
%
%  -- Inputs --
%  T  :  Table returned by `T = getRateTable(gData);`
%  K  :  (Optional) Number of factors (default: 5)
%  slice_pairs : (Optional) 'Name',value slice "Filter" cell array
%
%  -- Output --
%  h0 :  Table of initial factor coefficients for each set of time-series 
%           "factor" coefficients

% This should always be based on parameter in `defaults.experiment`
t_start_stop = defaults.experiment('t_start_stop_reduced');
t = T.Properties.UserData.t;
t_mask = (t >= t_start_stop(1)) & (t <= t_start_stop(2));
if nargin < 2
   [K,slice_pairs] = defaults.nnmf_analyses('n_factors','slice_pairs_h0');
elseif nargin < 3
   slice_pairs = defaults.nnmf_analyses('slice_pairs_h0');
end
% % These parameters are "static" (no input arg corresponds) % %
[opts,reps,alg] = defaults.nnmf_analyses('opts','reps','alg');


S = analyze.slice(T,slice_pairs{:});
NNMF_Offsets = min(S.Rate(:,t_mask),[],2);
Y = S.Rate - NNMF_Offsets;

[G,h0] = findgroups(S(:,{'Alignment'}));
nGroupings = max(G);
W = cell(nGroupings,1);
H = cell(nGroupings,1);
D = nan(nGroupings,1);
for iGroup = 1:nGroupings
   group_mask = G == iGroup;
   
   D_best = inf;
   for iRep = 1:reps
      [W_cur,H_cur,D_cur] = nnmf(Y(group_mask,t_mask),K,...
         'algorithm',alg,...
         'options',opts);
      if D_cur < D_best
         W{iGroup} = W_cur;
         H{iGroup} = H_cur;
         D(iGroup) = D_cur;
      end
   end
end
h0.W = W;
h0.H = H;
h0.D = D;
h0.Properties.Description = 'Table of initialization "guesses" for NNMF';
h0.Properties.UserData = struct;
h0.Properties.UserData.t = t;
h0.Properties.UserData.t_mask = t_mask;
h0.Properties.UserData.K = K;
h0.Properties.UserData.slice_pairs = slice_pairs;
h0.Properties.UserData.opts = opts;
h0.Properties.UserData.reps = reps;
h0.Properties.UserData.alg = alg;
end