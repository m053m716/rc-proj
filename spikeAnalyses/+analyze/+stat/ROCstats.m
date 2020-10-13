function [TPR,FPR,thresh] = ROCstats(obs,pred,thresh)
%ROCSTATS Evaluate TPR and FPR for categorical observations using continuous predictions discreetized by some threshold
%
%  [TPR,FPR,thresh] = analyze.stat.ROCstats(obs,pred);
%  [TPR,FPR,thresh] = analyze.stat.ROCstats(obs,pred,thresh);
%
% Inputs
%  obs    - Discrete labels (boolean zero or one) for each data point (row)
%  pred   - Predicted continuous output in regression of categorical endpoints
%  thresh - Threshold value: `pred` values greater than this are discretized as one and less than this are discretized as zero
%
% Output
%  TPR    - True positive rate:  [true positive] / ([true positive] + [false negative])
%  FPR    - False positive rate: [false positive] / ([false positive] + [true negative])
%  thresh - Same as input (convenient output if not specified as input); 
%              -> TPR and FPR are vectors of the same size as `thresh`
%
% See also: Contents, analyze, unit_learning_stats

if nargin < 2
   thresh = linspace(0,1,20);
end

if numel(thresh) > 1
   TPR = nan(size(thresh));
   FPR = nan(size(thresh));
   for ii = 1:numel(thresh)
      [TPR(ii),FPR(ii)] = analyze.stat.ROCstats(obs,pred,thresh(ii));
   end   
   [FPR,idx] = unique(FPR);
   TPR = TPR(idx);
   thresh = thresh(idx);   
   [FPR,iSort] = sort(FPR,'ascend');
   TPR = TPR(iSort);
   thresh = thresh(iSort);
   return;
end

pred_hat = pred > thresh;

tn = sum((~pred_hat) & (~obs));
tp = sum(pred_hat & obs);
fp = sum(pred_hat & (~obs));
fn = sum((~pred_hat) & obs);

TPR = tp/(tp+fn);
FPR = fp/(fp+tn);

end