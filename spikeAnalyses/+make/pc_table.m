function P = pc_table(T,K,opts,t_start_stop)
%PC_TABLE  Makes table for export based on PCs from different margins
%
%  P = make.pc_table(T);
%  P = analyze.pc_table(T,K);
%  P = analyze.pc_table(T,K,opts);
%  P = analyze.pc_table(T,K,opts,t_start_stop);
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
%  P : Data table with different marginalization coefficients instead of
%        rate data, but otherwise similar to the rate table that is
%        exported to Tableau.

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

% Get different groupings
[fixed_grouping,marginalizations] = defaults.experiment(...
   'pca_iterate_on','pca_marg_vars');

[Gf,T_Fixed] = findgroups(tSub(:,fixed_grouping));
[Gm,T_Marg] = findgroups(tSub(:,marginalizations));
P = table.empty;
for iFixed = 1:max(Gf)
   fixed_idx = Gf == iFixed;
   fixed_val = T_Fixed.(fixed_grouping)(iFixed);
   m = Gm(fixed_idx);
   tm = tSub(fixed_idx,:);
   for iMarg = 1:max(m)
      S = analyze.slice(tm,fixed_grouping,fixed_val,...
      
   end
   
   
   pc = analyze.pc.get(tSub,K,opts,t_start_stop);
end

end