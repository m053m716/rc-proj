function [E,fig] = export_table(D,showDistributions)
%EXPORT_TABLE  Create table that can be exported for JMP statistics
%
%  E = analyze.jPCA.export_table(D); % Default align is "Grasp"
%  [E,fig] = analyze.jPCA.export_table(D,showDistributions);
%
% Inputs
%  D                 - Table output by `analyze.jPCA.multi_jPCA`
%  showDistributions - (Default false), set true to plot output histograms
%
% Output
%  E - Table that can be exported for jPCA analysis.

if nargin < 2
   showDistributions = false;
end

D = D(ismember(string(D.Alignment),"Grasp") & ...
      ismember(string(D.Area),"All"),:);

E = table.empty;
for iD = 1:size(D,1)
   animalID = D.AnimalID(iD);
   blockID = floor(iD/2);
   groupID = D.Group(iD);
   postOpDay = D.PostOpDay(iD);
   for iPlane = 1:3      
      vec = [(iPlane-1)*2+1,iPlane*2];
      best_PCs = D.Summary{iD}.SS.best.explained.sort.vec.eig(vec);
      skew_PCs = D.Summary{iD}.SS.skew.explained.sort.vec.eig(vec);
      Explained_Skew = sum(D.Summary{iD}.SS.skew.explained.eig(skew_PCs)) ./ 100;
      R2_Skew = mean(D.Summary{iD}.SS.skew.explained.varcapt(skew_PCs)) ./ 100;
      Explained_Best = sum(D.Summary{iD}.SS.best.explained.eig(best_PCs)) ./ 100;
      R2_Best = mean(D.Summary{iD}.SS.best.explained.varcapt(best_PCs)) ./ 100;
      N = numel(D.Projection{iD});
      AnimalID = animalID;
      BlockID = blockID;
      GroupID = groupID;
      PostOpDay = postOpDay;
      PlaneIndex = iPlane;  
      AverageDuration = nanmean([D.PhaseData{iD}{iPlane}.duration].' .* 1e-3);
      thisTab = table(AnimalID,GroupID,BlockID,...
         PlaneIndex,PostOpDay,N,...
         AverageDuration,...
         Explained_Skew,R2_Skew,...
         Explained_Best,R2_Best);
      E = [E; thisTab]; %#ok<AGROW>
   end
end
E.GroupID = categorical(E.GroupID);
E.BlockID = categorical(E.BlockID);
E.AnimalID = categorical(E.AnimalID);

E.LogOdds_Explained = log(E.Explained_Skew) - log(E.Explained_Best);
E.LogOdds_R2 = log(E.R2_Skew) - log(E.R2_Best);

E.Properties.UserData = struct;
E.Properties.Description = 'jPCA Rotation Subspace summary table for fitting glme';
E = sortrows(E,'PostOpDay','ascend');

if showDistributions
   addHelperRepos();
   fig = figure('Name','Exported Response Distributions',...
      'Color','w',...
      'Units','Normalized',...
      'Position',[0.1 0.1 0.8 0.8],...
      'NumberTitle','off');
   responseVars = {...
      'Explained_Skew', 'Rotatory Planes: % explained';...
      'Explained_Best', 'Best-Fit Planes (control): % explained';...
      'R2_Skew', 'Rotatory Planes: R^2 Linearized System';...
      'R2_Best', 'Best-Fit Planes (control): R^2 Linearized System';...
      'LogOdds_Explained', '\Deltalog(explained)';...
      'LogOdds_R2', '\Deltalog(R^2)'};
   xl = [0 0.5; ...
         0 0.5; ...
         0 1; ...
         0 1; ...
         nan nan; ...
         nan nan];
   edges = {...
      linspace(0,1,26);...
      linspace(0,1,26); ...
      linspace(0,1,26); ...
      linspace(0,1,26); ....
      16; ...
      16 ...
      };
   nTotal = size(responseVars,1);
   nCol = floor(sqrt(nTotal));
   nRow = ceil(nTotal/nCol);
   G = ["Intact","Ischemia"];
   col = [0.3 0.3 0.8; 0.8 0.3 0.3];
   mark = 'ox';
   ax = [];
   for ii = 1:nTotal
      if ii == nTotal
         ax = [ax; subplot(nRow,nCol,ii:(nRow*nCol))]; %#ok<AGROW>
         if isnan(xl(ii,1))
            set(ax(ii),'XColor','k','YColor','k',...
               'NextPlot','add','LineWidth',1.5,...
               'FontName','Arial','YLim',[0 1]);
         else
            set(ax(ii),'XColor','k','YColor','k',...
               'NextPlot','add','LineWidth',1.5,...
               'FontName','Arial',...
               'XLim',xl(ii,:),'YLim',[0 1]);
         end
      else
         ax = [ax; subplot(nRow,nCol,ii)]; %#ok<AGROW>
         if isnan(xl(ii,1))
            set(ax(ii),'XColor','k','YColor','k',...
               'NextPlot','add','LineWidth',1.5,'FontName','Arial',...
               'YLim',[0 1]);
         else
            set(ax(ii),'XColor','k','YColor','k',...
               'NextPlot','add','LineWidth',1.5,'FontName','Arial',...
               'XLim',xl(ii,:),'YLim',[0 1]);
         end
      end
      if rem(ii,nCol)==1
         ylabel(ax(ii),'Probability','FontName','Arial','Color','k');
      end
      if ii > ((nRow-1)*nCol)
         xlabel(ax(ii),'Value','FontName','Arial','Color','k');
      end
      for iG = 1:2
         histogram(ax(ii),E.(responseVars{ii,1})(E.GroupID==G(iG)),edges{ii},...
            'FaceColor',col(iG,:),'EdgeColor','none','Normalization','probability'); 
      end
      legend(ax(ii),G,'Location','best');
      title(ax(ii),responseVars{ii,2},'FontName','Arial','Color','k');
   end

   % % Fit logistic regression to responses % %
   responseVars = {...
      'Explained_Skew', 'Rotatory Planes: % explained';...
      'Explained_Best', 'Best-Fit Planes (control): % explained';...
      'R2_Skew', 'Rotatory Planes: R^2 Linearized System';...
      'R2_Best', 'Best-Fit Planes (control): R^2 Linearized System'};
   xl = [0 0.5; ...
         0 0.5; ...
         0 1; ...
         0 1];
   nTotal = size(responseVars,1);
   nCol = floor(sqrt(nTotal));
   nRow = ceil(nTotal/nCol);
   
   fig = [fig; ...
      figure('Name','Exported Response: Trends by Day',...
      'Color','w',...
      'Units','Normalized',...
      'Position',gfx__.addToSecondMonitor(),...
      'NumberTitle','off')];
   figure(fig(2));
   ax2 = [];
   for ii = 1:nTotal
      if ii == nTotal
         ax2 = [ax2; subplot(nRow,nCol,ii:(nRow*nCol))]; %#ok<AGROW>
      else
         ax2 = [ax2; subplot(nRow,nCol,ii)]; %#ok<AGROW>
      end
      set(ax2(ii),'XColor','k','YColor','k',...
            'NextPlot','add','LineWidth',1.5,...
            'FontName','Arial',...
            'XLim',[-4 35],'XTick',[0 7 14 21 28]);
      if ~isnan(xl(ii,1))
         ylim(ax2(ii),xl(ii,:));
      end
      labInfo = strsplit(responseVars{ii,2},': ');
      xPlot = linspace(0,30,100); % See X in helper function
      yPlot = nan(2,numel(xPlot));
      Y = cell(1,2);
      zObs = cell(1,2);
      zHat = cell(1,2);
      xloc = [-3, 31];
      yIdx = [1,numel(xPlot)];
      for iG = 1:2
         eThis = E(E.GroupID==G(iG),:);
         scatter(ax2(ii),...
            eThis.PostOpDay,...
            eThis.(responseVars{ii,1}),...
            'Marker',mark(iG),...
            'MarkerFaceColor',col(iG,:),...
            'MarkerEdgeColor',col(iG,:),...
            'MarkerFaceAlpha',0.66,...
            'MarkerEdgeAlpha',0.75,...
            'SizeData',12,...
            'DisplayName',G(iG)); 
         gThis= findgroups(eThis(:,{'AnimalID'}));
         [Y{iG},stat] = splitapply(...
            @(x,y)analyze.stat.addLogisticRegression(ax2(ii),x,y,col(iG,:),...
            xPlot,'addlabel',false),...
            eThis.PostOpDay,eThis.(responseVars{ii,1}),gThis);
         stat = cell2mat(stat);
         Y{iG} = cell2mat(Y{iG});
         yPlot(iG,:) = nanmean(Y{iG},1);
         xThis = vertcat(stat.x);
         yThis = vertcat(stat.y);
         usePts = ~isnan(xThis) & ~isnan(yThis);
         analyze.stat.addLogisticRegression(ax2(ii),xThis(usePts),yThis(usePts),col(iG,:),...
            xPlot,'addlabel',true,'LineStyle','-','LineWidth',2.0,'TX',xloc(iG));
      end
      yTest = Y{2}(~any(isnan(Y{2}),2),:)';
      yTest = mat2cell(yTest,ones(1,size(yTest,1)),size(yTest,2));
      hTest = Y{1}(~any(isnan(Y{1}),2),:)';
      hTest = mat2cell(hTest,ones(1,size(hTest,1)),size(hTest,2));
      xTest = xPlot';
      gfx__.addSignificanceLine(ax2(ii),xTest,yTest,hTest,...
         'Alpha',0.05,'DoMultipleComparisonsCorrection',false,...
         'NormalizedBracketY',0.1,'NormalizedTickY',0.125);
      
      ylabel(ax2(ii),labInfo{end},'FontName','Arial','Color','k');
      if numel(labInfo) > 1
         title(labInfo{1},'FontName','Arial','Color','k');
      end

      if ii > ((nRow-1)*nCol)
         xlabel(ax2(ii),'Post-Op Day','FontName','Arial','Color','k');
      end
   end
   
else
   fig = [];
end 

end