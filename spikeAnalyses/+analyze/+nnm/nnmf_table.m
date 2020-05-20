function [N,C,exclusions] = nnmf_table(T,doExclusions,t_start_stop)
%NNMF_TABLE  Makes table for export based on NNMF factor loadings
%
%  N = analyze.nnm.nnmf_table(T);
%  N = analyze.nnm.nnmf_table(T,t_start_stop);
%  [N,C,exclusions] = ...
%
%  -- Inputs --
%  T : Data table of rates (as uploaded to Tableau)
%     --> Obtained from `T = getRateTable(gData);`
%
%  t_start_stop : [tStart, tStop] (ms) If not provided, use whole rate
%                                      vector from each "trial row." Give
%                                      this to set a filter on the starting
%                                      and stopping times relative to the
%                                      event (e.g. relative to t == 0).
%
%  -- Output --
%  N : Data table with different marginalization coefficients instead of
%        rate data, but otherwise similar to the rate table that is
%        exported to Tableau.
%
%  C : Coefficients table (data about each set of factors, by Block/Align)
%
%  exclusions : Exclusions data struct

if nargin < 2
   doExclusions = true;
end

if nargin < 3
   t_start_stop = defaults.experiment('t_start_stop_reduced');
end

EVENT = {'Reach','Grasp'};
uRat = unique(T.AnimalID);
t_idx = (T.Properties.UserData.t >= t_start_stop(1)) & ...
   (T.Properties.UserData.t <= t_start_stop(2));

N = table.empty;
C = table.empty;
% Get H0 as table
H0 = analyze.nnm.load_init_factors();
for iEvent = 1:numel(EVENT)
   h0 = H0.H{H0.Alignment==EVENT{iEvent}};
   for iRat = 1:numel(uRat)
      S = analyze.slice(T,...
         'AnimalID',uRat(iRat),...
         'Alignment',EVENT{iEvent},...
         'Outcome','Successful',...
         'PelletPresent','Present');
      [s,c] = analyze.nnm.stack(S,t_idx,'NNMF','NNMF_Key',h0);
      N = [N; s]; %#ok<AGROW>
      C = [C; c]; %#ok<AGROW>
   end  
end
C = analyze.nnm.append_meta(N,C);
exclusions = struct;
exclusions.slice_filter = { ...
      'AnimalID',uRat,...
      'Alignment',EVENT,...
      'Outcome','Successful',...
      'PelletPresent','Present'...
      };
if doExclusions
   analyze.nnm.view_all_corrs(C,true); % Default to save and delete figure obj
   [~,~,~,~,exclusions] = analyze.nnm.get_exclusions(C,exclusions);
   [N,C,exclusions] = analyze.nnm.apply_exclusions(N,C,exclusions);
end

end