function [TPR,FPR,AUC,r,threshold_list] = computeROC(mdl,varargin)
%COMPUTEROC Compute true-positive rate, false-positive rate, and area-under-curve for ROC analysis
%
%  [TPR,FPR,r,AUC] = analyze.stat.computeROC(mdl,varargin);
%
% Inputs
%  mdl - GeneralizedLinearMixedModel object that was fit as a classifier
%  varargin - (Optional) 'Name',value pairs specifying Variable Names in
%                 mdl source data (mdl.Variable) and the values that are
%                 allowable for the corresponding variable.
%
% Output
%  TPR - True positive rate
%  FPR - False positive rate
%  r   - Data table used according to slicing done by varargin
%  AUC - Area under the ROC curve (found using trapz to do numerical
%           integration of TPR with respect to FPR).
%  threshold_list - Thresholds that correspond to each TPR and FPR.
%
% See also: analyze.stat, analyze.stat.plotROC, analyze.stat.batchROC,
%           analyze.trials.doPrediction

r = mdl.Variables;
r.Week = categorical(ceil(r.PostOpDay/7),1:4,{'Week-1','Week-2','Week-3','Week-4'});
r = analyze.slice(r,varargin{:});
% threshold_list = linspace(0,1,25);
p = predict(mdl,r);
if min(p)==max(p) % If the minimum value is same as maximum value, can't do a thresholding on it
   TPR = nan; FPR = nan; AUC = nan; threshold_list = nan;
   return;
end
threshold_list = linspace(min(p)-0.1,max(p)+0.1,25);
TPR = nan(size(threshold_list));
FPR = nan(size(threshold_list));

for iT = 1:numel(threshold_list)
   thresh = threshold_list(iT);
   [TPR(iT),FPR(iT)] = analyze.trials.doPrediction(mdl,r,thresh);
   
end

[FPR,iSort] = sort(FPR,'ascend');
TPR = TPR(iSort);
threshold_list = threshold_list(iSort);

AUC = trapz(FPR,TPR);

end