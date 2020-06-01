function fig = plotRosette(Proj,p)
%PLOTROSETTE  Plot the rosette (lines with arrows) itself
%
%  fig = analyze.jPCA.plotRosette(Proj,p);
%
% Inputs
%  Proj        - Matrix where rows are time steps and columns are each
%                       jPC or PC projection. 
%  p           - (Optional) Parameters struct with following fields:
%
%     * `WhichPair` - Specifies which plane to look at
%     * `VarCapt`   - Specifies percent (0 to 1) of variance captured by
%                       this plane
%     * `XLim`      - Axes x-limits
%     * `YLim`      - Axes y-limites
%     * `FontName`  - Name of font ('Arial')
%     * `FontSize`  - Size of text labels (16-pt)
%     * `FontWeight`- 'bold' (default) or 'normal'
%     * `Figure`    - Figure handle (default is empty)
%     * `Axes`      - Axes handle (default is empty)
%
% Output
%  fig         - Figure handle 

if nargin < 2
   p = defaults.jPCA('rosette_params');
end

% Port old variable names from previous syntax:
whichPair = p.WhichPair;
vc = p.VarCapt; 

d1 = 1 + 2*(whichPair-1);
d2 = d1+1;

numConds = length(Proj);

if isempty(p.Figure)
   fig = figure(...
      'Name',sprintf(p.FigureNameExpr,whichPair),...
      'Units',p.FigureUnits,...
      'Position',p.FigurePosition,...
      'Color',p.FigureColor...
      );
else
   fig = p.Figure;
end

if isempty(p.Axes)
   p.Axes = axes(fig,...
      'XColor',p.XColor,...
      'YColor',p.YColor,...
      'XLim',p.XLim,...
      'YLim',p.YLim,...
      'LineWidth',p.AxesLineWidth...
      );
end
p.Arrow.Axes = p.Axes;

% first deal with the ellipse for the plan variance (we want this under the rest of the data)
planData = zeros(numConds,2);
for c = 1:numConds
   planData(c,:) = Proj(c).proj(Proj(c).planStateIndex,[d1,d2]);
end
mu = nanmean(planData,1);
R = nancov(planData);
rad = sqrt([R(1,1), R(2,2)]);
yr = sqrt(sum(R(:,2).^2));
xr = sqrt(sum(R(:,1).^2));
if ~isreal(yr) || ~isreal(xr)
   theta_rot = 0;
else
   theta_rot = atan2(yr,xr);
end
analyze.jPCA.circle(rad,theta_rot,mu); hold on;
%fprintf('ratio of plan variances = %1.3f (hor var / vert var)\n', planVars(1)/planVars(2));

% allD = vertcat(Proj(:).proj);  % just for getting axes
% allD = allD(:,d1:d2);
% mxVal = max(abs(allD(:)));
% axLim = mxVal*1.05*[-1 1 -1 1];

cm = struct;
iSuccess = [Proj.Condition]==2;
if any(iSuccess)
   cm.Success.map = getColorMap(sum(iSuccess),'green');
   cm.Success.cur = 1;
end
iSuccess = [Proj.Condition]==1;
if any(iSuccess)
   cm.Fail.map = getColorMap(sum(iSuccess),'blue');
   cm.Fail.cur = 1;
end
key = {'Fail','Success'};

for c = 1:numConds
   thisOutcome = key{Proj(c).Condition};
   line(p.Axes,Proj(c).proj(:,d1), Proj(c).proj(:,d2), ...
      'Color',cm.(thisOutcome).map(cm.(thisOutcome).cur,:),...
      'LineWidth',p.LineWidth,...
      'MarkerIndices',Proj(c).planStateIndex,....
      'Marker','o',...
      'MarkerFaceColor',p.PlanStateColor);
   penultimatePoint = [Proj(c).proj(end-1,d1), Proj(c).proj(end-1,d2)];
   lastPoint = [Proj(c).proj(end,d1), Proj(c).proj(end,d2)];

   cm.(thisOutcome).cur = cm.(thisOutcome).cur + 1;
   if isreal(penultimatePoint) && isreal(lastPoint)
      analyze.jPCA.arrowMMC(penultimatePoint, lastPoint, p);
   end
   
end

line(p.Axes,0,0,...
   'LineStyle','none',...
   'Marker','+',...
   'Color','k',...
   'LineWidth',p.AxesLineWidth,...
   'DisplayName','Origin');

fontColor = [max(1 - 6*vc,0), max(min(10*vc - 1, 0.75),0), 0.15];

tx_v = sprintf('%02.3g%%',vc*100);

xVPos = p.XLim(2) - 0.95 *(p.XLim(2) - p.XLim(1));
yVPos = p.YLim(2) - 0.15 *(p.YLim(2) - p.YLim(1));
text(p.Axes,xVPos,yVPos, tx_v,...
   'FontSize',p.FontSize,...
   'FontName',p.FontName,...
   'FontWeight',p.FontWeight,...
   'Color',fontColor);
title(p.Axes,sprintf(p.AxesTitleExpr, whichPair));
end