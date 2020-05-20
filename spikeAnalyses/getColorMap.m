function cm = getColorMap(nRows,style)
%GETCOLORMAP  Helper function to return CubeHelix colormap
%
%  cm = getColorMap(nRows);
%  -> nRows default: 12 (number of colormap rows)
%
%  cm = getColorMap(nRows,style);
%  -> style options:
%     * 'green' (default)
%     * 'red'
%     * 'blue'
%     * 'pastel'

% % Hard-coded params % %
N = 512;

% % Check inputs % %
if nargin < 1
   nRows = 12;
else
   nRows = min(nRows,N);
end

if nargin < 2
   style = 'green';
end

utils.addHelperRepos();
switch lower(style)
   case 'green'
      cm = gfx__.cubehelix(N,[0.05 -1 0.9 0.8],[0.2 0.9],[0.1 0.5]);
   case 'pastel'
      cm = gfx__.cubehelix(N,[0.5625 -1.1827 1.2327 0.66635],[0.5 0.8],[0.3 0.7]);
   case 'red'
      cm = gfx__.cubehelix(N,[0.10096 0.40385 0.75769 0.6024],[0.2 0.7],[0.3 0.6]);
   case 'blue'
      cm = gfx__.cubehelix(N,[0.22596 -0.016152 0.75769 0.6024],[0.2 0.7],[0.3 0.6]);
   otherwise
      cm = gfx__.cubehelix(N,[0.05 -1 0.9 0.8],[0.2 0.9],[0.1 0.5]);
end
      
cm = cm(round(linspace(1,N,nRows)),:);
end