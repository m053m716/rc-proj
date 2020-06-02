function [colorStruct, haxP, vaxP] = phaseSpace(Projection, Summary, params)
%PHASESPACE  For making publication quality rosette plots
% useage:
%       phaseSpace(Projection, Summary)
%       phaseSpace(Projection, Summary, params)
%
% You can limit the conditions you plot either by
%   1) including only some entries of Projection (e.g., Projection(1:2))
%   or 2) by using params.conds2plot to restrict (e.g., params.conds2plot = 1:2);
%   In the former case, scaling etc is based just on the passed points.
%   In the latter scaling is based on all the points.
%
% outputs are [colorStruct, hf, haxP, vaxP] = phaseSpace(Projection, Summary)
%
%   'colorStruct' is a structure (one per dataset) of cells of linecolors (one per condition)
%   that you might wish to pass to another function (e.g., one that plots the rosette PSTH's
%   or the hand trajectories).
%
%    'hf' is the fig#, 'haxP' and 'vaxP' are the axis parameters.
%
%   *** ALL of the outputs, except the last, pertain only the LAST graph plotted. ***
%
% rosetteData comes from multiRosetteScript
%
% params can have the following fields:
%       .times    These override the default times (those corresponding to scores; e.g., the orginal
%               times that were used to build the space.  If empty, the defaults are used.
%                 Note that zero is movement onset.  Thus .times will probably start strongly
%               negatively.
%                 Thus, you might pass it -1550:10:150 if you wanted to start way back at the
%               beginning.
%                 A nice feature is that only those times that match times in 'scoresExtraTime' are
%               used.  Thus, if you pass -100000:1000000 things will still work fine.
%               Scalings are based on all times in Projection.projAllTimes.  This is nice for movies
%               as the scaling won't change as a function of the times you plot.
%
%       .planes2plot   list of the jPC planes you want plotted.  Default is [1].  [1,2] would also be reasonable.
%
%       .arrowSize        The default is 5
%       .arrowGain        FOR MOVIES: sets velocity dependence of arrow size (0 to not grow when faster).
%       .plotPlanEllipse  Controls whether the ellipse is plotted.  The default is 'true'
%       .useAxes          whether axes should be plotted.  Default is 'true'
%       .useLabel         whether to label with dataset. Default is 'true'
%       .planMarkerSize   size of the plan dot.  Default is 6.
%       .lineWidth        width of the trajectories.  Default is 0.85.
%       .arrowMinVel      minimum velocity for plotting an arrow.
%       .rankType         default is 'eig', but you can override with 'varCapt'.  The first plane will
%                         then be the jPC plane that captured the most variance (often associated with the
%                         largest eigenvalue but not always
%       .conds2plot       which conditions to plot (scalings will still be based on all the conds in 'Projection')
%       .substRawPCs      use PC projections rather than jPC projections
%       .crossCondMean    if present and == 1, plot the cross condition mean in cyan.
%       .reusePlot        if present and == 1, do cla then reuse the plot
%       .dataRanges       normally this is set automatically, but you can decide yourself what the
%                         range should be.  You should supply one entry per plane to be plotted.  You can also supply
%                         just the first, and then the defaults will be used after that.

if nargin < 3
   params = struct;
end

TOL = 1e-4; % tolerance for matching time values

% some basic parameters
axLimScale = 1.05;
axisSeparation = 0.20;  % separated by 20% of the maximum excursion (may need more if plotting future times, which aren't used to compute farthestLeft or farthestDown)

numPlanes = length(Summary.varCaptEachPlane);  % total number of planes provided (may only plot a subset)

% set defaults and override if 'params' is included as an argument

% allows for the use of times other than the original ones that correspond to 'scores' (those that
% were used to create the projection and do the analysis)
overrideTimes = [];
if isfield(params,'times')
   overrideTimes = params.times;
end

arrowSize = 5;
if isfield(params,'arrowSize')
   arrowSize = params.arrowSize;
end

arrowGain = 0;
if isfield(params,'arrowGain')
   arrowGain = params.arrowGain;
end

% Default is we plot the ellipse if we have 6 or more conditions
% NOTE: we still plot it even if asked to only plot one cond, so long as we HAVE more than 6 to
% build the ellipse off.  It matters whether length(Projection) >= 6, not whether conds2plot >= 6
if length(Projection) >= 6
   plotPlanEllipse = true;
else
   plotPlanEllipse = false;
   axLimScale = 1.3*axLimScale;
end
if isfield(params,'plotPlanEllipse')
   plotPlanEllipse = params.plotPlanEllipse;
end

useAxes = true;
if isfield(params,'useAxes')
   useAxes = params.useAxes;
end

useLabel = true;
if isfield(params,'useLabel')
   useLabel = params.useLabel;
end

planMarkerSize = 0;
if isfield(params,'planMarkerSize')
   planMarkerSize = params.planMarkerSize;
end

lineWidth = 0.85;
if isfield(params,'lineWidth')
   lineWidth = params.lineWidth;
end

arrowAlpha = 0.275;
if isfield(params,'arrowAlpha')
   arrowAlpha = params.arrowAlpha;
end

tailAlpha = 0.35;
if isfield(params,'tailAlpha')
   tailAlpha = params.tailAlpha;
end

arrowMinVel = [];
if isfield(params,'arrowMinVel')
   arrowMinVel = params.arrowMinVel;
end

minAvgDP = 0.5;
if isfield(params,'minAvgDP')
   minAvgDP = params.minAvgDP;
end

planes2plot = 1;  % this is a list of which planes to plot
if isfield(params,'planes2plot')
   planes2plot = params.planes2plot;
end

rankType = 'eig';
if isfield(params,'rankType')
   rankType = params.rankType;
end

reusePlot = 0;
if isfield(params,'reusePlot')
   reusePlot = params.reusePlot;
end
if length(planes2plot) > 1, reusePlot = 0; end  % cant reuse if we are plotting more than one thing.

numTrials = numel(Projection);
trials2plot = 1:numTrials;
if isfield(params,'trials2plot')
   if ~strcmp(params.trials2plot,'all')
      trials2plot = params.trials2plot;
      numTrials = numel(trials2plot);
   end
end

if params.useConditionLabels
   if isfield(Projections,'conditionLabels')
      params.conditionLabels = vertcat(Projections.conditionLabels);
   end
end

% If asked, substitue the raw PC projections.
substRawPCs = 0;
if isfield(params,'substRawPCs') && params.substRawPCs
   substRawPCs = 1;
   % just overwrite
   for c = 1:numTrials
      Projection(c).proj = Projection(c).tradPCAproj;
      Projection(c).projAllTimes = Projection(c).tradPCAprojAllTimes;
   end
   Summary.varCaptEachPlane = sum(reshape(Summary.varCaptEachPC,2,numPlanes));
end

use_orth = false;
if isfield(params,'use_orth')
   use_orth = params.use_orth;
   if use_orth
      for c = 1:numTrials
         Projection(c).proj = Projection(c).proj_orth;
         Projection(c).projAllTimes = Projection(c).projAllTimes_orth;
      end
      Summary.varCaptEachPlane = Summary.varCaptEachPlane_orth;
   end
end

if strcmp(rankType, 'varCapt')  && substRawPCs == 0  % we WONT reorder if they were PCs
   [~, sortIndices] = sort(Summary.varCaptEachPlane,'descend');
   planes2plot_Orig = planes2plot;  % keep this so we can label the plane appropriately
   planes2plot = sortIndices(planes2plot);  % get the asked for planes, but by var accounted for rather than eigenvalue
end

% the range of the data will set the size of the plot unless you manually override
dataRanges = max(abs(vertcat(Projection.proj)));
dataRanges = max(reshape(dataRanges,2,numPlanes));  % one range per plane

if isfield(params,'dataRanges')
   for i = 1:length(params.dataRanges)
      dataRanges(i) = params.dataRanges(i);  % only override those values that are specified
   end
end

if numTrials < 5
   fprintf(1,'Only %g trials for this dataset. skipping.\n',numTrials);
   colorStruct = [];
   haxP = [];
   vaxP = [];
   return;
end

arrowEdgeColor = 'k';
if isfield(params,'arrowEdgeColor')
   arrowEdgeColor = params.arrowEdgeColor;
end

for pindex = 1:length(planes2plot)
   % get some useful indices
   plane = planes2plot(pindex);  % which plane to plot
   d2 = 2*plane;  % indices into the dimensions
   d1 = d2-1;
   
   phaseData = analyze.jPCA.getPhase(Projection,plane);
   
   % set the limits of the figure
   axLim = axLimScale * dataRanges(plane) * [-1 1 -1 1];
   planData = nan(numTrials,2);
   idx = 0;
   for c = trials2plot
      idx = idx + 1;
      % Always taken from the 1st element (NOT the first that will be plotted)
      % This way the ellipse doesn't depend on which times you choose to plot
      planData(idx,:) = Projection(c).proj(1,[d1,d2]);
   end
   
   % need this for ellipse plotting
   ellipseRadii = std(planData,[],1);  % we may plot an ellipse for the plan activity
   mu = nanmean(planData,1);
   R = nancov(planData);
   theta_rot = atan2(sqrt(sum(R(:,2).^2)),sqrt(sum(R(:,1).^2)));
   
   % these will be altered further below based on how far the data extends left and down
   farthestLeft = mu(1)-ellipseRadii(1)*5;  % used figure out how far the axes need to be offset
   farthestDown = mu(2)-ellipseRadii(2)*5;  % used figure out how far the axes need to be offset
   
   
   % deal with the color scheme
   
   % ** colors graded based on PLAN STATE
   % These do NOT depend on which times you choose to plot (only on which time is first in Projection.proj).
   
   if isnan(params.conditionLabels(1))
      htmp = redbluecmap(numTrials, 'interpolation', 'linear');
      [~,newColorIndices] = sort(planData(:,1));
      
      htmp(newColorIndices,:) = htmp;
      
      for c = 1:numTrials  % cycle through conditions, and assign that condition's color
         lineColor{c} = htmp(c,:); %#ok<*AGROW>
         arrowFaceColor{c} = htmp(c,:);
         planMarkerColor{c} = htmp(c,:);
      end
   else
      if numel(unique(params.conditionLabels)) > 2
         [u,~,iC] = unique(params.conditionLabels);
         htmp = redbluecmap(numel(u), 'interpolation', 'sigmoid');
         htmpIdx = fliplr(round(linspace(1,size(htmp,1),numel(u))));
         htmp = htmp(htmpIdx,:);
      else
         iC = params.conditionLabels;
         htmp = [0.6 0.6 0.6;
            0.4 0.4 1.0];
         
      end
      
      for c = 1:numTrials  % cycle through conditions, and assign that condition's color
         lineColor{c} = htmp(iC(c),:);
         arrowFaceColor{c} = htmp(iC(c),:);
         planMarkerColor{c} = htmp(iC(c),:);
      end
   end
   
   % override colors if asked
   if isfield(params,'colors')
      lineColor = params.colors;
      arrowFaceColor = params.colors;
      planMarkerColor = params.colors;
   end
   
   colorStruct(pindex).colors = lineColor;
   
   % Plot the rosette itself
   if reusePlot == 0
      [~,axLim] = analyze.jPCA.blankFigure(axLim);
   else
      cla;
   end
   
   % first deal with the ellipse for the plan variance (we want this under the rest of the data)
   if plotPlanEllipse
      analyze.jPCA.circle(ellipseRadii,theta_rot,mu);
   end
   
   % cycle through conditions
   for c = numTrials:-1:1
      if abs(phaseData(c).wAvgDPWithPiOver2) <= minAvgDP
         continue;
      end
      
      
      if isempty(overrideTimes)  % if we are going with the original times (those that were used to create the projection and do the analysis)
         P1 = Projection(c).proj(:,d1);
         P2 = Projection(c).proj(:,d2);
         t = (1:numel(P1));
      else
         useTimes = ismembertol(Projection(c).allTimes, overrideTimes,TOL);
         t = Projection(c).allTimes(useTimes).';
         P1 = Projection(c).projAllTimes(useTimes,d1).';
         P2 = Projection(c).projAllTimes(useTimes,d2).';
      end
      
      if (numel(P1) < 2) || (numel(P2) < 2)
         str = repmat('->\t%6.7g\n',1,numel(overrideTimes));
         fprintf(1,['Could not find matches for:\n' str],overrideTimes);
         continue;
      end
      
      if ismember(c,trials2plot)
         if isnan(tailAlpha)
            tailAlphaThis = compute_tail_alpha(params,c);
         else
            tailAlphaThis = tailAlpha;
         end
         surface([P1;P1],[P2;P2],zeros(2,numel(P1)),[t;t],...
            'facecol','no',...
            'EdgeColor',lineColor{c},...
            'EdgeAlpha',tailAlphaThis,...
            'linew',1.5);
         
         if planMarkerSize>0
            plot(P1(1), P2(1), 'ko', 'markerSize',...
               planMarkerSize, 'markerFaceColor',...
               planMarkerColor{c});
         end
         
         % for arrow, figure out last two points, and (if asked) supress the arrow if velocity is
         % below a threshold.
         penultimatePoint = [P1(end-1), P2(end-1)];
         lastPoint = [P1(end), P2(end)];
         vel = norm(lastPoint - penultimatePoint);
         if isempty(arrowMinVel) || vel > arrowMinVel
            aSize = arrowSize + arrowGain * vel;  % if asked (e.g. for movies) arrow size may grow with vel
            if isnan(arrowAlpha)
               arrowAlphaThis = compute_tail_alpha(params,c);
            else
               arrowAlphaThis = arrowAlpha;
            end
            analyze.jPCA.arrowMMC(penultimatePoint, lastPoint, [], ...
               aSize, axLim, ...
               arrowFaceColor{c}, arrowEdgeColor, arrowAlphaThis);
         else
            plot(lastPoint(1), lastPoint(2), 'ko', 'markerSize',...
               arrowSize, 'markerFaceColor', arrowFaceColor{c},...
               'markerEdge', 'none');
         end
      end
      
      % axis locations will be based on the original set of times used to make the scores
      % and not on the actual times used.  Here we get the leftmost and bottommost point
      if isfield(Projection, 'projAllTimes')
         farthestLeft = min(farthestLeft, min(Projection(c).projAllTimes(:,d1)));
         farthestDown = min(farthestDown, min(Projection(c).projAllTimes(:,d2)));
      else
         farthestLeft = min(farthestLeft, min(Projection(c).proj(:,d1)));
         farthestDown = min(farthestDown, min(Projection(c).proj(:,d2)));
      end
   end
   
   plot(0,0,'b+', 'markerSi', 7.5);  % plot a central cross
   
   
   % if asked we will also plot the cross condition mean
   if params.crossCondMean && length(Summary.crossCondMean) > 1
      meanColor = [1 1 1];
      
      if isempty(overrideTimes)  % if we are going with the original times (those that were used to create the projection and do the analysis)
         P1 = Summary.crossCondMean(:,d1);
         P2 = Summary.crossCondMean(:,d2);
      else
         useTimes = ismembertol(Projection(c).allTimes, overrideTimes,TOL);
         P1 = Summary.crossCondMeanAllTimes(useTimes,d1);
         P2 = Summary.crossCondMeanAllTimes(useTimes,d2);
      end
      
      if (numel(P1) < 2) || (numel(P2) < 2)
         str = repmat('->\t%6.7g\n',1,numel(overrideTimes));
         fprintf(1,['Could not find matches for:\n' str],overrideTimes);
         continue;
      end
      
      plot(P1, P2, 'color', meanColor, 'lineWidth', 2*lineWidth);  % make slightly thicker than for rest of data.
      if planMarkerSize>0
         plot(P1(1), P2(1), 'ko', 'markerSize', planMarkerSize, 'markerFaceColor', meanColor);
      end
      
      % for arrow, figure out last two points, and (if asked) supress the arrow if velocity is
      % below a threshold.
      penultimatePoint = [P1(end-1), P2(end-1)];
      lastPoint = [P1(end), P2(end)];
      vel = norm(lastPoint - penultimatePoint);
      
      aSize = arrowSize*1.5 + arrowGain * vel;  % if asked (e.g. for movies) arrow size may grow with vel
      analyze.jPCA.arrowMMC(penultimatePoint, lastPoint, [], aSize, axLim, meanColor, meanColor, 1);
      
   end
   
   % make axes
   if isempty(params.phaseSpaceAx)
      extraSeparation = axisSeparation*(min(farthestDown,farthestLeft));
      
      % general axis parameters
      axisParams.tickLocations = [-axLim(plane), 0, axLim(plane)];
      %       axisParams.tickLocations = [-axisLength, 0, axisLength];
      axisParams.longTicks = 0;
      axisParams.fontSize = 10.5;
      
      % horizontal axis
      axisParams.axisOffset = farthestDown + extraSeparation;
      axisParams.axisLabel = 'projection onto jPC_1 (a.u.)';
      axisParams.axisOrientation = 'h';
      haxP = analyze.jPCA.AxisMMC(axLim(1),axLim(2),axisParams);
      
      % vertical axis
      axisParams.axisOffset = farthestLeft + extraSeparation;
      axisParams.axisLabel = 'projection onto jPC_2 (a.u.)';
      axisParams.axisOrientation = 'v';
      axisParams.axisLabelOffset = 1.9*haxP.axisLabelOffset;
      vaxP = analyze.jPCA.AxisMMC(axLim(3),axLim(4),...
         axisParams);
   end

   if substRawPCs == 1
      titleText = sprintf('raw PCA plane %d', plane);
   elseif strcmp(rankType, 'varCapt')
      letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      titleText = sprintf('jPCA plane %s (var capt ranked)', letters(planes2plot_Orig(pindex)));
   else
      titleText = sprintf('jPCA plane %d (eigval ranked)', plane);
   end
   titleText2 = sprintf('%d%% of var captured', round(100*Summary.varCaptEachPlane(plane)));
   text(0,0.99*axLim(4),titleText, 'horizo', 'center');
   text(0,0.88*axLim(4),titleText2, 'horizo', 'center', 'fontSize', 8.5);

end  % done looping through planes

   function alpha = compute_tail_alpha(params,c)
      %COMPUTE_TAIL_ALPHA Return tail-alpha based on condition/index
      %
      %  alpha = compute_tail_alpha(params,c);
      
      alpha = max(min((-tansig(sum(params.conditionLabels==params.conditionLabels(c))/numel(params.conditionLabels))+1)/2,0.8),0.2);
   end

end  % end of the main function




