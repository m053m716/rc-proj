% produces a blank figure with everything turned off
% hf = blankFigure(axLim)
% where axLim = [left right bottom top]
function [hf,axLim] = blankFigure(axLim)

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

hf = figure; hold on; 
set(gca,'visible', 'off');
set(hf, 'color', [1 1 1]);


axis(axLim); axis square;