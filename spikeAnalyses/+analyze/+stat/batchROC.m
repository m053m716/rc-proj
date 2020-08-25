function [fig,AUC] = batchROC(mdl,type,varargin)
%BATCHROC Plot ROC for prediction model of individual animals or groups Successful/Unsuccessful by trial
%
%  fig = analyze.stat.batchROC(mdl);
%
% Inputs
%  mdl - GeneralizedLinearMixedModel that predicts "Label" (response)
%        "Label" : 1 - Unsuccessful | 2 - Successful
%  type - 'GroupID' | 'AnimalID' | 'GroupID*Area' (def) |
%           'GroupID*Area*Week' | 'AnimalID*Week' | 'AnimalID*Area*Week'
%     If type includes 'AnimalID'
%     -> varargin{1} : Array of included animal identifiers
%        * For interaction "type" it is only supported for one animal at a
%           time (otherwise figures get too cluttered)
%
% Output
%  fig - Figure handle with ROC curve
%  AUC - AUC corresponding to each panel
%
% See also: unit_learning_stats, analyze.trials.doPrediction,
%           analyze.stat.plotROC

if nargin < 2
   type = 'GroupID*Area';
end

mainTitle = sprintf('Outcome ROC (%s)',type);
fig = figure('Name',mainTitle,...
   'Color','w','NumberTitle','off',...
   'Units','Normalized','Position',[0.1 0.1 0.8 0.8]);
