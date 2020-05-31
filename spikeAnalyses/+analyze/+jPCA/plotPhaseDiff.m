function circStatsSummary = plotPhaseDiff(phaseData, jPCplane,params)
%PLOTPHASEDIFF  Plots histogram of angle between dx(t)/dt and x(t) 
%
%  circStatsSummary = analyze.jPCA.plotPhaseDiff(phaseData,jPCplane,params)
%
%  --------
%   INPUTS
%  --------
%  phaseData      :     Data struct output from JPCA.GETPHASE.
%
%  jPCplane       :     Index of jPCplane to plot. Default is 1.
%
%  params       :     (Optional) Struct with field `suppressHistograms`. 
%                       Default is true for this field if not provided.
%                       If false, will plot the histograms. If no
%                       output argument is supplied, default is false 
%                       (otherwise why run this function)

% PARSE INPUT
if nargin < 2
   jPCplane = 1; % If not specified, assume it is the main plane
end

if nargin < 3 % If parameters struct not specified, suppress histograms
   params = defaults.jPCA('jpca_params');
   if nargout < 1
      params.suppressHistograms = false;
   else
      params.suppressHistograms = true;
   end
end

% compute the circular mean of the data, weighted by the r's
circMn = analyze.jPCA.CircStat2010d.circ_mean([phaseData.phaseDiff]', [phaseData.radius]');
resultantVect = analyze.jPCA.CircStat2010d.circ_r([phaseData.phaseDiff]', [phaseData.radius]');
stats = analyze.jPCA.CircStat2010d.circ_stats([phaseData.phaseDiff]',[phaseData.radius]');

cnts = histcounts([phaseData.phaseDiff], params.histBins);  % not for plotting, but for passing back out
nBin = numel(params.histBins)-1;
% If data is perfectly uniform, then yMax will be total number of sample
% points divided by total number of bins. It will probably not be totally
% uniform. Also, we don't really want the data to go all the way up to the
% top of the y-axis, so that's where the factor of 5 comes in (still not
% perfect).
yMax = round(numel([phaseData.phaseDiff])/(nBin/5)); 
yMax = ceil(yMax/100) * 100;
binCenters = (params.histBins(1:end-1) + params.histBins(2:end))/2;

xTick = [-pi -pi/2 0 pi/2 pi];
iMatch = ismembertol(xTick,circMn,0.05); % Don't want labels too close

[xTick,xIdx] = sort([xTick(~iMatch) circMn],'ascend');
xTickLabel = {'-\pi','\color{blue} -\pi/2','0','\color{blue} \pi/2','\pi'};
circMnLab = ['\color{red} ' num2str(circMn,'%3.2f')];
xTickLabel = [xTickLabel(~iMatch), circMnLab];
xTickLabel = xTickLabel(xIdx);

% do this unless params contains a field 'params.suppressHistograms' that is true
if ~params.suppressHistograms
   fig = figure(...
      'Name',sprintf('dPhase Distribution: jPCA plane %d',jPCplane),...
      'Units','Normalized',...
      'Position',[0.15 + 0.15*(jPCplane-1),...
      0.55 + 0.025*randn,...
      0.2, 0.3],...
      'Color','w');
   ax = axes(fig,...
      'XLim',[-pi pi],...
      'YLim',[0 yMax],...
      'NextPlot','add',...
      'LineWidth',1.5,...
      'XColor','k',...
      'FontName','Arial',...
      'FontSize',12,...
      'FontWeight','bold',...
      'XTick',xTick,...
      'XTickLabel',xTickLabel,...
      'YAxisLocation','origin',...
      'YColor','k',...
      'TickDir','both');
      
   bar(ax,binCenters,cnts,1,...
      'EdgeColor','none',...
      'FaceColor','k',...
      'DisplayName','Distribution of Phases'); 
   line(ax,[-pi/2 -pi/2 nan pi/2 pi/2], [0 yMax nan 0 yMax], ...
      'LineStyle','--',...
      'LineWidth',2,...
      'MarkerFaceColor','b', ...
      'MarkerSize', 8,...
      'DisplayName','Pure Rotations');
   line(ax,[circMn,circMn],[0 yMax], ...
      'LineStyle',':',...
      'LineWidth',1.5,...
      'Color','w',...
      'Marker','v',...
      'MarkerIndices',1,...
      'MarkerFaceColor', 'r', ...
      'MarkerSize', 8,...
      'DisplayName','Average Phase');
   title(ax,sprintf('Counts: Phase Angle (Plane-%d)', jPCplane),...
      'FontName','Arial',...
      'Color','k','FontWeight','bold');
   xlabel(ax,'Rotation Phase','FontName','Arial','Color','k');
end

%fprintf('(pi/2 is %1.2f) The circular mean (weighted) is %1.2f\n', pi/2, circMn);

% compute the average dot product of each datum (the angle difference for one time and condition)
% with pi/2.  Will be one for perfect rotations, and zero for random data or expansions /
% contractions.
avgDP = analyze.jPCA.averageDotProduct([phaseData.phaseDiff]', pi/2);
%fprintf('the average dot product with pi/2 is %1.4f  <<---------------\n', avgDP);

circStatsSummary.stats = stats;
circStatsSummary.circMn = circMn;
circStatsSummary.resultantVect = resultantVect;
circStatsSummary.avgDPwithPiOver2 = avgDP;  % note this basically cant be <0 and definitely cant be >1
circStatsSummary.DISTRIBUTION.bins = params.histBins;
circStatsSummary.DISTRIBUTION.binCenters = binCenters;
circStatsSummary.DISTRIBUTION.counts = cnts(1:end-1);
circStatsSummary.RAW.rawData = [phaseData.phaseDiff]';
circStatsSummary.RAW.rawRadii = [phaseData.radius]';
circStatsSummary.plane = jPCplane;

end