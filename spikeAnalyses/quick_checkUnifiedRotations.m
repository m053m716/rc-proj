function quick_checkUnifiedRotations(blockObj)
%% QUICK_CHECKUNIFIEDROTATIONS  Quickly plot first 10 successful trials jPCA


iSuccess = find(blockObj.Data.Grasp.All.jPCA.Unified.Full.Summary.outcomes==2,10,'first');
for iTrial = reshape(iSuccess,1,numel(iSuccess))
   figure('Name',sprintf('jPCA--%s success trial %g',blockObj.Name,iTrial),...
      'Units','Normalized',...
      'Position',[(randn([1 2])*0.05 + 0.35) 0.33 0.33],...
      'Color','w');
   subplot(2,3,1:3); 
   plot(blockObj.Data.Grasp.All.jPCA.Unified.Full.Projection(iTrial).allTimes,...
      blockObj.Data.Grasp.All.jPCA.Unified.Full.Projection(iTrial).projAllTimes);
   title(gca,sprintf('All jPCs: Trial %g',iTrial),'FontName','Arial','FontSize',16,'FontWeight','bold','Color','k');
   idx = (blockObj.Data.Grasp.All.jPCA.Unified.Full.Projection(iTrial).allTimes >= -750) & ...
      (blockObj.Data.Grasp.All.jPCA.Unified.Full.Projection(iTrial).allTimes <= 500);
   for ii = 1:3
      subplot(2,3,ii+3);
      c = zeros(1,3);
      c(ii) = 1;
      plot(blockObj.Data.Grasp.All.jPCA.Unified.Full.Projection(iTrial).projAllTimes(:,2*(ii-1)+1),...
         blockObj.Data.Grasp.All.jPCA.Unified.Full.Projection(iTrial).projAllTimes(:,2*ii),...
         'Color',c);
      title(gca,sprintf('jPCA Plane-%g',ii),'FontName','Arial','FontSize',14,'Color','k');
      xlabel('jPC_1','FontSize',8,'FontName','Arial','Color','k');
      ylabel('jPC_2','FontSize',8,'FontName','Arial','Color','k');
   end
   
end