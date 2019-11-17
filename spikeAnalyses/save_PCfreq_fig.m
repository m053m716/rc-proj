function fig = save_PCfreq_fig(xPC,name,outpath)
%% SAVE_PCFREQ_FIG  Function to export PCA frequency spectra
%
%

%% CHANGE HERE
MAX_FREQ = 3.5; % Hz
N_PC_TO_PLOT = 4;

%%
if nargin < 3
   outpath = 'G:\Lab Member Folders\Max Murphy\Writing\_MANUSCRIPTS\2019-11-12_RC_Nat-Comms\Figures\PCA\Freqs';
end


[pxx,ff] = doPCfreqEstimate(xPC);
fig = figure('Name',sprintf('PC Freq Content: %s',name),...
   'Units','Normalized',...
   'Color','w',...
   'ToolBar','none',...
   'MenuBar','none',...
   'Position',[0.3 0.1 0.4 0.8]); 
colormap('jet');
h = waterfall(ff(ff<=MAX_FREQ),1:N_PC_TO_PLOT,pxx(ff<=MAX_FREQ,1:N_PC_TO_PLOT).');
set(h,'FaceAlpha',0.75,'FaceColor',[0.9 0.9 0.9],'LineWidth',3);
ax = gca;
ax.NextPlot = 'add';
ylim(ax,[0.5 N_PC_TO_PLOT+0.5]);
xlim(ax,[0 MAX_FREQ]);
set(ax,'YTick',1:N_PC_TO_PLOT);
set(ax,'XColor','k','YColor','k','ZColor','k');
set(ax,'LineWidth',1.5);
xlabel(ax,'Frequency (Hz)','FontName','Arial','Color','k','FontSize',14);
ylabel(ax,'Principal Component','FontName','Arial','Color','k','FontSize',14);
zlabel(ax,'PSD (Spike Rate / Hz)','FontName','Arial','Color','k','FontSize',14);
title(name,'FontName','Arial','Color','k','FontSize',16,'FontWeight','bold');

for i = 1:N_PC_TO_PLOT
   [pk,pkloc] = max(pxx(:,i));
   scatter3(ax,ff(pkloc),i,pk,40,'k','Marker','o','MarkerFaceColor','r');
   text(ax,ff(pkloc),i,pk+0.05,sprintf('%2.4g Hz',ff(pkloc)),...
      'FontName','Arial','FontSize',14,'Color','k');
end

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