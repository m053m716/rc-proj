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
      xPlot = 3:30; % See X0 in helper function
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
         [Y{iG},stat] = splitapply(@(x,y)addLinearRegression(ax2(ii),x,y,col(iG,:),xPlot),...
            eThis.PostOpDay,eThis.(responseVars{ii,1}),gThis);
         stat = cell2mat(stat);
         Y{iG} = cell2mat(Y{iG});
         yPlot(iG,:) = nanmean(Y{iG},1);
         line(ax2(ii),xPlot,yPlot(iG,:),...
            'LineWidth',1.5,'Color',col(iG,:),...
            'LineStyle','-','DisplayName',sprintf('Fit: %s',G(iG)));
         zObs{iG} = vertcat(stat.z);
         zHat{iG} = vertcat(stat.zhat);
         TSS = nansum((zObs{iG} - nanmean(zObs{iG})).^2);
         ESS = nansum((zHat{iG} - nanmean(zObs{iG})).^2);
         R2 = ESS / TSS;
         yloc = yPlot(iG,yIdx(iG));
         text(ax2(ii),xloc(iG),yloc,sprintf('R^2 = %4.2f',R2),...
            'FontName','Arial','FontWeight','bold','Color',col(iG,:));
      end
      yTest = Y{2}(~any(isnan(Y{2}),2),:)';
      yTest = mat2cell(yTest,ones(1,size(yTest,1)),size(yTest,2));
      hTest = Y{1}(~any(isnan(Y{1}),2),:)';
      hTest = mat2cell(hTest,ones(1,size(hTest,1)),size(hTest,2));
      xTest = xPlot';
      gfx__.addSignificanceLine(ax2(ii),xTest,yTest,hTest,...
         'Alpha',0.05,'DoMultipleComparisonsCorrection',false,...
         'NormalizedBracketY',0.1,'NormalizedTickY',0.125);
