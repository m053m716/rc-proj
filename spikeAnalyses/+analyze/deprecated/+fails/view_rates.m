function fig = view_rates(U)
%VIEW_RATES  Plot all unsuccessful rate averages by animal
%
%  fig = analyze.fails.view_rates(U);
%
%  -- Inputs --
%  U : Table from `U = analyze.fails.get_subset(T);`
%
%  -- Output --
%  fig : Figure handle

utils.addHelperRepos();
Align = {'Reach','Grasp'};
for iA = 1:numel(Align)
   fig = figure('Name',sprintf('Unsuccessful Average Rates: %s',Align{iA}),...
      'NumberTitle','off',...
      'Units','Normalized',...
      'Color','w',...
      'Position',[0.1 0.1 0.8 0.8]...
      );

   ax = axes(fig,'NextPlot','add',...
      'XColor','k','LineWidth',1.5,...
      'YColor','k');

   u = U(U.Alignment==Align{iA},:);
   G = findgroups(u(:,{'AnimalID','Area'}));
   splitapply(@(X)addMeanPlot(ax,u.Properties.UserData.t,X),u.Rate,G);
end
   function addMeanPlot(ax,t,X)
      gfx__.plotWithShadedError(ax,t,X,'FaceAlpha',0.1,'FaceColor',rand(1,3));
   end

end