function [TPR,FPR] = doPrediction(mdl,r,threshold,varargin)
%DOPREDICTION Use preditive GLME to determine TPR/FPR for trial outcomes
%
%  [TPR,FPR] = analyze.trials.doPrediction(mdl);
%  [TPR,FPR] = analyze.trials.doPrediction(mdl,r);
%  [TPR,FPR] = analyze.trials.doPrediction(mdl,r,threshold);
%  [TPR,FPR] = analyze.trials.doPrediction(mdl,r,threshold,'Name',value,...);
%
% Inputs
%  mdl       - GeneralizedLinearMixedModel object that predicts LABEL 
%                 ([1 2]) where 1 == Unsuccessful | 2 == Successful
%  r         - (Optional) data table to use for predictions
%  threshold - (Optional) Specific threshold for measuring ROC. Values
%                 greater than threshold (as predicted by model) get
%                 assigned to the "Successful" category.
%  varargin - (Optional) 'Name',value pairs specifying Variable Names in
%                 mdl source data (mdl.Variable) and the values that are
%                 allowable for the corresponding variable.
%
% Output
%  TPR       - True Positive Rate 
%              TPR = TP/P
%              TP = [# True Positives: Output Unsuccessful v True Unsuccessful]
%              P  = [TP + # False Negatives] = Total target positives 
%
%  FPR       - False Positive Rate 
%              FPR = FP/N
%              FP = [# False Positives: Output Unsuccessful v True Success]
%              N  = [FP + # True Negatives] = Total target negatives
%
% See also: analyze.stat.plotROC, analyze.trials, unit_learning_stats

if nargin < 3
   threshold = 0.5;
end

if nargin < 2
   r = mdl.Variables;
end

if numel(varargin) > 0
   r = analyze.slice(r,varargin{:});
end

tU = r.Outcome=="Unsuccessful";
tS = r.Outcome=="Successful";

output = categorical(double(predict(mdl,r) > threshold)+1,...
   [1 2],...
   {'Unsuccessful','Successful'});

tp = sum(output=="Unsuccessful" & tU);
tn = sum(output=="Successful" & tS);
fp = sum(output=="Unsuccessful" & tS);
fn = sum(output=="Successful" & tU);

TPR = tp/(tp+fn);
FPR = fp/(fp+tn);
end