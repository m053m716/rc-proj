function fig = save_coherenceByDay_fig(cxy,name,outpath)

PODAY = (3:28)';
COL = {'b';'r';'m';'k'};
SZ = 25;
LB = 0.05;
UB = 0.95;

OUT = 'G:\Lab Member Folders\Max Murphy\Writing\_MANUSCRIPTS\2019-11-12_RC_Nat-Comms\Figures\PCA\Cross-Day-Coherence';
NAME = 'PC Coherence By Day - All Channels';

if nargin < 3
   outpath = OUT;
end
if nargin < 2
   name = NAME;
end

iIntact = 1:numel(PODAY);
iIschemia = (numel(PODAY)+1):size(cxy,1);

iGroup = {iIntact; ...
          iIschemia};
gName = {'Intact - All Channels'; ...
         'Ischemia - All Channels'};

fig = figure('Name','PC Coherence by Day',...
   'Units','Normalized',...
   'Color','w',...
   'Position',[0.2 0.1 0.4 0.8]);

ax = gobjects(2,1);
nRow = size(ax,1);
nCol = size(ax,2);
nRep = size(cxy,3);
iCount = 0;
ub = min(round(UB * nRep),nRep);
lb = max(round(LB * nRep),1);
pxy = cell(nRow,nCol);
for iRow = 1:nRow
   for iCol = 1:nCol
      iCount = iCount + 1;
      ax(iRow,iCol) = subplot(nRow,nCol,iCount);
      ax(iRow,iCol).NextPlot = 'add';
      
      [b,a] = butter(2,0.125,'low');
      pxy{iRow,iCol} = cxy(iGroup{iRow,iCol},:,:);
%       idx = ~isnan(pxy(:,1,1));
      if any(ismissing(pxy{iRow,iCol}(:,1,1)))
         for iShuff = 1:nRep
            pxy{iRow,iCol}(:,:,iShuff) = fillmissing(pxy{iRow,iCol}(:,:,iShuff),'linear');
         end
      end
      
      for iShuff = 1:nRep
         pxy{iRow,iCol}(:,:,iShuff) = filtfilt(b,a,pxy{iRow,iCol}(:,:,iShuff));
      end
      
      
%       for iShuff = 1:size(cxy,3)
         
         
%          for i = 1:size(pxy,2)
%             scatter(ax(iRow,iCol),...
%                PODAY,...
%                pxy(:,i,iShuff),...
%                SZ,COL{i},'Marker','+');
%          end
         
%          
%          pxy(idx,:,iShuff) = filtfilt(b,a,pxy(idx,:,iShuff));
%          if any(ismissing(pxy(:,1,iShuff)))
%             pxy(:,:,iShuff) = fillmissing(pxy(:,:,iShuff),'linear');
%          end
%       end
      


      % Add lines with shaded SEM
      h = gobjects(size(pxy{iRow,iCol},2),1);
      mu = mean(pxy{iRow,iCol},3);
      sd = std(pxy{iRow,iCol},[],3);
      
      
      for i = 1:size(mu,2)
         err = squeeze(pxy{iRow,iCol}(:,i,:));
         err = sort(err,2,'ascend');
         err = err(:,[lb, ub]).';
         
         h(i) = plot(ax(iRow,iCol),...
            PODAY,mu(:,i),'Color',COL{i},...
            'LineWidth',2);
         gfx.plotWithShadedError(ax(iRow,iCol),PODAY,mu(:,i),err,...
            'Color',COL{i},'FaceColor',COL{i});         

      end
      
      
      
      if iCount == 1
         l = legend(h,{'PC-1';'PC-2';'PC-3';'PC-4'});
            l.FontName = 'Arial';
            l.FontSize = 12;
            l.TextColor = 'k';
      end
      
      if iCount == 2
         for i = 1:size(pxy{iRow,iCol},2)
            h0 = squeeze(pxy{1}(:,i,:));
            y = squeeze(pxy{2}(:,i,:));
            gfx.addSignificanceLine(ax(iRow,iCol),PODAY,y,h0,1e-15,...
               'Color',COL{i},...
               'HighVal',0.95 - (i-1)*0.035,...
               'LowVal',0.94 - (i-1)*0.035);
         end
      end
      title(ax(iRow,iCol),gName{iRow,iCol},'FontName','Arial','FontSize',16,'Color','k');
      xlabel(ax(iRow,iCol),'PO-Day','FontName','Arial','FontSize',14,'Color','k');
      ylabel(ax(iRow,iCol),'||C_x_y(f_{MAX})||^2','FontName','Arial','FontSize',14,'Color','k');
      xlim([min(PODAY), max(PODAY)+1]);
      ylim([0 1]);
   end
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