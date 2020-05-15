function [S,C] = stack(S,K,opts,colMask,grouping)
%STACK Output table to "stack" for `splitapply` workflow
%
%  [S,C] = analyze.pc.stack(S);
%  [S,C] = analyze.pc.stack(S,K,opts,colMask);
%  [S,C] = analyze.pc.stack(S,K,opts,colMask,grouping);
%
%  -- Inputs --
%  S     : "Sliced" table, based on filtered rate table:
%                 ```
%                    T = getRateTable(gData); 
%                    S = analyze.pc.slice(T,'Filter1','val',...);
%                 ```
%        
%  K     : Number of principal components to return
%  opts  : `statset` struct (e.g. `opts = statset('Display','off');`)
%  colMask : Logical indexing vector of size [1, size(S.Rate,2)].
%  grouping
%
%  -- Output --
%  S : "Sliced" table updated with individual trial values. 
%        -> Contains additional "Key" variable for matching to coefficients
%  C : Table with actual PCA coefficients, means, and % explained

if nargin < 2
   K = defaults.experiment('pca_n');
end

if nargin < 3
   opts = defaults.experiment('pca_opts');
end

if nargin < 4
   colMask = true(1,size(S.Rate,2));
end

if nargin < 5
   grouping = '';
end

utils.addHelperRepos();


Y = S.Rate - median(S.Rate(:,colMask),2);
warning('off','stats:pca:ColRankDefX');
[PCA_Coeffs,score,~,~,PCA_Explained,PCA_Means] = pca(...
   Y(:,colMask),...
   'Algorithm','svd',...
   'NumComponents',K,...
   'Economy',true,...
   'Options',opts);
warning('on','stats:pca:ColRankDefX');

if isempty(grouping)
   Key = tag__.makeKey(1,'unique','PC_');
else
   grouping = strrep(grouping,' ','_');
   grouping = strrep(grouping,'-','_');
   if ~strcmp(grouping(1),'_')
      grouping = ['_' grouping];
   end
   Key = tag__.makeKey(1,'unique',['PC' grouping '_']);
end
PCA_Coeffs = {PCA_Coeffs};
PCA_Explained = {PCA_Explained(1:K)};
PCA_Means = {PCA_Means(1:K)};
C = table(PCA_Coeffs,PCA_Explained,PCA_Means);
C.Properties.UserData.t = S.Properties.UserData.t(1,colMask);
nRow = size(S,1);

if isempty(grouping)
   C.Key = Key;
   S.Key = repmat(Key,nRow,1);
   S.PCA_Scores = score;
else
   S.(['Key' grouping]) = repmat(Key,nRow,1);
   C.(['Key' grouping]) = Key;
   S.(['PCA_Scores' grouping]) = score;
end
C = C(:,[end, 1:(end-1)]);

end