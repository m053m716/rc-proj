function [data,fig,tbl] = weeklyConfusion(rClass,type)
%WEEKLYCONFUSION Return data for weekly confusion tabulation
%
%  data = analyze.trials.weeklyConfusion(rClass);
%  [data,fig] = analyze.trials.weeklyConfusion(rClass);
%  [data,fig] = analyze.trials.weeklyConfusion(rClass,'type');
%
% Inputs
%  rClass - Data table with classification predictions of individual trials
%     'type' : 'standard' (default)
%              'simple' (does not use durations in Naive Bayes classifier)
%
% Output
%  data   - Data table with tabulated accuracy on weekly basis
%  fig    - (Optional) second output argument request generates a figure
%  tbl    - Tabulation with counts by group
%
% See also: Contents, unit_learning_stats

if nargin < 2
   type = 'standard';
end

[G,TID] = findgroups(rClass(:,{'AnimalID','Week'}));
TID.Prior = cell2mat(splitapply(@(o){[sum(string(o)=="Successful")./numel(o), sum(string(o)=="Unsuccessful")./numel(o)]},...
   rClass.Outcome,G));
rClass = outerjoin(rClass,TID,'Keys',{'AnimalID','Week'},'LeftVariables',setdiff(rClass.Properties.VariableNames,{'Prior'}),...
   'RightVariables',{'Prior'},'Type','left');
[G,data] = findgroups(rClass(:,{'GroupID','Area','Week'}));

switch lower(type)
   case 'standard'
      if ismember('AUC',rClass.Properties.VariableNames)
         [data.Accuracy,data.TPR,data.FPR,data.FDR,data.TNR,data.AUC] = ...
            splitapply(@getConfusionStats_AUC,rClass.TP,rClass.FP,rClass.TN,rClass.FN,rClass.AUC,G);
         varName = 'AUC';
      else
         [data.Accuracy,data.TPR,data.FPR,data.FDR,data.TNR,data.Weighted_Accuracy] = ...
            splitapply(@getConfusionStats,rClass.TP,rClass.FP,rClass.TN,rClass.FN,rClass.Prior,G);
         varName = 'Weighted_Accuracy';
      end
   case 'simple'
      [data.Accuracy,data.TPR,data.FPR,data.FDR,data.TNR,data.Weighted_Accuracy] = ...
            splitapply(@getConfusionStats,rClass.TP_s,rClass.FP_s,rClass.TN_s,rClass.FN_s,rClass.Prior,G);
         varName = 'Weighted_Accuracy';
   otherwise
      error('Unrecognized value for `type` input (''%s'')',type);
   
end
if nargout < 2
   fig = [];
   return;
end

[~,obsID] = findgroups(rClass(:,{'ChannelID','Area','GroupID'}));
x = strcat(string(obsID.GroupID),"::",string(obsID.Area));
tbl = tabulate(x);

G = findgroups(data(:,{'GroupID','Area'})); 
fig = figure('Color','w','Name','Weekly Classifier Performance',...
   'Units','Normalized','Position',[0.2 0.2 0.5 0.5]); 
ax = subplot(2,3,1);
set(ax,'NextPlot','add','XColor','k','YColor','k',...
   'XLim',[1 4],'XTick',1:4,...
   'YLim',[0 1],'YTick',[0.25 0.5 0.75],...
   'FontName','Arial','LineWidth',1.5,....
   'Parent',fig); 

splitapply(@(x,y,g,a)addDataLines(ax,x,y,g,a),...
   data.Week,data.TPR,data.GroupID,data.Area,G); 
title(ax,'Sensitivity','FontName','Arial','Color','k');

ax = subplot(2,3,2);
set(ax,'NextPlot','add','XColor','k','YColor','k',...
   'XLim',[1 4],'XTick',1:4,...
   'YLim',[0 1],'YTick',[0.25 0.5 0.75],...
   'FontName','Arial','LineWidth',1.5,....
   'Parent',fig); 
splitapply(@(x,y,g,a)addDataLines(ax,x,y,g,a),...
   data.Week,data.FPR,data.GroupID,data.Area,G); 
title(ax,'FPR','FontName','Arial','Color','k');

ax = subplot(2,3,3);
set(ax,'NextPlot','add','XColor','k','YColor','k',...
   'XLim',[1 4],'XTick',1:4,...
   'YLim',[0 1],'YTick',[0.25 0.5 0.75],...
   'FontName','Arial','LineWidth',1.5,....
   'Parent',fig); 
splitapply(@(x,y,g,a)addDataLines(ax,x,y,g,a),...
   data.Week,data.(varName),data.GroupID,data.Area,G); 
