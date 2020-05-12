if exist('x','var')==0
   load('All-Days-Successful-Grasp-All-Groups-All-Channels-xPCobj.mat','x','y');
end

OUT = 'G:\Lab Member Folders\Max Murphy\Writing\_MANUSCRIPTS\2019-11-12_RC_Nat-Comms\Figures\PCA\Freqs';
NAME = 'All-Spectra';
WLEN = 32;
NFFT = 1028;
T0 = x.t(1)*1e-3;
TW = x.t(WLEN)*1e-3;
wCenterT = (T0+TW)/2;

fig = figure('Name','PC-spectra',...
   'NumberTitle','off',...
   'MenuBar','none',...
   'ToolBar','none',...
   'Color','w',...
   'Units','Normalized',...
   'Position',[0.25 0.25 0.4 0.65]); 

for i = 1:4
   subplot(2,2,i);
   [s,f,t] = spectrogram(x.V(:,i),hamming(WLEN),WLEN-1,NFFT,x.fs,'power');
   tOffset = t(1) + (T0 + wCenterT);
   T = t+tOffset;
   imagesc(t+tOffset,f,mag2db(abs(s)));
   set(gca,'YDir','normal');
   xlabel('Time (s)','FontName','Arial','Color','k','FontSize',14);
   ylabel('Freq (Hz)','FontName','Arial','Color','k','FontSize',14);
   title(sprintf('PC-%g',i),'FontName','Arial','Color','k','FontSize',16);
   [~,iFMax] = max(nanmean(abs(s),2));
   hold on;
   line([T(1),T(end)],[f(iFMax) f(iFMax)],'Color','k','LineStyle',':',...
      'LineWidth',2);
   text(-0.15,f(iFMax)+0.75,sprintf('f_{MAX} = %2.3g Hz',f(iFMax)),...
      'FontName','Arial','FontSize',13,'Color','k');
end

if exist(OUT,'dir')==0
   mkdir(OUT);
end
expAI(fig,fullfile(OUT,NAME));
savefig(fig,fullfile(OUT,[NAME '.fig']));
saveas(fig,fullfile(OUT,[NAME '.png']));
delete(fig);