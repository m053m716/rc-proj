function setAxesProps(ax,nameStr,p)
%% SETAXESPROPS      Default axes properties based on parameters structure

set(ax,'NextPlot','add');

set(ax,'XLimMode','manual');
set(ax,'YLimMode','manual');
set(ax,'ZLimMode','manual');

set(ax,'XLim',p.XLIM);
set(ax,'YLim',p.YLIM);
set(ax,'ZLim',p.ZLIM);
set(ax,'View',p.VIEW);

set(ax,'XColor',p.AXES_COL);
set(ax,'YColor',p.AXES_COL);
set(ax,'ZColor',p.AXES_COL);

set(ax,'XGrid',p.XGRID);
set(ax,'YGrid',p.YGRID);
set(ax,'ZGrid',p.ZGRID);

set(ax.Title,'String',nameStr);
set(ax.Title,'FontName',p.FONT);
set(ax.Title,'Color',p.FONT_COL);
set(ax.Title,'FontSize',p.TITLE_FONT_SIZE);

set(ax.XLabel,'String',p.XLABEL);
set(ax.XLabel,'FontName',p.FONT);
set(ax.XLabel,'Color',p.FONT_COL);
set(ax.XLabel,'FontSize',p.AXES_FONT_SIZE);

set(ax.YLabel,'String',p.YLABEL);
set(ax.YLabel,'FontName',p.FONT);
set(ax.YLabel,'Color',p.FONT_COL);
set(ax.YLabel,'FontSize',p.AXES_FONT_SIZE);

set(ax.ZLabel,'String',p.ZLABEL);
set(ax.ZLabel,'FontName',p.FONT);
set(ax.ZLabel,'Color',p.FONT_COL);
set(ax.ZLabel,'FontSize',p.AXES_FONT_SIZE);
end