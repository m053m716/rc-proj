function [hf,ax,axLim] = blankFigure(axLim,varargin)
%BLANKFIGURE  Construct blank figure with everything turned off
%
% analyze.jPCA.blankFigure(axLim);
% [hf,ax,axLim] = analyze.jPCA.blankFigure(axLim,'FigProp1',prop1val,...);
%
% Inputs
%  axLim - [X_lb X_ub Y_lb Y_ub] (data units)
%  
% Output
%  hf    - matlab.graphics.figure handle
%  ax    - matlab.graphics.axis.Axes handle
%  axLim - [left right bottom top]

if nargin < 1
   axLim = [-1 1 -1 1];
end

if numel(axLim) ~= 4
   axLim = [-1 1 -1 1];
end

if axLim(1) >= axLim(2)
   axLim(1) = -1;
   axLim(2) = 1;
end

if axLim(3) >= axLim(4)
   axLim(3) = -1;
   axLim(4) = 1;
end
hf = figure(...
   'NumberTitle','off',...
   'MenuBar','none',...
   'ToolBar','none',...
   'Color',[1 1 1],...
   varargin{:}); 
ax = axes(hf,...
   'Visible','off',...
   'XLimMode','manual',...
   'XLim',axLim(1:2),...
   'YLimMode','manual',...
   'YLim',axLim(3:4),...
   'NextPlot','add');
cm = analyze.jPCA.RC_cmap();
colormap(ax,cm);
axes(ax);
daspect(ax,[1 1 1]);
end