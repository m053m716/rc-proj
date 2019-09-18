close all force;

T = readtable('P:\Extracted_Data_To_Move\Rat\TDTRat\behavior_data.xlsx');
u = unique(T.Name);
out_folder = fullfile(pwd,'behavioral-trajectories');
if exist(out_folder,'dir')==0
   mkdir(out_folder);
end

for ii = 1:numel(u)
% for ii = [5,6,8,11]
   fig = figure('Name',sprintf('Pellet Success: %s',u{ii}),...
      'Color','w',...
      'Units','Normalized',...
      'Position',[0.2+(ii/numel(u)*0.3),0.2+(ii/numel(u)*0.3),0.3,0.3]);
   
   idx = ismember(T.Name,u{ii});
%    plot(T.Date(idx),T.pct(idx)*100,...
%       'Color','k',...
%       'LineWidth',2,...
%       'Marker','o',...
%       'MarkerFaceColor','m');
   plot(parsePostOpDate(T(idx,:)),T.pct(idx)*100,...
      'Color','k',...
      'LineWidth',2,...
      'Marker','o',...
      'MarkerFaceColor','m');
   title(u{ii},'FontName','Arial','FontSize',16,'Color','k');
   ylim([-10 110]);
   ylabel('% Success','FontName','Arial','FontSize',14,'Color','k');
   xlabel('Post-Op Day','FontName','Arial','FontSize',14,'Color','k');
   
   fname = sprintf('%s_pellet_scored_successes_PO_DAY',u{ii});
   savefig(fig,fullfile(out_folder,[fname '.fig']));
   saveas(fig,fullfile(out_folder,[fname '.png']));
   delete(fig);
end