%       legend(ax2(ii),'Location','best');
      
      ylabel(ax2(ii),labInfo{end},'FontName','Arial','Color','k');
      if numel(labInfo) > 1
         title(labInfo{1},'FontName','Arial','Color','k');
      end

      if ii > ((nRow-1)*nCol)
         xlabel(ax2(ii),'Post-Op Day','FontName','Arial','Color','k');
      end
   end
   

   fig = [fig; ...
      figure('Name','Rotatory Planes R^2: Trends by Day',...
      'Color','w',...
      'Units','Normalized',...
      'Position',gfx__.addToSecondMonitor(),...
      'NumberTitle','off')];
   ax3 = axes(fig(3),...
      'XColor','k','YColor','k',...
      'NextPlot','add','LineWidth',1.5,...
      'FontName','Arial',...
      'XLim',[-4 35],'XTick',[0 7 14 21 28],...
      'YLim',[0 1]);
   for iG = 1:2
      eThis = E(E.GroupID==G(iG),:);
      scatter(ax3,...
         eThis.PostOpDay,...
         eThis.R2_Skew,...
         'Marker',mark(iG),...
         'MarkerFaceColor',col(iG,:),...
         'MarkerEdgeColor',col(iG,:),...
         'MarkerFaceAlpha',0.66,...
         'MarkerEdgeAlpha',0.75,...
         'SizeData',12,...
         'DisplayName',G(iG)); 
   end
   expected = addLinearRegression(ax3,E.PostOpDay,E.R2_Skew,[0 0 0],xPlot,...
      'LineStyle','-','DisplayName','Expected');
   hTest = num2cell(expected{1}');
   gThis= findgroups(E(:,{'GroupID'}));
   c_all = col((E.GroupID=="Ischemia")+1,:);
   splitapply(@(x,y,col,groupTag)addLinearRegression(ax3,x,y,col(1,:),xPlot,...
      'DisplayName',string(groupTag(1))),E.PostOpDay,E.R2_Skew,c_all,...
      E.GroupID,gThis);
   
   for iG = 1:2
      % Aggregate data for comparison to expected value
      yTest = cell(size(hTest));
      for ii = 1:numel(xPlot)
         yTest{ii} = E.R2_Skew(E.PostOpDay == xPlot(ii));
      end
      gfx__.addSignificanceLine(ax3,xTest,yTest,hTest,...
         'Alpha',0.05,'DoMultipleComparisonsCorrection',false,...
         'NormalizedBracketY',0.1,'NormalizedTickY',0.125);
   end
   legend(ax3,'Location','Best');
else
   fig = [];
end

E.R2_Skew = E.R2_Skew - mean(E.R2_Skew);

% Helper functions for graphing & stats
   function [Y,stat] = addLinearRegression(ax,x,y,c,X,varargin)
      %ADDLINEARREGRESSION Helper for splitapply to add lines for animals
      %
      %  [Y,stat] = addLinearRegression(ax,x,y,c,X);
      %
      %  Uses median of dependent variable for offset and median of all
      %  pairs of distances of dependent variable for slope estimate.
      %
      % Inputs
      %  ax    - Target axes to add line to
      %  x     - X-Data (independent variable for linear regression)
      %  y     - Y-Data (dependent variable for linear regression)
      %  c     - Color of line
      %  X     - Points to use in projection to actually plot fit
      %
      % Output
      %  Y     - Model output for each day
      %  stat  - Statistics for model fit
      %
      %  Adds line to `axObj` object
      
      % DEFAULTS TO PLOT
      if nargin < 5
         X  = 3:30; % Plot line using prediction at these points
      end
%       TX = 33;   % Text x-coordinate
      
      % Put data into correct orientation for `pdist`
      if ~iscolumn(x)
         x = x.';
      end
      
      if ~iscolumn(y)
         y = y.';
      end
      
      if (numel(unique(x)) < 2) || (numel(unique(y)) < 2)
         Y  = {nan(size(X))};
         stat = {struct('R2',nan,'RSS',nan,'TSS',nan,'x',[],'y',[],...
            'yhat',[],'z',[],'zhat',[],'f',@(x)x,'g',@(x)x)};
         return;
      end

      % Get link function and inverse link function
      [yn,o,s] = scaleResponse(y);
      z = real(log(yn) - log(1-yn));
      
      % Get differences and median slope, intercept
      dZ = pdist(z);
      dX = pdist(x);
      iBad = isinf(dZ) | isinf(dX) | isnan(dZ) | isnan(dX);
      if ~any(~iBad)
         Y = {nan(size(X))};
         stat = {struct('R2',nan,'RSS',nan,'TSS',nan,'x',[],'y',[],...
            'yhat',[],'z',[],'zhat',[],'f',@(x)x,'g',@(x)x)};
         return;
      end
%       Beta  = median(dZ(~iBad) ./ dX(~iBad));
      Beta = dZ(~iBad) / dX(~iBad);
      Beta0 = mean(z);
      x0 = mean(x);

      f   = @(x)reshape(Beta0 + Beta.*(x - x0),numel(x),1); 
      g   = @(x)reshape(s./(1 + exp(-f(x)))+o,numel(x),1);
      
      % Plot
      Y = g(X);
      stat = struct;
      [stat.R2,stat.RSS,stat.TSS] = getR2(g,x,y);
      stat.x = x;
      stat.y = y;
      stat.yhat = g(x);
      stat.z = z;
      stat.zhat = f(x);
      stat.f = f;
      stat.g = g;
      stat = {stat};
      
      hReg = line(ax,X,Y,'Color',c,'LineStyle','--',...
         'LineWidth',1.25,'Tag','Median Regression',varargin{:});
      hReg.Annotation.LegendInformation.IconDisplayStyle = 'off';  
%       text(ax,TX,Y(end),sprintf('R^2 = %4.2f',R2),'FontName','Arial',...
%          'Color',c,'FontSize',12,'FontWeight','bold');
      Y = {reshape(Y,1,numel(Y))};
   end

   function [R2,RSS,TSS] = getR2(g,x,y)
      %GETR2 Return R2 for observations & model
      %
      %  [R2,RSS,TSS,x,y,yn,ynhat,yhat] = getR2(g,x,y);
      %
      % Inputs
      %  g - Function handle (model)
      %  x - Independent variable vector (days)
      %  y - Matched dependent variable vector (should match model g)
      %
      % Output
      %  R2  - Coefficient of determination based on model
      %  RSS - Residual sum of squares (sum-of-squares due to estimate
      %           errors)
      %  TSS - Total sum of squares (data variance, essentially)
      %  x   - Input data (independent variable)
      %  y   - Output data (dependent variable)
      %  yn  - Normalized output data (dependent variable; observation)
      %  ynhat - Normalized predicted output (model prediction)
      %  yhat- Function output estimate (prediction; scaled as normal)
      
      
      mu = mean(y);
      TSS = sum((y - mu).^2);
      RSS = sum((g(x) - y).^2);
      R2 = 1 - (RSS / TSS);
   end

   function [yn,o,s] = scaleResponse(y)
      %SCALERESPONSE Scale y to be "well-tolerated" for logistic regression
      %
      %  [yn,s,o] = scaleResponse(y);
      %
      % Inputs
      %  y  - Observed response of interest
      %
      % Output
      %  yn - "Normalized" response that is bounded on open interval (0,1)
      %  o  - Offset constant: 
      %        ```
      %           mu = median(y);
      %           yc = y - mu;
      %           ys = (yc) ./ s;
      %           o = min(ys) + e;
      %        ```
      %  s  - Scale constant:  
      %        ```
      %           mu = median(y);
      %           yc = y - mu;
      %           [s1,idx] = max(abs(yc)); 
      %           s = s1*sign(yc(idx)) + epsilon*sign(yc(idx));
      %           e = epsilon*sign(yc(idx));
      %        ```
      %  Default epsilon value is 1e-3
      %
      % yn = (y - o)./s;
      % y  = yn.*s + o;
      
      epsilon = 1e-3; % Error term to ensure behavior of y as open interval      
      o = min(y);
      s = max(abs(y - o + epsilon)) + epsilon;
      
      yn = (y - o + epsilon) ./ s;
   end

end