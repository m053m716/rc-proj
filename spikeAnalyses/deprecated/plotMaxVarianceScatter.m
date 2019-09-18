function fig = plotMaxVarianceScatter(ratePkData,p)
%% PLOTMAXVARIANCESCATTER  Plot scatter of peak rates for each trial by time for every channel on every trial of every day.
%
%  fig = PLOTMAXVARIANCESCATTER(ratePkData,p);
%
%  --------
%   INPUTS
%  --------
%  ratePkData     :     Array output by GETMAXRATEBYDAY.
%
%    p            :     Params struct from GETMAXRATEBYDAY
%                          (defaults.MaxRateByDay)
%
%  --------
%   OUTPUT
%  --------
%    fig          :     Handle to 3D scatter where axes are time relative
%                          to reach; post-op day; and IFR @ peak closest to
%                          point of maximal variance.
%
% By: Max Murphy  v1.0  01/22/2019  Original version (R2017a)

%% LOAD/PARSE NECESSSARY VARIABLES
addpath('libs');
nBlock = numel(p.dayTracker{1});
idx = [[p.info.probe].',[p.info.channel].'];

load('hotcoldmap.mat','cm');
cmIdx = round(linspace(1,size(cm,1),nBlock)); %#ok<NODEF>

%% MAKE FIGURE

fig = figure('Name',sprintf(p.FIG_TITLE_STR,p.name),...
   'Units',p.FIG_UNITS,...
   'Color',p.FIG_COL,...
   'Position',p.FIG_POS);

% Get indices for plotting (colormap index; number of plot rows & cols)

nRow = floor(sqrt(size(idx,1)));
nCol = ceil(size(idx,1)/nRow);
for iB = 1:nBlock
   for ii = 1:numel(ratePkData)
      subplot(nRow,nCol,ii);
      if iB == 1
         nameStr = sprintf(p.TITLE_STR,p.info(ii).area,p.info(ii).channel);
         setAxesProps(gca,nameStr,p);
      end
      
      r = [ratePkData{ii}.rateExtreme];
      
      x = [ratePkData{ii}.tPeak];
      y = [ratePkData{ii}.day];
      z = r;
      
      day_idx = [ratePkData{ii}.day] == p.dayTracker{ii}(iB);
      mask_idx = getPercentileMask(r,p.MASK_THRESH);
      
      idx = day_idx & mask_idx;
      
      scatter3(x(idx),y(idx),z(idx),p.MARKER_SIZE,...
         cm(cmIdx(iB),:),'filled',...
         'MarkerEdgeColor',p.MARKER_EDGE_COL,...
         'MarkerFaceAlpha',p.MARKER_FACE_ALPHA,...
         'Tag',sprintf(p.SCATTER_TAG,p.dayTracker{ii}(iB)));
      
   end
end

%% SAVE RATE-BY-DAY FIGURE
fprintf(1,'Saving figures...');
rateFigFile = sprintf('%s_%sRateExtremaScatterByDay.fig',...
   p.name,p.pars.alignmentEvent);
ratePNGFile = sprintf('%s_%sRateExtremaScatterByDay.png',...
   p.name,p.pars.alignmentEvent);

savefig(fig,fullfile(p.outDir,rateFigFile));
saveas(fig,fullfile(p.outDir,ratePNGFile));
if p.BATCH
   delete(fig);
end
fprintf(1,'complete.\n');

   function mask_idx = getPercentileMask(r,percentile)
      [r_sort,i_orig] = sort(r,'ascend');
      n = numel(r_sort);
      lb = ceil(n * percentile) - 1;
      ub = floor(n * (1 - percentile)) + 1;
      
      tmp_mask = false(1,n);
      tmp_mask([1:lb,ub:n]) = true;
      mask_idx = false(1,n);
      for i = 1:n
         mask_idx(i_orig) = tmp_mask(i);
      end
   end

end