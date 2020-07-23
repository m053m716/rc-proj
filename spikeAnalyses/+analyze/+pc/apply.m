function [coeff,score,explained,mu] = apply(Y,K,opts,colMask)
%APPLY  Applies PCA using `splitapply` built-in syntax
%
%  [coeff,score,explained,mu] = analyze.pc.apply(Y);
%  [coeff,score,explained,mu] = analyze.pc.apply(Y,K,opts,colMask);
%
%  -- Inputs --
%  Y     : Matrix where rows are observations and columns are variables
%  K     : Number of principal components to return
%  opts  : `statset` struct (e.g. `opts = statset('Display','off');`)
%  colMask : Logical indexing vector of size [1, size(Y,2)].
%
%  -- Output --
%  [coeff,score,explained,mu] : See `pca`
%     -> Returned as array of cells, so that this can be run using the
%        following example syntax
%
%        ## Example ##
%        ```(matlab)
%           opts = statset('Display','off'); % options
%           K = 3; % # of components
%           [coeff,score,explained,mu] = ...
%              splitapply(@(Y)applyPCA(Y,K,opts),data,groupings);
%        ```

if nargin < 2
   K = defaults.experiment('pca_n');
end

if nargin < 3
   opts = defaults.experiment('pca_opts');
end

if nargin < 4
   colMask = true(1,size(Y,2));
end

warning('off','stats:pca:ColRankDefX');
[coeff,score,~,~,explained,mu] = pca(...
   Y(:,colMask),...
   'Algorithm','svd',...
   'NumComponents',K,...
   'Economy',true,...
   'Options',opts);
warning('on','stats:pca:ColRankDefX');
coeff = {coeff};
score = {score};
explained = {explained};
mu = {mu};

end