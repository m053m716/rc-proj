function fig = check_nth_pc(pc_struct,nth_pc,align)
%CHECK_NTH_PC  Checks the "n-th" principal-component overlay
%
%  fig = make.fig.check_nth_pc(pc_struct);
%  fig = make.fig.check_nth_pc(pc_struct,n,align);
%
%  -- Inputs --
%  pc_struct : `struct` returned by `pc = analyze.pc.get(T);` called on
%              rate table returned by `T = getRateTable(gData);`
%
%  n : (Optional) If not given, default is first PC. Specify as index
%           (1,2,3,... etc) of the "n-th" largest PC to overlay and check
%
%  align : (Optional) Default is 'Grasp'
%
%  -- Output --
%  fig : Figure handle

% % Handle inputs % %
if nargin < 3
   align = 'Grasp';
end

if nargin < 2
   nth_pc = 1;
elseif numel(nth_pc) > 1
   fig = [];
   if nargout < 1
      close all force;
   end
   for ii = 1:numel(nth_pc)
      fig = [fig; make.fig.check_nth_pc(pc_struct,nth_pc(ii),align)]; %#ok<AGROW>
   end   
   return;
end

tag = tag__.getOrdinalString(nth_pc,true);
tag = sprintf('%s PC',tag);
pos = ui__.getSecondMonitorPosition('Normalized',[0.2 0.2 0.5 0.5]);
pos(1) = pos(1) + 0.05*pos(3)*randn(1);
pos(2) = pos(2) + 0.05*pos(4)*randn(1);

fig = figure('Name',[tag ' overlay'],...
   'Color','w',...
   'Units','Normalized',...
   'Position',pos);

cols = defaults.experiment('rat_color');
ax = ui__.panelizeAxes(fig,10);

rat = unique(pc_struct.groups.table.AnimalID);
iKeep = cellfun(@(C)size(C,2)>=nth_pc,pc_struct.coeff) & ...
   pc_struct.groups.table.Alignment==align & ...
   pc_struct.groups.table.Outcome=='Successful';
coeffs = pc_struct.coeff(iKeep);
tab = pc_struct.groups.table(iKeep,:);
% d = tab.PostOpDay;
for iRat = 1:numel(rat)   
   hg_cfa = hggroup(ax(iRat),...
      'DisplayName',...
      sprintf('%s-CFA: %s',char(rat(iRat)),tag));
   hg_cfa.Annotation.LegendInformation.IconDisplayStyle = 'on';
   hg_rfa = hggroup(ax(iRat),...
      'DisplayName',...
      sprintf('%s-RFA: %s',char(rat(iRat)),tag));
   hg_rfa.Annotation.LegendInformation.IconDisplayStyle = 'on';

   t = pc_struct.t(pc_struct.t_idx).';
   T = [t; flipud(t)];
   F = [1:numel(T),1]; % faces

   idx = find(tab.AnimalID == rat(iRat));
   idx = reshape(idx,1,numel(idx));
   
   c_rfa = cols.All(iRat,:);
   c_cfa = min(c_rfa + [0.15 0.15 0.15],[1, 1, 1]);
   
   for ii = idx
      y = coeffs{ii,1}(:,nth_pc);
      
      if tab.Area(ii)=='CFA' %#ok<BDSCA>
         Y = [y+0.0045; flipud(y)-0.0045];
         h_cfa = patch(hg_cfa,...
            'Faces',F,'Vertices',[T,Y],...
            'FaceAlpha',0.25,...
            'FaceColor',c_cfa,...
            'EdgeColor','none');
         h_cfa.Annotation.LegendInformation.IconDisplayStyle = 'off';
%          datatip(h_cfa,'DataIndex',1,'Visible','off');
%          h_cfa.DataTipTemplate.DataTipRows(1) = ...
%             dataTipTextRow('Relative Time','XData',...
%                ['%#4.4g ms (Day ' num2str(d(ii)) ')']);
%          h_cfa.DataTipTemplate.DataTipRows(2) = ...
%             dataTipTextRow('PC Coeff (CFA)','YData','%#3.4g');
         
      else
         Y = [y+0.0065; flipud(y)-0.0065];
         h_rfa = patch(hg_rfa,...
            'Faces',F,'Vertices',[T,Y],...
            'FaceAlpha',0.35,...
            'FaceColor',c_rfa,...
            'EdgeColor','none');
         h_rfa.Annotation.LegendInformation.IconDisplayStyle = 'off';
%          datatip(h_rfa,'DataIndex',1,'Visible','off');
%          h_rfa.DataTipTemplate.DataTipRows(1) = ...
%             dataTipTextRow('Relative Time','XData',...
%                ['%#4.4g ms (Day ' num2str(d(ii)) ')']);
%          h_rfa.DataTipTemplate.DataTipRows(2) = ...
%             dataTipTextRow('PC Coeff (RFA)','YData','%#3.4g');
      end
      
   end

   title(ax(iRat),char(rat(iRat)),...
      'FontName','Arial','Color','k','FontSize',14,'FontWeight','bold');
   xlabel(ax(iRat),'Time (ms)','FontName','Arial','FontSize',12,'Color','k');
   ylabel(ax(iRat),'Coefficient','FontName','Arial','FontSize',12,'Color','k');
   xlim(ax(iRat),[min(t) max(t)]);
   ylim(ax(iRat),[-1 1]);
end

end