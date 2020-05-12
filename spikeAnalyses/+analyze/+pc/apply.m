function [coeff,score,explained,mu] = apply(Y,K,opts)
%APPLY  Applies PCA using `splitapply` built-in syntax
%
%  [coeff,score,latent] = analyze.pc.apply(Y,opts);
%
%  -- Inputs --
%  Y : Matrix where rows are observations and columns are variables
%  opts : `statset` struct (e.g. `opts = statset('Display','off');`)
%
%  -- Output --
%  [coeff,score,latent] : See `pca`
%     -> Returned as array of cells, so that this can be run using the
%        following example syntax
%
%        ## Example ##
%        ```(matlab)
%           opts = statset('Display','off'); % options
%           K = 3; % # of components
%           [coeff,latent,explained] = ...
%              splitapply(@(Y)applyPCA(Y,K,opts),data,groupings);
%        ```

warning('off','stats:pca:ColRankDefX');
[coeff,score,~,~,explained,mu] = pca(Y,...
   'Algorithm','svd',...
   'NumComponents',K,...
   'Options',opts);
warning('on','stats:pca:ColRankDefX');
coeff = {coeff};
score = {score};
explained = {explained};
mu = {mu};

end