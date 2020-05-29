function fig = plotRosette(Proj,whichPair,vc)
%PLOTROSETTE  Plot the rosette (lines with arrows) itself
%
%  fig = analyze.jPCA.plotRosette(Proj,whichPair,vc);
%
% Inputs
%  Proj        - Matrix where rows are time steps and columns are each
%                       jPC or PC projection. 
%
%  whichPair   - Specifies which plane to look at.
%
%  vc          - Percent (0 to 1) of variance captured by this plane.
%
% Output
%  fig         - Figure handle 

if nargin < 3
   vc = 0;
end

if nargin < 2
   whichPair = 1;
end

d1 = 1 + 2*(whichPair-1);
d2 = d1+1;

numConds = length(Proj);

fig = figure('Name',sprintf('Rosette: jPCA plane %d',whichPair),...
   'Units','Normalized',...
   'Position',[0.15 + 0.15*(whichPair-1) + 0.015*randn, ...
   0.25 + 0.075*randn,...
   0.2, 0.3],...
   'Color','w');

% first deal with the ellipse for the plan variance (we want this under the rest of the data)
planData = zeros(numConds,2);
for c = 1:numConds
   planData(c,:) = Proj(c).proj(1,[d1,d2]);
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

allD = vertcat(Proj(:).proj);  % just for getting axes


allD = allD(:,d1:d2);
mxVal = max(abs(allD(:)));
axLim = mxVal*1.05*[-1 1 -1 1];
arrowSize = 5;
for c = 1:numConds

   plot(Proj(c).proj(:,d1), Proj(c).proj(:,d2), 'k');
   plot(Proj(c).proj(1,d1), Proj(c).proj(1,d2), 'ko', 'markerFaceColor', [0.7 0.9 0.9]);
   penultimatePoint = [Proj(c).proj(end-1,d1), Proj(c).proj(end-1,d2)];
   lastPoint = [Proj(c).proj(end,d1), Proj(c).proj(end,d2)];

   
   if isreal(penultimatePoint) && isreal(lastPoint)
      analyze.jPCA.arrowMMC(penultimatePoint, lastPoint, [], arrowSize, axLim);
   end
   
end

axis(axLim);
axis square;
plot(0,0,'k+');

xl = get(gca,'XLim');
yl = get(gca,'YLim');

% xl = defaults.jPCA('rosette_xlim');
% yl = defaults.jPCA('rosette_ylim');
% xlim(xl);
% ylim(yl); % Just to standardize for comparison

fontColor = [max(1 - 6*vc,0), max(min(10*vc - 1, 0.75),0), 0.15];

tx_v = sprintf('%02.3g%%',vc*100);

xVPos = xl(2) - 0.95 *(xl(2) - xl(1));
yVPos = yl(2) - 0.15 *(yl(2) - yl(1));
text(gca,xVPos,yVPos, tx_v,...
   'FontSize',defaults.jPCA('rosette_fontsize'),...
   'FontName',defaults.jPCA('rosette_fontname'),...
   'FontWeight',defaults.jPCA('rosette_fontweight'),...
   'Color',fontColor);


title(sprintf('jPCA plane %d', whichPair));
end