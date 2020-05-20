function [S,C] = stack(S,colMask,varname,keyname)
%STACK Output table to "stack" for `splitapply` workflow
%
%  [S,C] = analyze.pc.stack(S);
%  [S,C] = analyze.pc.stack(S,colMask);
%  [S,C] = analyze.pc.stack(S,colMask,varname,keyname);
%
%  -- Inputs --
%  S     : "Sliced" table, based on filtered rate table:
%                 ```
%                    T = getRateTable(gData); 
%                    S = analyze.pc.slice(T,'Filter1','val',...);
%                 ```
%        
%  opts  : `statset` struct (e.g. `opts = statset('Display','off');`)
%  colMask : Logical indexing vector of size [1, size(S.Rate,2)].
%  varname : (Optional) Name of new variable
%  keyname : (Optional) Name of new key
%
%  -- Output --
%  S : "Sliced" table updated with individual trial values. 
%        -> Contains additional "Key" variable for matching to coefficients
%  C : Table with actual PCA coefficients, means, and % explained

if nargin < 2
   colMask = true(1,size(S.Rate,2));
end

if nargin < 3
   varname = 'PC_Scores';
end

if nargin < 4
   keyname = 'Key';
end

utils.addHelperRepos();
Y = S.Rate - median(S.Rate(:,colMask),2);
warning('off','stats:pca:ColRankDefX');
[PCA_Coeffs,score,~,~,PCA_Explained,PCA_Means] = pca(...
   Y(:,colMask),...
   'Algorithm','svd',...
   'NumComponents',3,...
   'Economy',true);
warning('on','stats:pca:ColRankDefX');
Key = tag__.makeKey(1,'unique',[varname '_']);

PCA_Coeffs = {PCA_Coeffs};
PCA_Explained = {PCA_Explained(1:3)};
PCA_Means = {PCA_Means(1:3)};
C = table(PCA_Coeffs,PCA_Explained,PCA_Means);
C.Properties.UserData.t = S.Properties.UserData.t(1,colMask);
nRow = size(S,1);

S.(keyname) = repmat(Key,nRow,1);
C.(keyname) = Key;
S.(varname) = score;
C = C(:,[end, 1:(end-1)]);

end