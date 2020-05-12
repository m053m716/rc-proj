function fig = plotNeuralVariabilityByCondition(s)


AREA = {'RFA';'CFA'};
GROUP = {'Intact';'Ischemia'};
LINEGROUP = {'--';':'};
COL = {[0.2 0.2 0.8], [0.8 0.2 0.2]; [0.4 0.4 1.0], [1.0 0.4 0.4]};

STARTSTOP = [3  10;...
             11 17;...
             18 24];
          
SCORE_THRESH = [0 1.0];
PC1_DC_REMOVAL_SCORE = 6;
PC2_PC3_RADIUS = 4;
N_SEM = 1;

x = s.NV;
t = linspace(-2000,1000,3000);
idx = (t>=-400) & (t<=400);

fig = figure('Name','Neural Variability By Condition',...
         'Units','Normalized',...
         'Color','w',...
         'Position',[0.1 0.1 0.8 0.8]); 


for iG = 1:numel(GROUP)
   switch GROUP{iG}
      case 'Intact'

         
%          subplot(numel(GROUP),3,(1+(iG-1)*size(STARTSTOP,1)):(iG*size(STARTSTOP,1)));
         for iD = 1:size(STARTSTOP,1)
            h = [];
            legText = cell(numel(AREA),1);
            subplot(numel(GROUP),3,iD+(iG-1)*size(STARTSTOP,1));
            iAll = false(size(s,1),1);
            for iA = 1:numel(AREA)

%                iThis = ismember(s.area,AREA{iA}) ...
%                   & ismember(s.Group,GROUP{iG}) ...
%                   & (s.Score > SCORE_THRESH(1,1)) ...
%                   & (s.Score <= SCORE_THRESH(1,2)) ...
%                   & (s.pc(:,1) <= PC1_DC_REMOVAL_SCORE) ...
%                   & (sqrt(s.pc(:,2).^2 + s.pc(:,3).^2) >= PC2_PC3_RADIUS);
               iThis = ismember(s.area,AREA{iA}) ...
                  & ismember(s.Group,GROUP{iG}) ...
                  & (s.Score > SCORE_THRESH(1,1)) ...
                  & (s.Score <= SCORE_THRESH(1,2)) ...
                  & (s.pc(:,1) <= PC1_DC_REMOVAL_SCORE);
               iAll = iAll | iThis;
               z = mean(x(iThis,idx));
               sd = N_SEM*std(x(iThis,idx),[],1)/sqrt(sum(iThis));

               h = [h; ...
                  plot(t(idx),z,...
                  'Color',COL{iA,iG},'LineWidth',2,'LineStyle','-')]; %#ok<*AGROW>
               hold on; 
               plot(t(idx),[z-sd; z+sd],...
                  'Color',COL{iA,iG},'LineWidth',1.5,'LineStyle',LINEGROUP{iA});

               legText{iA} = sprintf('%s-%s (N = %g)',GROUP{iG},AREA{iA},sum(iThis));
            end
            xlabel('Time (ms)','FontName','Arial','Color','k','FontSize',14); 
            ylabel('Neural Variability','FontName','Arial','Color','k','FontSize',14); 
            title('All Post-Op Days',...
               'FontName','Arial','Color','k','FontSize',16); 
            tickVec = [round(0.75 * min(t(idx))), 0, round(0.75 * max(t(idx)))];
            set(gca,'XTick',tickVec);
            set(gca,'XTickLabel',{num2str(tickVec(1)), 'Grasp', num2str(tickVec(3))});
            set(gca,'XColor','k');
            set(gca,'YColor','k');
            set(gca,'FontName','Arial');
            set(gca,'FontSize',12);
            set(gca,'LineWidth',1.5);
            ylim([0 2]);
            xlim([min(t(idx)) max(t(idx))]);

            legend(h,legText); 
            sc = floor(mean(s.Score(iAll))*100);
            text(gca,-300,1.5,sprintf('Behavioral Score: %g%%',sc),...
                  'FontName','Arial',...
                  'FontSize',14,...
                  'Color','k',...
                  'FontWeight','bold');
         end
      case 'Ischemia'
         for iD = 1:size(STARTSTOP,1)      
            h = [];
            legText = cell(numel(AREA),1);

            subplot(numel(GROUP),3,iD+(iG-1)*size(STARTSTOP,1));
            iAll = false(size(s,1),1);
            for iA = 1:numel(AREA)

%                iThis = ismember(s.area,AREA{iA}) ...
%                   & ismember(s.Group,GROUP{iG}) ...
%                   & ismember(s.PostOpDay,STARTSTOP(iD,1):STARTSTOP(iD,2)) ...
%                   & (s.Score > SCORE_THRESH(1,1)) ...
%                   & (s.Score <= SCORE_THRESH(1,2)) ...
%                   & (s.pc(:,1) <= PC1_DC_REMOVAL_SCORE) ...
%                   & (sqrt(s.pc(:,2).^2 + s.pc(:,3).^2) >= PC2_PC3_RADIUS);
               iThis = ismember(s.area,AREA{iA}) ...
                  & ismember(s.Group,GROUP{iG}) ...
                  & ismember(s.PostOpDay,STARTSTOP(iD,1):STARTSTOP(iD,2)) ...
                  & (s.Score > SCORE_THRESH(1,1)) ...
                  & (s.Score <= SCORE_THRESH(1,2)) ...
                  & (s.pc(:,1) <= PC1_DC_REMOVAL_SCORE);
               iAll = iAll | iThis;
               z = mean(x(iThis,idx));
               sd = N_SEM*std(x(iThis,idx),[],1)/sqrt(sum(iThis));

               h = [h; ...
                  plot(t(idx),z,...
                  'Color',COL{iA,iG},'LineWidth',2,'LineStyle','-')]; %#ok<*AGROW>
               hold on; 
               plot(t(idx),[z-sd; z+sd],...
                  'Color',COL{iA,iG},'LineWidth',1.5,'LineStyle',LINEGROUP{iA});
               
               
               
               
               legText{iA} = sprintf('%s-%s (N = %g)',GROUP{iG},AREA{iA},sum(iThis));
            end
            sc = floor(mean(s.Score(iAll))*100);
            text(gca,-300,1.5,sprintf('Behavioral Score: %g%%',sc),...
                  'FontName','Arial',...
                  'FontSize',14,...
                  'Color','k',...
                  'FontWeight','bold');
               
            xlabel('Time (ms)','FontName','Arial','Color','k','FontSize',14); 
            ylabel('Neural Variability','FontName','Arial','Color','k','FontSize',14); 
            title(sprintf('Post-OP Days %g-%g',...
               STARTSTOP(iD,1),STARTSTOP(iD,2)),...
               'FontName','Arial','Color','k','FontSize',16); 
            tickVec = [round(0.75 * min(t(idx))), 0, round(0.75 * max(t(idx)))];
            set(gca,'XTick',tickVec);
            set(gca,'XTickLabel',{num2str(tickVec(1)), 'Grasp', num2str(tickVec(3))});
            set(gca,'XColor','k');
            set(gca,'YColor','k');
            set(gca,'FontName','Arial');
            set(gca,'FontSize',12);
            set(gca,'LineWidth',1.5);
            ylim([0 2]);
            xlim([min(t(idx)) max(t(idx))]);

            legend(h,legText); 
         end
   end
   
end


end