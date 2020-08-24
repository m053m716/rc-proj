function fig = plotROC(mdl,varargin)
%PLOTROC Plot ROC for prediction model of Successful/Unsuccessful by trial
%
%  fig = analyze.stat.plotROC(mdl);
%  fig = analyze.stat.plotROC(mdl,'Name',value,...);
%  fig = analzye.stat.plotROC(ax,mdl,'Name',value,...);
%
% Inputs
%  mdl - GeneralizedLinearMixedModel that predicts "Label" (response)
%        "Label" : 1 - Unsuccessful | 2 - Successful
%  varargin - (Optional) 'Name',value pairs specifying Variable Names in
%                 mdl source data (mdl.Variable) and the values that are
%                 allowable for the corresponding variable.
%
% Output
%  fig - Figure handle with ROC curve
%
% See also: unit_learning_stats, analyze.trials.doPrediction

if isa(mdl,'matlab.graphics.axis.Axes')
   ax = mdl;
   mdl = varargin{1};
   varargin(1) = [];
   fig = ax.Parent;
else
   fig = figure('Name','Outcome ROC','Color','w','NumberTitle','off');
   ax = axes(fig,'XColor','k','YColor','k','NextPlot','add',...
      'LineWidth',1.5,'FontName','Arial');
end
r = mdl.Variables;
r.Week = categorical(ceil(r.PostOpDay/7),1:4,{'Week-1','Week-2','Week-3','Week-4'});
r = analyze.slice(r,varargin{:});
threshold_list = linspace(0,1,25);
TPR = nan(size(threshold_list));
FPR = nan(size(threshold_list));

for iT = 1:numel(threshold_list)
   thresh = threshold_list(iT);
   [TPR(iT),FPR(iT)] = analyze.trials.doPrediction(mdl,r,thresh);
   
end

if numel(varargin) >= 2
   dispID = strjoin(varargin(2:2:end),'::');
end

line(ax,FPR,TPR,...
   'LineWidth',2,...
   'Color','k',...
   'LineStyle','-',...
   'Tag','ROC',...
   'DisplayName',dispID);
outputs = predict(mdl,r);
bestThresh = nanmean(outputs);
[TPR_thresh,FPR_thresh] = analyze.trials.doPrediction(mdl,r,bestThresh);
line(ax,[0 1],ones(1,2).*TPR_thresh,'LineStyle','--','LineWidth',1.5,...
   'DisplayName',sprintf('TPR: Threshold = %4.2f',bestThresh),'Color','k');
line(ax,ones(1,2).*FPR_thresh,[0 1],'LineStyle','--','LineWidth',1.5,...
   'DisplayName',sprintf('FPR: Threshold = %4.2f',bestThresh),'Color','m');

xlabel(ax,'False Positive Rate','FontName','Arial','Color','k','FontWeight','bold');
ylabel(ax,'True Positive Rate','FontName','Arial','Color','k','FontWeight','bold');
legend(ax,'TextColor','k','FontName','Arial','Location','southeast');
title(ax,sprintf('Predictive Model ROC (%s)',strjoin(varargin,'::')),...
   'FontName','Arial','FontWeight','bold','Color','k');


analyze.stat.addInputDistribution(ax,outputs,bestThresh);

end