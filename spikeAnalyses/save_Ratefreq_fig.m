function fig = save_Ratefreq_fig(xPC,name,outpath)
%% SAVE_RATEFREQ_FIG  Function to export RATE frequency spectra
%
%

%% CHANGE HERE
MAX_FREQ = 1.75; % Hz
% N_PC_TO_PLOT = 4;

%%
if nargin < 3
   outpath = 'G:\Lab Member Folders\Max Murphy\Writing\_MANUSCRIPTS\2019-11-12_RC_Nat-Comms\Figures\Rate\Freqs';
end


[pxx,ff] = doRatefreqEstimate(xPC);

% Sort by time to first peak
[maxVal,maxLoc] = max(pxx,[],1);
[sortedMaxLoc,sortedIdx] = sort(maxLoc,'ascend');
% Then sort by value of the peak (on ties)
sortedMax = maxVal(sortedIdx);
u = unique(sortedMaxLoc);
for i = 1:numel(u)
   idx = sortedMaxLoc == u(i);
   [~,iMaxVal] = sort(sortedMax(idx),'descend');
   s = sortedIdx(idx);
   sortedIdx(idx) = s(iMaxVal); 
end

pxx = pxx(:,sortedIdx);

fig = figure('Name',sprintf('Rate Freq Content: %s',name),...
   'Units','Normalized',...
   'Color','w',...
   'ToolBar','none',...
   'MenuBar','none',...
   'Position',[0.3 0.1 0.4 0.8]); 
colormap('jet');
% h = waterfall(ff(ff<=MAX_FREQ),1:N_PC_TO_PLOT,pxx(ff<=MAX_FREQ,1:N_PC_TO_PLOT).');
% set(h,'FaceAlpha',0.75,'FaceColor',[0.9 0.9 0.9],'LineWidth',3);
ax = axes(fig,'Units','Normalized','NextPlot','add',...
   'XColor','k','YColor','k','LineWidth',1.5');
ylim(ax,[0.5 size(pxx,2)+0.5]);
xlim(ax,[0 MAX_FREQ]);
% set(ax,'YTick',1:N_PC_TO_PLOT);
xlabel(ax,'Frequency (Hz)','FontName','Arial','Color','k','FontSize',14);
ylabel(ax,'Channel','FontName','Arial','Color','k','FontSize',14);
title(ax,name,'FontName','Arial','Color','k','FontSize',16,'FontWeight','bold');

fIdx = ff<=MAX_FREQ;
imagesc(ax,ff(fIdx),1:size(pxx,2),pxx(fIdx,:).');
colorbar;

% for i = 1:size(pxx,2)
%    [pk,pkloc] = max(pxx(:,i));
%    scatter3(ax,ff(pkloc),i,pk,40,'k','Marker','o','MarkerFaceColor','r');
%    text(ax,ff(pkloc),i,pk+0.05,sprintf('%2.4g Hz',ff(pkloc)),...
%       'FontName','Arial','FontSize',14,'Color','k');
% end

if exist(outpath,'dir')==0
   mkdir(outpath);
end

expAI(fig,fullfile(outpath,name));
savefig(fig,fullfile(outpath,[name '.fig']));
saveas(fig,fullfile(outpath,[name '.png']));
if nargout < 1
   delete(fig);
end

end