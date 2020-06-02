function [fig,Proj] = plotRosette(Proj,p)
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
%  Proj        - Input data array with additional zero offset (traj_offset)
%                 field if that was done for visualization

if nargin < 2
   p = defaults.jPCA('rosette_params');
end

% Port old variable names from previous syntax:
whichPair = p.WhichPair;
vc = p.VarCapt; 

d1 = 1 + 2*(whichPair-1);
d2 = d1+1;

numConds = length(Proj);


% % If zero-centering about some index, do that now % % 
if p.zeroCenters
   % Check if there is a zeroTime
   if ischar(p.zeroTime)
      tField = [lower(p.zeroTime) 'Index'];
      zIndx = max([Proj.(tField)] - p.zeroTimeOffset,1);
   elseif ~isnan(p.zeroTime)
      [~,zIndx] = min(abs(Data(1).times-p.zeroTime));
      zIndx = zIndx(1); % If multiple closest, use first
   else
      zIndx = 1; % Otherwise it's just the first sample index
   end
   
   % Iterate, applying this to all trials.
%    f = {'proj'};
   if numel(zIndx) > 1
%       fcn = @(pro,iZero)analyze.jPCA.zeroCenterPoints(pro,iZero,f,f);
      fcn = @(pro,iZero)analyze.jPCA.zeroCenterPoints(pro,iZero);
      Proj= arrayfun(fcn,Proj,zIndx);
   else
%       fcn = @(pro)analyze.jPCA.zeroCenterPoints(pro,zIndx,f,f);
      fcn = @(pro)analyze.jPCA.zeroCenterPoints(pro,zIndx);
      Proj = arrayfun(fcn,Proj);
   end
end

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
      'XLimMode','manual',...
      'XLim',p.XLim,...
      'YLimMode','manual',...
      'YLim',p.YLim,...
      'LineWidth',p.AxesLineWidth,...
      'NextPlot','add'...
      );
end
p.Arrow.Axes = p.Axes;

% Add the ellipse that indicates variance at time of Reach onset
%  (We want this to be layered "under" the rest of the data)
reachData = zeros(numConds,2);
for c = 1:numConds
   reachData(c,:) = Proj(c).proj(Proj(c).reachIndex,[d1,d2]);
end
mu = nanmean(reachData,1);
R = nancov(reachData);
rad = sqrt([R(1,1), R(2,2)]);
yr = sqrt(sum(R(:,2).^2));
xr = sqrt(sum(R(:,1).^2));
if ~isreal(yr) || ~isreal(xr)
   theta_rot = 0;
else
   theta_rot = atan2(yr,xr);
end
circParams = getCircleParams(p,rad,theta_rot,mu);
analyze.jPCA.circle(circParams);

% Create color map scheme
cm = struct;
iSuccess = [Proj.Condition]==2;
if any(iSuccess)
   cm.Success.map = getColorMap(sum(iSuccess),'green');
   cm.Success.cur = 1;
end
iSuccess = [Proj.Condition]==1;
if any(iSuccess)
   cm.Fail.map = getColorMap(sum(iSuccess),'red');
   cm.Fail.cur = 1;
end
key = {'Fail','Success'};

for c = 1:numConds
   % Get information for this trial (convenience)
   thisOutcome = key{Proj(c).Condition};
   data = Proj(c).proj(:,[d1,d2]);
   nPt = size(data,1);
   
   gi = Proj(c).graspIndex;
   ci = Proj(c).completeIndex;
   ri = Proj(c).reachIndex;
   si = Proj(c).supportIndex;
   thisCol = cm.(thisOutcome).map(cm.(thisOutcome).cur,:);
   
   % Create group for graphics objects indicating different "states"
   hg = hggroup(p.Axes,'DisplayName',Proj(c).Trial_ID);
   p.Arrow.Group = hg;
   % Use line primitive objects since they are small:
   h = line(hg,data(1:ri,1),data(1:ri,2),...
      'Color',thisCol,...
      'LineStyle','--',...
      'LineWidth',0.5,...
      'Tag','Lead-Up');
   h.Annotation.LegendInformation.IconDisplayStyle = 'off';
   h = line(hg,data(ri:ci,1),data(ri:ci,2), ...
      'Color',thisCol,...
      'LineStyle','-',...
      'LineWidth',p.LineWidth,...
      'Tag','Reach');
   h.Annotation.LegendInformation.IconDisplayStyle = 'off';
   addArrow(data,ri,p.Arrow,p.ReachStateColor);
   addArrow(data,gi,p.Arrow,p.GraspStateColor);
   h = line(hg,data(ci:nPt,1),data(ci:nPt,2),...
      'Color',thisCol,...
      'LineWidth',0.75,...
      'LineStyle',':',...
      'Tag','Excess');
   h.Annotation.LegendInformation.IconDisplayStyle = 'off';
   addArrow(data,ci,p.Arrow,p.CompleteStateColor);
   if ~isnan(si)
      addArrow(data,si,p.Arrow,p.SupportStateColor);
   end
   % Add "final" data arrow
   addArrow(data,nPt,p.Arrow);

   hg.Annotation.LegendInformation.IconDisplayStyle = 'on';
   
   % Update colormap indexing
   cm.(thisOutcome).cur = cm.(thisOutcome).cur + 1;
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

   function h = addArrow(data,iArrow,arrowParams,col)
      %ADDARROW Add arrow based on data to axes in `arrowParams`
      %
      %  h = addArrow(data,iArrow,arrowParams);
      %  h = addArrow(data,iArrow,arrowParams,col);
      %
      %  Inputs
      %     data - Data matrix for a single trial
      %     iArrow - Index (time-sample) to add the arrow to
      %     arrowParams - Parameters struct (main parameters `.Arrow`
      %                    field)
      %     col - (Optional) face color for arrow
      %
      %  Output
      %   h - Fill object that is the arrow
      
      if nargin < 4
         col = [0.85 0.85 0.85];
      end
      arrowParams.FaceColor = col;
      
      iPre = max(iArrow-1,1);
      penultimatePoint = [data(iPre,1), data(iPre,2)];
      lastPoint = [data(iArrow,1), data(iArrow,2)];
      d = sqrt(sum((lastPoint - penultimatePoint).^2)); % L2 distance
      arrowParams.Size = arrowParams.BaseSize + abs(10 * tansig(10*d)); 
      h = analyze.jPCA.arrowMMC(penultimatePoint, lastPoint,arrowParams);
   end

   function circParams = getCircleParams(p,rad,theta_rot,mu)
      %GETCIRCLEPARAMS Helper function to return circle parameters struct
      %
      % circParams = getCircleParams(p,rad,theta_rot,mu);
      %
      % Inputs
      %  p - Struct from `defaults.jPCA('rosette_params');`
      %  rad - Radius of circle (or radii if elipse)
      %  theta_rot - Rotation of ellipse
      %  mu - Center of circle or ellipse
      % Output
      %  circParams - Params struct for `analyze.jPCA.circle(circParams)`
      
      circParams = p.Circle;
      circParams.Axes = p.Axes;
      circParams.Radius = rad;
      circParams.Theta = theta_rot;
      circParams.Center = mu;
   end
end