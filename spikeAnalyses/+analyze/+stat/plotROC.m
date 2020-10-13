function [fig,TPR,FPR,AUC,r] = plotROC(mdl,varargin)
%PLOTROC Plot ROC for prediction model of Successful/Unsuccessful by trial
%
%  fig = analyze.stat.plotROC(mdl);
%  fig = analyze.stat.plotROC(mdl,'Name',value,...);
%  fig = analzye.stat.plotROC(ax,mdl,'Name',value,...);
%
%  -- or --
%  
%  fig = analyze.stat.plotROC(TPR,FPR,Prediction,bestThresh,TPR_thresh,FPR_thresh,dispID);
%
% Inputs
%  mdl - GeneralizedLinearMixedModel that predicts "Label" (response)
%        "Label" : 1 - Unsuccessful | 2 - Successful
%  varargin - (Optional) 'Name',value pairs specifying Variable Names in
%                 mdl source data (mdl.Variable) and the values that are
%                 allowable for the corresponding variable.
%
% -- OR (if mdl is not numeric) --
%  TPR - True positive rate (same number elements as FPR)
%  FPR - False positive rate
%  Prediction - All predicted values used to generate TPR and FPR
%  bestThresh - Threshold selected for best confusion matrix
%  TPR_thresh - TPR corresponding to bestThresh
%  FPR_thresh - FPR corresponding to bestThresh
%  dispID     - (Optional) char or string to use as title of figure
%
% Output
%  fig - Figure handle with ROC curve
%  [TPR, FPR, AUC, r] - see analyze.stat.computeROC
%
% See also: analyze.stat, analyze.stat.computeROC, analyze.stat.batchROC, 
%           analyze.trials.doPrediction, unit_learning_stats

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

if ~isnumeric(mdl)

   [TPR,FPR,AUC,r] = analyze.stat.computeROC(mdl,varargin{:});

   if numel(varargin) >= 2
      dispID = strjoin(varargin(2:2:end),'::');
   else
      dispID = 'ROC';
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
   title(ax,sprintf('(%s)',dispID),...
      'FontName','Arial','FontWeight','bold','Color','k');

   analyze.stat.addInputDistribution(ax,outputs,bestThresh);
   
else
   TPR = mdl;
   FPR = varargin{1};
   Prediction = varargin{2};
   bestThresh = varargin{3};
   TPR_thresh = varargin{4};
   FPR_thresh = varargin{5};
   if numel(varargin) < 6
      dispID = 'ROC';
   else
      dispID = varargin{6};
   end
   AUC = [];
   
   line(ax,FPR,TPR,...
      'LineWidth',2,...
      'Color','k',...
      'LineStyle','-',...
      'Tag','ROC',...
      'DisplayName',dispID);
   line(ax,[0 1],ones(1,2).*TPR_thresh,'LineStyle','--','LineWidth',1.5,...
      'DisplayName',sprintf('TPR: Threshold = %4.2f',bestThresh),'Color','k');
   line(ax,ones(1,2).*FPR_thresh,[0 1],'LineStyle','--','LineWidth',1.5,...
      'DisplayName',sprintf('FPR: Threshold = %4.2f',bestThresh),'Color','m');

   xlabel(ax,'False Positive Rate','FontName','Arial','Color','k','FontWeight','bold');
   ylabel(ax,'True Positive Rate','FontName','Arial','Color','k','FontWeight','bold');
   legend(ax,'TextColor','k','FontName','Arial','Location','southeast');
   title(ax,sprintf('(%s)',dispID),...
      'FontName','Arial','FontWeight','bold','Color','k');

   analyze.stat.addInputDistribution(ax,Prediction,bestThresh);
   
end




end