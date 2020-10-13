function [AUC,bestThresh,ROCdata,fig] = computeWeeklyChannelROC(Outcome,Prediction,name)
%COMPUTEWEEKLYCHANNELROC Compute area under curve for individual channel ROC and optionally plot the ROC
%
%  AUC = analyze.trials.computeWeeklyChannelROC(Outcome,Prediction);
%  [AUC,bestThresh,ROCdata,fig] = analyze.trials.computeWeeklyChannelROC(Outcome,Prediction);
%  [AUC,bestThresh,ROCdata,fig] = analyze.trials.computeWeeklyChannelROC(Outcome,Prediction,name);
%
% Inputs
%  Outcome     - Observed outcomes - [0 Unsuccessful 1 Successful]
%  Prediction  - Continuous predicted value from regression onto Outcome
%  name        - (Optional) only used if `fig` is requested; specify custom
%                    name for axes title (otherwise it is `ROC` by default)
%
% Output
%  AUC         - Area under curve (AUC) for receiver operating
%                 characteristic (ROC) curve relating false positive rate
%                 and true positive rate. A value of 1 indicates a perfect
%                 detector, while a value of 0.5 indicates an uninformative
%                 detector.
%  bestThresh  - Best threshold determined as the last value before change
%                 in ROC is lower than expected change for uninformative
%                 detector.
%  ROCdata     - (Optional); this is a data struct with fields corresponding to
%                 the FPR, TPR, and matched thresholds used to generate
%                 each ROC point.
%  fig         - (Optional); if requested, this generates an ROC figure 
%
% See also: Contents, unit_learning_stats

THRESH_LIST = linspace(0,1,50);
dt_thresh = min(diff(THRESH_LIST));

if nargin < 3
   name = 'ROC';
end

if iscategorical(Outcome)
   tmp = false(size(Outcome));
   tmp(string(Outcome)=="Successful") = true;
   Outcome = tmp;
end

ROCdata = struct;
[ROCdata.TPR,ROCdata.FPR,ROCdata.thresh] = analyze.stat.ROCstats(Outcome,Prediction,THRESH_LIST);
AUC = trapz(ROCdata.FPR,ROCdata.TPR);

iForward = [false, true(1,numel(ROCdata.thresh)-1)];
iBackward = [true(1,numel(ROCdata.thresh)-1), false];

dRoc_f = diff(ROCdata.TPR(iForward)) ./ diff(ROCdata.FPR(iForward));
dRoc_b = diff(ROCdata.TPR(iBackward)) ./ diff(ROCdata.FPR(iBackward));

dRoc = (dRoc_f + dRoc_b)./2;
iThresh = find(dRoc > dt_thresh,1,'last');
if isempty(iThresh)
   iThresh = round(numel(ROCdata.thresh)/2);
end
bestThresh = ROCdata.thresh(iThresh);
ROCdata.TPR_thresh = ROCdata.TPR(iThresh);
ROCdata.FPR_thresh = ROCdata.FPR(iThresh);

if nargout < 4
   fig = [];
   return;
end

fig = figure('Name','Receiver Operating Characteristic',...
   'Color','w','Units','Normalized',...
   'Position',[0.2 0.2 0.5 0.5]);
ax = axes(fig,'XColor','k','YColor','k','LineWidth',1.5,...
   'FontName','Arial','NextPlot','add');

% Add the ROC to `fig` via `ax`:
analyze.stat.plotROC(ax,ROCdata.TPR,ROCdata.FPR,Prediction,...
   bestThresh,ROCdata.TPR_thresh,ROCdata.FPR_thresh,name);
end