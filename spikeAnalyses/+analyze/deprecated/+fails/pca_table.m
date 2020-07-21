function [P,C] = pca_table(U,K,t_start_stop)
%PCA_TABLE  Makes table for export based on PCA factor loadings
%
%  P = analyze.fails.pca_table(U,K);
%  P = analyze.fails.pca_table(U,K,t_start_stop);
%  [P,C] = ...
%
%  -- Inputs --
%  U : Data table of rates (as uploaded to Tableau)
%     --> Obtained from `U = analyze.fails.get_subset(T);`
%
%  K : Number of components
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
%
%  C : Coefficients table (data about each set of factors, by Block/Align)

if nargin < 2
   K = defaults.fails_analyses('n_factors');
end

if nargin < 3
   t_start_stop = defaults.experiment('t_start_stop_reduced');
end

t = U.Properties.UserData.t;
t_mask = (t >= t_start_stop(1)) & (t <= t_start_stop(2));

[G,TID] = findgroups(U(:,{'Group','Alignment','Area'}));
P = table.empty;
C = table.empty;
warning('off','stats:pca:ColRankDefX');
for iGroup = 1:max(G)
   [S,rate] = analyze.sliceRate(U,...
         'Alignment',TID.Alignment(iGroup),...
         'Group',TID.Group(iGroup),...
         'Area',TID.Area(iGroup));
   X = rate(:,t_mask) - mean(rate(:,t_mask),2);
   [coeffs,score,~,~,explained,mu] = pca(...
      X,'Algorithm','svd','NumComponents',K,'Economy',true);
   
   PC_Key = tag__.makeKey(1,'unique','PC_');
   S.PC_Key = repmat(PC_Key,size(S,1),1);
   S.PC_Score = score;
   
   PC_Coeffs = {coeffs};
   PC_Explained = {explained};
   PC_Means = {mu};
   P = [P; S]; %#ok<AGROW>
   C = [C; ...
      TID(iGroup,:), ...
      table(PC_Key,PC_Coeffs,PC_Explained,PC_Means)]; %#ok<AGROW>
end
warning('on','stats:pca:ColRankDefX');
P = movevars(P,'RowID','Before','Alignment');
P = movevars(P,'Trial_ID','Before','Alignment');

C.Properties.UserData.t = t;
C.Properties.UserData.t_mask = t_mask;
C.Properties.UserData.color_order = defaults.pca_analyses('color_order');

% Make sure that they are all rotated so components are matched.
Gc = findgroups(C(:,'Alignment'));
for iGroup = 1:max(Gc)
   iC = find(Gc==iGroup);   
   target = C.PC_Coeffs{3};
   for k = 1:sum(Gc==iGroup)
      iP = P.Alignment==C.Alignment(iC(k)) & ...
           P.Group==C.Group(iC(k)) & ...
           P.Area==C.Area(iC(k));
      A = C.PC_Coeffs{iC(k)};
      scores = P.PC_Score(iP,:);
      [B,transform] = rotatefactors(A,'Method',...
         'procrustes','Target',target);
      C.PC_Coeffs{iC(k)} = B;
      P.PC_Score(iP,:) = scores/transform;
   end   
end
end