r = mdl.Variables;
r.Week = categorical(ceil(r.PostOpDay/7),1:4,{'Week-1','Week-2','Week-3','Week-4'});
AUC = [];
switch lower(type)
   case 'animalid'
      [~,TID] = findgroups(r(:,{'GroupID','AnimalID'}));
      if numel(varargin) < 1
         animals = {'RC-02','RC-05','RC-21','RC-43'}; % Defaults are different than in main script unit_learning_stats.m
      else
         animals = varargin{1};
      end
      TID = TID(ismember(string(TID.AnimalID),animals),:);
      [gGroup,TID_g] = findgroups(TID(:,'GroupID'));
      gGroup = splitapply(@numel,gGroup,gGroup);
      nMax = max(gGroup);
      iGroup = struct(string(TID_g.GroupID(1)),1,...
                      string(TID_g.GroupID(2)),nMax+1);
      iVal = iGroup;
      
      for iT = 1:size(TID,1)
         g = char(TID.GroupID(iT));
         ax = formatAxes(subplot(2,nMax,iGroup.(g)),fig,g);
         analyze.stat.plotROC(ax,mdl,'AnimalID',char(TID.AnimalID(iT)));
         if iGroup.(g)==iVal.(g)
            ylabel(ax,g,'FontName','Arial','Color','k','FontWeight','bold');
         end
         iGroup.(g) = iGroup.(g) + 1;
      end    
   case 'animalid*week'
      set(fig,'Position',[0.35+randn(1)*0.05 0.1 0.3 0.8]);
      [~,TID] = findgroups(r(:,{'AnimalID','Week'}));
      if numel(varargin) < 1
         animalid = string(TID.AnimalID(randsample(size(TID,1),1)));
      else
         animalid = varargin{1};
      end
      TID = TID(ismember(string(TID.AnimalID),animalid),:);
      
      for iT = 1:size(TID,1)
         a = char(TID.AnimalID(iT));
         w = double(TID.Week(iT));
         W = char(TID.Week(iT));
         ax = formatAxes(subplot(4,1,w),fig,W);
         analyze.stat.plotROC(ax,mdl,'AnimalID',a,'Week',W);
      end  
      delete(findobj(fig.Children,'Type','Legend'));
   case 'animalid*area*week'
      set(fig,'Position',[0.35+randn(1)*0.05 0.1 0.3 0.8]);
      [~,TID] = findgroups(r(:,{'AnimalID','Area','Week'}));
      if numel(varargin) < 1
         animalid = string(TID.AnimalID(randsample(size(TID,1),1)));
      else
         animalid = varargin{1};
      end
      
      TID = TID((TID.AnimalID==animalid),:);
      mainTitle = sprintf('%s: %s (by Week)',animalid,mainTitle);
      ax = gobjects(4,2);
      for iT = 1:8
         ax(iT) = subplot(4,2,iT);
      end
      for iT = 1:size(TID,1)
         a = char(TID.Area(iT));
         A = char(TID.AnimalID(iT));
         w = double(TID.Week(iT));
         W = char(TID.Week(iT));
         
         iArea = double(TID.Area(iT));
         iPlot = 2*(w-1)+iArea;
         
         formatAxes(ax(iPlot),fig,sprintf('%s::%s::%s',A,a,W));
         analyze.stat.plotROC(ax(iPlot),mdl,'AnimalID',A,'Area',a,'Week',W);
         title(ax(iPlot),sprintf('%s: %s',a,W),...
            'FontName','Arial','FontWeight','bold','Color','k');
      end
      delete(findobj(fig.Children,'Type','Legend'));
      
      % Add legend at end
      legend(findobj(ax(1).Children,'Tag','ROC'),...
         'Location','southeast',...
         'FontName','Arial',...
         'TextColor','black',...
         'AutoUpdate','off');
   case 'groupid'
      [~,TID] = findgroups(r(:,'GroupID'));      
      for iT = 1:size(TID,1)
         g = char(TID.GroupID(iT));
         ax = formatAxes(subplot(1,2,iT),fig,g);
         analyze.stat.plotROC(ax,mdl,'GroupID',g);
      end  
   case 'groupid*area'
      [~,TID] = findgroups(r(:,{'GroupID','Area'}));    
      for iT = 1:size(TID,1)
         g = char(TID.GroupID(iT));
         a = char(TID.Area(iT));
         ax = formatAxes(subplot(2,2,iT),fig,sprintf('%s::%s',g,a));
         analyze.stat.plotROC(ax,mdl,'GroupID',g,'Area',a);
      end  
   case 'groupid*area*week'
      set(fig,'Position',[0.35+randn(1)*0.05 0.1 0.3 0.8]);
      [~,TID] = findgroups(r(:,{'GroupID','Area','Week'}));
      if numel(varargin) < 1
         group = "Ischemia";
      else
         group = varargin{1};
      end
      TID = TID(TID.GroupID==group,:);
      mainTitle = sprintf('%s: (Area by Week %s} ROC)',...
         group,strrep(mdl.PredictorNames{end},'_','_{'));
      ax = gobjects(4,2);
      for iT = 1:8
         ax(iT) = subplot(4,2,iT);
      end
      AUC = nan(4,2);
      for iT = 1:size(TID,1)
         g = char(TID.GroupID(iT));
         a = char(TID.Area(iT));
         w = char(TID.Week(iT));
         iArea = double(TID.Area(iT));
         iPlot = 2*(double(TID.Week(iT))-1)+iArea;
         
         formatAxes(ax(iPlot),fig,sprintf('%s::%s',g,a));
         [~,~,~,AUC(iPlot),~] = analyze.stat.plotROC(ax(iPlot),mdl,'GroupID',g,'Area',a,'Week',w);
         if iPlot<=2
            title(ax(iPlot),a,'FontName','Arial','FontWeight','bold','Color','k');
         end
         if rem(iPlot,2)==1
            ylabel(ax(iPlot),w,'FontName','Arial','FontWeight','bold','Color','k');
         end
      end
      delete(findobj(fig.Children,'Type','Legend'));
%       
%       % Add legend at end
%       legend(findobj(ax(1).Children,'Tag','ROC'),...
%          'Location','southeast',...
%          'FontName','Arial',...
%          'TextColor','black',...
%          'AutoUpdate','off');
   otherwise
      error('Unrecognized `type`: <strong>%s</strong>',type);
      
end
   
suptitle(mainTitle);

   function ax = formatAxes(ax,fig,tag)
      if nargin < 3
         tag = '';
      end
      set(ax,'XColor','k','YColor','k',...
         'NextPlot','add','FontName','Arial',...
         'LineWidth',1.25,'Tag',tag,'Parent',fig);
   end

end