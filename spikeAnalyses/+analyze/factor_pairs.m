function [xc,i_new2orig,i_orig2new] = factor_pairs(h0,hnew)
%FACTOR_PAIRS  Gives factor cross correlations, as well as indexing
%
%  [xc,i_new2orig,i_orig2new] = analyze.factor_pairs(h0,hnew);
%
%  -- Inputs --
%  h0 : Original factors, where each column is a sample index
%  hnew : New factors (rows are factors for h0 and hnew)
%  
%     -- e.g. This would be NNMF_Coeffs for .nnm, or PC_Coeffs for .pc --
%
%  -- Output --
%  xc : Matrix of normalized cross correlations between factor pairs;
%     -> Rows correspond to rows of hnew; columns correspond to rows of h0
%        -- e.g. xc(2,3) corresponds to cross-correlation between hnew(2,:)
%                    and h0(3,:)
%
%  i_new2orig : Indexing such that hnew(i_new2orig,:) rearranges hnew to
%                 match h0 factor ordering
%
%  i_orig2new : Indexing such that h0(i_orig2new,:) rearranges h0 to match
%                 hnew factor ordering

nFactor = size(h0,1);
xc = zeros(nFactor,nFactor);
ss_orig = sum(h0.^2,2);
ss_new = sum(hnew.^2,2);
for iRow = 1:nFactor
   dp = dot(repmat(hnew(iRow,:),nFactor,1),h0,2)./(ss_orig.*ss_new(iRow));
   xc(iRow,:) = reshape(dp,1,nFactor);
end

[~,i_new2orig] = max(xc,[],1);
[~,i_orig2new] = max(xc,[],2);

end