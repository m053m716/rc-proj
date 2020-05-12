function fig = plotNV(stats,ratName,postOpDay)

DELETE_FIG = true;

s = screenStats(stats);

if nargin < 2
   ratName = unique(s.Rat);
else
   if nargin < 3
      postOpDay = unique(s.PostOpDay(ismember(s.Rat,ratName)));
   end
end

if iscell(ratName) 
   fig = [];
   for ii = 1:numel(ratName)
      if nargin < 3
         postOpDay = unique(s.PostOpDay(ismember(s.Rat,ratName{ii})));
      end
      fig = [fig; plotNV(s,ratName{ii},postOpDay)]; %#ok<*AGROW>
   end
   return;
end

if numel(postOpDay) > 1
   fig = [];
   for ii = 1:numel(postOpDay)
      fig = [fig; plotNV(s,ratName,postOpDay(ii))];
   end
   return;
end

str = sprintf('%s - Post-Op Day %g Neural Variability',ratName,postOpDay);
fig = figure('Name',str,...
   'Units','Normalized',...
   'Color','w',...
   'Position',[0.1 0.1 0.8 0.8]);

s = screenStats(s,ratName,postOpDay);

t = linspace(-2000,1000,size(s.NV,2));
idx = (t >=-400) & (t<= 400);

plot(t(idx),s.NV(ismember(s.area,'CFA'),idx),...
   'Color','r','LineWidth',1.75);
text(-150, -0.35, 'CFA','Color','r','FontName','Arial','FontSize',14,'FontWeight','bold');
hold on;
plot(t(idx),s.NV(ismember(s.area,'RFA'),idx),...
   'Color','b','LineWidth',1.75);
text(-100, -0.35, 'RFA','Color','b','FontName','Arial','FontSize',14,'FontWeight','bold');
text(200, -0.35, sprintf('Behavioral Score: %g%%',round(s.Score(1)*100)),'FontName','Arial','FontSize',14,'FontWeight','bold','Color','m');

ylim([0 7]);
xlim([min(t(idx)) max(t(idx))]);
tickVec = [round(0.75 * min(t(idx))), 0, round(0.75 * max(t(idx)))];
set(gca,'XTick',tickVec);
set(gca,'XTickLabel',{num2str(tickVec(1)), 'Grasp', num2str(tickVec(3))});
set(gca,'XColor','k');
set(gca,'YColor','k');
set(gca,'LineWidth',1.5);
xlabel('Time (ms)','FontName','Arial','FontSize',14,'Color','k');
ylabel('Neural Variability (NV)','FontName','Arial','FontSize',14,'Color','k');
title(str,'FontName','Arial','FontSize',16,'Color','k');

outpath = fullfile(pwd,'optimal-subspace');
if exist(outpath,'dir')==0
   mkdir(outpath);
end

str = sprintf('%s_%03gms-Kernel',str,defaults.block('spike_smoother_w'));
savefig(fig,fullfile(outpath,[str '.fig']));
saveas(fig,fullfile(outpath,[str '.png']));

if DELETE_FIG
   delete(fig);
end

end