legend(ax,'Location','southeast','TextColor','black','FontName','Arial');
title(ax,strrep(varName,'_',' '),'FontName','Arial','Color','k');

ax = subplot(2,3,4);
set(ax,'NextPlot','add','XColor','k','YColor','k',...
   'XLim',[1 4],'XTick',1:4,...
   'YLim',[0 1],'YTick',[0.25 0.5 0.75],...
   'FontName','Arial','LineWidth',1.5,....
   'Parent',fig); 
splitapply(@(x,y,g,a)addDataLines(ax,x,y,g,a),...
   data.Week,data.FDR,data.GroupID,data.Area,G); 
xlabel(ax,'Week','FontName','Arial','Color','k');
title(ax,'FDR','FontName','Arial','Color','k');

ax = subplot(2,3,5);
set(ax,'NextPlot','add','XColor','k','YColor','k',...
   'XLim',[1 4],'XTick',1:4,...
   'YLim',[0 1],'YTick',[0.25 0.5 0.75],...
   'FontName','Arial','LineWidth',1.5,....
   'Parent',fig); 
splitapply(@(x,y,g,a)addDataLines(ax,x,y,g,a),...
   data.Week,data.TNR,data.GroupID,data.Area,G); 
xlabel(ax,'Week','FontName','Arial','Color','k');
title(ax,'Specificity','FontName','Arial','Color','k');

ax = subplot(2,3,6);
set(ax,'NextPlot','add','XColor','k','YColor','k',...
   'XLim',[1 4],'XTick',1:4,...
   'YLim',[0 1],'YTick',[0.25 0.5 0.75],...
   'FontName','Arial','LineWidth',1.5,....
   'Parent',fig); 
splitapply(@(x,y,g,a)addDataLines(ax,x,y,g,a),...
   data.Week,data.Accuracy,data.GroupID,data.Area,G); 
legend(ax,'Location','southeast','TextColor','black','FontName','Arial');
xlabel(ax,'Week','FontName','Arial','Color','k');
title(ax,'Accuracy','FontName','Arial','Color','k');


iIschemia = contains(tbl(:,1),'Ischemia');
iIntact = contains(tbl(:,1),'Intact');
nIschemia = sum(vertcat(tbl{iIschemia,2}));
nIntact = sum(vertcat(tbl{iIntact,2}));

suptitle(sprintf('Ischemia: %d channels | Intact: %d channels',nIschemia,nIntact));


   function [acc,tpr,fpr,fdr,tnr,w_acc] = getConfusionStats(TP,FP,TN,FN,prior)
      tp = sum(TP);
      fp = sum(FP);
      tn = sum(TN);
      fn = sum(FN);  
      
      acc = (tp + tn)/(tp+fp+tn+fn);
      
      tpr = tp/(tp+fn);
      
      fpr = fp/(fp+tn);
      
      fdr = fp/(fp+tp);
      
      tnr = tn/(tn+fp);
      
      c = (1 + sqrt(2)/2)/2; % constant offset
      
      L = c - sqrt(sum(prior.^2,2)); % min sqrt(2)/2, max val is 1
      
      K = (1 ./ (1 + exp(-8 .* pi .* L)))'; % Bounded between 0 and 1
      C = 1 - K;
      
      % Weighted accuracy based on uninformative prior
      w_acc = (sum(TP.*K) + sum(TN.*K))/...
         (sum(TP.*K)+sum(TN.*K)+sum(FP.*C)+sum(FN.*C));
      
   end

   function [acc,tpr,fpr,fdr,tnr,avg_AUC] = getConfusionStats_AUC(TP,FP,TN,FN,auc)
      tp = sum(TP);
      fp = sum(FP);
      tn = sum(TN);
      fn = sum(FN);  
      
      acc = (tp + tn)/(tp+fp+tn+fn);
      
      tpr = tp/(tp+fn);
      
      fpr = fp/(fp+tn);
      
      fdr = fp/(fp+tp);
      
      tnr = tn/(tn+fp);
      
      
      % Weighted accuracy based on uninformative prior
      idx = any([TP,FP,TN,FN] > 0,2);
      avg_AUC = nanmean(auc(idx));
   end

   function addDataLines(ax,x,y,g,a)
      groupName = ["Ischemia::CFA";"Ischemia::RFA";"Intact::CFA";"Intact::RFA"];
      c = [1.0 0.2 0.2; 0.8 0.0 0.0; 0.2 0.2 1.0; 0.0 0.0 0.8];
      
      str = string(sprintf('%s::%s',string(g(1)),string(a(1))));
      
      line(ax,x,y,'Color',c(groupName==str,:),...
         'LineWidth',2,...
         'DisplayName',str)
   end

end