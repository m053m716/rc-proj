function quick_checkRotations(blockObj)
%% QUICK_CHECKUNIFIEDROTATIONS  Quickly plot first 10 successful trials jPCA

for iTrial = 1:(min(5,numel(blockObj.Data.Grasp.Successful.jPCA.Full.Projection)))
   figure('Name',sprintf('jPCA--%s success trial %g',blockObj.Name,iTrial),...
      'Units','Normalized',...
      'Position',[(randn([1 2])*0.05 + 0.35) 0.33 0.33],...
      'Color','w');
   subplot(3,3,1:3);
   plot(blockObj.Data.Grasp.Successful.t,...
      blockObj.Data.Grasp.Successful.rate(:,:,iTrial));
   title(gca,sprintf('Rates: Trial %g',iTrial),'FontName','Arial','FontSize',16,'FontWeight','bold','Color','k');
   
   subplot(3,3,4:6); 
   plot(blockObj.Data.Grasp.Successful.jPCA.Full.Projection(iTrial).allTimes,...
      blockObj.Data.Grasp.Successful.jPCA.Full.Projection(iTrial).projAllTimes);
   title(gca,sprintf('All jPCs: Trial %g',iTrial),'FontName','Arial','FontSize',16,'FontWeight','bold','Color','k');
   idx = (blockObj.Data.Grasp.Successful.jPCA.Full.Projection(iTrial).allTimes >= -750) & ...
      (blockObj.Data.Grasp.Successful.jPCA.Full.Projection(iTrial).allTimes <= 500);
   for ii = 1:3
      subplot(3,3,ii+6);
      c = zeros(1,3);
      c(ii) = 1;
      plot(blockObj.Data.Grasp.Successful.jPCA.Full.Projection(iTrial).projAllTimes(:,2*(ii-1)+1),...
         blockObj.Data.Grasp.Successful.jPCA.Full.Projection(iTrial).projAllTimes(:,2*ii),...
         'Color',c);
      title(gca,sprintf('jPCA Plane-%g',ii),'FontName','Arial','FontSize',14,'Color','k');
      xlabel('jPC_1','FontSize',8,'FontName','Arial','Color','k');
      ylabel('jPC_2','FontSize',8,'FontName','Arial','Color','k');
   end
end