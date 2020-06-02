function [circStatsSummary,fig] = plotPhaseDiff(phaseData,jPCplane,params)
%PLOTPHASEDIFF  Plots histogram of angle between dx(t)/dt and x(t) 
%
% Use
%  circStatsSummary = analyze.jPCA.plotPhaseDiff(phaseData,jPCplane,params)
%  [circStatsSummary,fig] = ...
%
% Inputs
%  phaseData - Data struct output from JPCA.GETPHASE.
%  jPCplane  - Index of jPCplane to plot. Default is 1.
%  params    - (Optional) Struct with field `suppressHistograms`. 
%                 Default is true for this field if not provided.
%                 If false, will plot the histograms. If no
%                 output argument is supplied, default is false 
%                 (otherwise why run this function)
%
% Output
%  circStatsSummary - Information struct or cell array of structs
%                       containing summary circle-statistics for the data
%                       presented in output bar graphs.
%  fig              - Figure handle to figure containing the bar graph

% PARSE INPUT
if nargin < 3 % If parameters struct not specified, suppress histograms
   params = defaults.jPCA('jpca_params');
   if nargout < 1
      params.suppressHistograms = false;
   else
      params.suppressHistograms = true;
   end
end

if nargin < 2
   if iscell(phaseData)
      circStatSummary = cell(1,numel(phaseData));
      for jPCplane = numel(phaseData):-1:1
         circStatSummary{jPCplane} = analyze.jPCA.plotPhaseDiff(...
            phaseData{jPCplane},jPCplane,params);
      end
      return;
   else
      jPCplane = 1; % If not specified, assume it is the main plane
   end
elseif iscell(phaseData)
   if numel(jPCplane) > 1
      circStatSummary = cell(1,max(jPCplane));
      for iPlane = 1:numel(jPCplane)
         circStatSummary{1,jPCplane} = analyze.jPCA.plotPhaseDiff(...
            phaseData{jPCplane(iPlane)},jPCplane(iPlane),params);
      end
      return;
   else
      phaseData = phaseData{jPCplane};
   end
end

% compute the circular mean of the data, weighted by the r's
pdMain = [phaseData.phaseDiff];
pdAll = [pdMain.All];
circMn = analyze.jPCA.CircStat2010d.circ_mean([pdAll.delta]', [phaseData.radius]');
resultantVect = analyze.jPCA.CircStat2010d.circ_r([pdAll.delta]', [phaseData.radius]');
stats = analyze.jPCA.CircStat2010d.circ_stats([pdAll.delta]',[phaseData.radius]');


cnts = histcounts([pdAll.delta], params.histBins);  % not for plotting, but for passing back out
nBin = numel(params.histBins)-1;

S = setdiff(fieldnames(pdMain),{'All'});
Y = nan(numel(S),nBin);
nMax = 0;
for iS = 1:numel(S)
   pdThis = [pdMain.(S{iS})];
   Y(iS,:) = histcounts([pdThis.delta],params.histBins);
   nMax = nMax + numel([pdThis.delta]); 
end
CData = [params.ReachStateColor; ...
         params.GraspStateColor; ...
         params.SupportStateColor; ...
         params.CompleteStateColor];

% If data is perfectly uniform, then yMax will be total number of sample
% points divided by total number of bins. It will probably not be totally
% uniform. Also, we don't really want the data to go all the way up to the
% top of the y-axis, so that's where the factor of 5 comes in (still not
% perfect).
yMax = round(nMax/(nBin/5)); 
yMax = ceil(yMax/100) * 100;
binCenters = (params.histBins(1:end-1) + params.histBins(2:end))/2;

xTick = [-pi -pi/2 0 pi/2 pi];
iMatch = ismembertol(xTick,circMn,params.min_phase_axes_tick_spacing); % Don't want labels too close

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
      'Position',params.FigurePosition,...
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
      'ColorOrder',CData,...
      'TickDir','both');
   h = bar(ax,binCenters,Y,1,...
      'stacked',...
      'EdgeColor','none',...
      'FaceColor','flat'); 
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
   legend(h,S,'Location','northwest',...
      'FontName','Arial','TextColor','black');
   title(ax,sprintf('Counts: Phase Angle (Plane-%d)', jPCplane),...
      'FontName','Arial',...
      'Color','k','FontWeight','bold');
   xlabel(ax,'Rotation Phase','FontName','Arial','Color','k');
else
   fig = []; % Otherwise return as empty
end
% Compute the average dot product of each datum (the angle difference for 
% one time and condition) with pi/2.  
% --> This quantity will be one for perfect rotations, and zero for random 
%     data or expansions / contractions.
avgDP = analyze.jPCA.averageDotProduct([pdAll.delta]', pi/2);
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