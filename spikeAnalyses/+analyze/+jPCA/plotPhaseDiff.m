function circStatsSummary = plotPhaseDiff(phaseData, jPCplane,suppressHistograms)
%% PLOTPHASEDIFF  Plots histogram of angle between dx(t)/dt and x(t) 
%
%  circStatsSummary = PLOTPHASEDIFF(phaseData,jPCplane,params)
%
%  --------
%   INPUTS
%  --------
%  phaseData      :     Data struct output from JPCA.GETPHASE.
%
%  jPCplane       :     Index of jPCplane to plot. Default is 1.
%
%  suppressHistograms        :     (Optional) Default is true. If false,
%                                      will plot the histograms. If no
%                                      output argument is supplied, default
%                                      is false (otherwise why run this
%                                      function)

%% PARSE INPUT
if nargin < 2
   jPCplane = 1; % If not specified, assume it is the main plane
end

if nargin < 3 % If parameters struct not specified, suppress histograms
   if nargin < 1
      suppressHistograms = false;
   else
      suppressHistograms = true;
   end
end

%%
% compute the circular mean of the data, weighted by the r's
circMn = analyze.jPCA.CircStat2010d.circ_mean([phaseData.phaseDiff]', [phaseData.radius]');
resultantVect = analyze.jPCA.CircStat2010d.circ_r([phaseData.phaseDiff]', [phaseData.radius]');
stats = analyze.jPCA.CircStat2010d.circ_stats([phaseData.phaseDiff]',[phaseData.radius]');

bins = pi*(-1:0.1:1);
cnts = histc([phaseData.phaseDiff], bins);  % not for plotting, but for passing back out


% do this unless params contains a field 'suppressHistograms' that is true
if ~suppressHistograms
   figure('Name',sprintf('dPhase Distribution: jPCA plane %d',jPCplane),...
      'Units','Normalized',...
      'Position',[0.15 + 0.15*(jPCplane-1) + 0.015*randn,...
      0.55 + 0.075*randn,...
      0.2, 0.3],...
      'Color','w');
   hist([phaseData.phaseDiff], bins); hold on;
   plot(circMn, 20, 'ro', 'markerFa', 'r', 'markerSiz', 8);
   plot(pi/2*[-1 1], [0 0], 'ko', 'markerFa', 'r', 'markerSiz', 8);
   set(gca,'XLim',pi*[-1 1]);
   title(sprintf('jPCs plane %d', jPCplane));
   ylim([0 2000]);
end

%fprintf('(pi/2 is %1.2f) The circular mean (weighted) is %1.2f\n', pi/2, circMn);

% compute the average dot product of each datum (the angle difference for one time and condition)
% with pi/2.  Will be one for perfect rotations, and zero for random data or expansions /
% contractions.
avgDP = analyze.jPCA.averageDotProduct([phaseData.phaseDiff]', pi/2);
%fprintf('the average dot product with pi/2 is %1.4f  <<---------------\n', avgDP);

% w_avgDP = analyze.jPCA.averageDotProduct([phaseData.phaseDiff]',pi/2,[phaseData.radius]');

circStatsSummary.stats = stats;
circStatsSummary.circMn = circMn;
circStatsSummary.resultantVect = resultantVect;
circStatsSummary.avgDPwithPiOver2 = avgDP;  % note this basically cant be <0 and definitely cant be >1
% circStatsSummary.w_avgDPwithPiOver2 = w_avgDP;
circStatsSummary.DISTRIBUTION.bins = bins;
circStatsSummary.DISTRIBUTION.binCenters = (bins(1:end-1) + bins(2:end))/2;
circStatsSummary.DISTRIBUTION.counts = cnts(1:end-1);
circStatsSummary.RAW.rawData = [phaseData.phaseDiff]';
circStatsSummary.RAW.rawRadii = [phaseData.radius]';
circStatsSummary.plane = jPCplane;

end