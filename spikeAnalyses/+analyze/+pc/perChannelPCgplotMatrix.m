function fig = perChannelPCgplotMatrix(data,pars)
%PERCHANNELPCGPLOTMATRIX Group matrix scatter for top-3 PCs
%
%  fig = analyze.pc.perChannelPCgplotMatrix(data,pars);
%
% Inputs
%  data - struct with fields
%           'coeff','score','day','explained','desc','epoch','Group','Area'
%  pars - parameters struct
%
% Output
%  fig  - Figure handle
%
% See also: analyze.pc, channel_cross_day_trends

fig = figure('Name',sprintf('GPlotMatrix - %s',data.epoch),...
   'Color','w','Units','Normalized',...
   'Position',[0.2 0.2 0.4 0.6],'NumberTitle','off',...
   'UserData',data); 
[~,ax,bigAx] = gplotmatrix(fig,data.coeff(:,1:3),[],...
   pars.gplotPars.Groups,...
   pars.gplotPars.clr,...
   pars.gplotPars.sym,...
   pars.gplotPars.siz,...
   pars.gplotPars.doleg,...
   pars.gplotPars.dispopt,...
   data.desc);
title(bigAx,sprintf('%s Trend Groupings',data.epoch),...
   'FontName','Arial','Color','k','FontWeight','bold');

for iAx = 1:numel(ax)
   set(ax(iAx),'XColor','k','YColor','k','FontName','Arial','LineWidth',1.5);
   set(get(ax(iAx),'XLabel'),'FontName','Arial','Color','k','FontWeight','bold');
   set(get(ax(iAx),'YLabel'),'FontName','Arial','Color','k','FontWeight','bold');
end

end