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
%     * 'vibrant'
%     * 'events'

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
      cm = gfx__.cubehelix(N,[0.05 -1.00 0.90 0.96],[0.40 0.60],[0.10 0.53]);
   case 'pastel'
      cm = gfx__.cubehelix(N,[0.56 -1.36 1.23 0.95],[0.50 0.55],[0.30 0.70]);
   case 'red'
      cm = gfx__.cubehelix(N,[0.28 0.40 1.69 0.58],[0.40 0.60],[0.30 0.60]);
   case 'blue'
      cm = gfx__.cubehelix(N,[0.23 -0.02 0.76 0.81],[0.30 0.60],[0.30 0.60]);
   case 'vibrant'
      cm = gfx__.cubehelix(N,[0.38 1.82 1.43 0.74],[0.20 0.80],[0.30 0.70]);
   case {'event','events','align','alignment','behavior'}
      N = 4;
      cm = gfx__.cubehelix(N,[0.74 -1.50 1.00 1.00],[0.00 0.75],[0.00 1.00]);
   otherwise
      cm = gfx__.cubehelix(N,[0.38 1.82 1.43 0.74],[0.20 0.80],[0.30 0.70]);
end
      
cm = cm(round(linspace(1,N,nRows)),:);
end