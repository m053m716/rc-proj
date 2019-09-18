function fig = plotWarpedRates(J,rowIdx,ch)
%% PLOTWARPEDRATES   Plot rates that are "warped" to match Reach & Grasp
%
%  fig = PLOTWARPEDRATES(J,rowIdx,ch);
%
% By: Max Murphy  v1.0  2019-06-14  Original version (R2017a)

%%
w = J.Data(rowIdx).Warp;
if nargin < 3
   fig = [];
   for ii = 1:size(w.rate,3)
      fig = [fig; plotWarpedRates(J,rowIdx,ii)]; %#ok<*AGROW>
   end
   return;
end

%%


chInfo = J.ChannelInfo{rowIdx}(ch);
chan = chInfo.channel;
probe = chInfo.probe;

%%
fig = figure('Name',sprintf('%s: Warped Rate: Channel %g-%g',J.Name{rowIdx},probe,chan),...
   'Color','w',...
   'Units','Normalized',...
   'Position',[0.1 0.1 0.8 0.8]);
COLS = {[0.4 0.4 0.8]; [0.8 0.4 0.4]}; 
t = linspace(-250,250,size(w.rate,2));

for ii = 1:numel(unique(w.label))
%    if isempty(w.time)
%       t = linspace(-250,250,size(w.rate,2));
%    else
%       t = w.time(w.label==(ii),:);
%    end

   rate = w.rate(w.label==(ii),:,ch);
   if isempty(rate)
      continue;
   end
   
   plot(t.',rate.',...
      'Color',COLS{ii},...
      'LineWidth',max(2.5-ii,1),...
      'ButtonDownFcn',@(src,evt,varargin)lineCallback(src,evt,'SEL_COL',COLS{ii}));
   hold on;
   
end

end