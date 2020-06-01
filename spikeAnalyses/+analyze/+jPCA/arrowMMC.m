function h = arrowMMC(prevPoint, point, nextPoint, p)
%ARROWMMC  Returns nice "arrow" for animated vectors, etc.
%
%   h = analyze.jPCA.arrowMMC(prevPoint, point, nextPoint);
%
%       Where each input (`prevPoint` `point` and `nextPoint`) is an 
%       [x,y] pair.  The three points are used to set the orientation
%       of the arrow so that it looks good when plotted on top of a curve, 
%       and roughly follows the tangent of the curvature.
%
%       If you don't want to use the third point (e.g., if there isn't one)
%       then use:
%
%   h = analyze.jPCA.arrowMMC(prevPoint, point, []);
%
%       You can also specify these additional arguments 
%       (must be done in order, but you don't have to use all)
%
%   h = analyze.jPCA.arrowMMC(__,sizeArrow,axisRange,faceColor,edgeColor);
%       Most importantly, axisRange tells arrowMMC how big to make the 
%       arrow, and allows it to have appropriately scaled proportions.  
%       If you don't supply this, arrowMMC will get it using 'gca'.  
%       But, if the axes are then later rescaled (e.g. due to more 
%       points plotting) things will get wonky.  
%       So either supply 'axisRange', or make sure the axes don't change 
%       after plotting the arrow.
%
%       A reasonable starting size for the arrow is 6.

% setting this empirically so that 'sizeArrow' 
% works roughly like 'markerSize'


% % do some parsing of the inputs, and use defaults if not provided % %
if nargin < 4
   p = defaults.jPCA('rosette_params');
end

if (nargin < 3) || isempty(nextPoint)
   nextPoint = point + point-prevPoint;
elseif isstruct(nextPoint)
   p = nextPoint;
   nextPoint = point + point-prevPoint;
end

if isfield(p,'Arrow')
   if isempty(p.Arrow.Axes)
      p.Arrow.Axes = p.Axes;
   end
   p = p.Arrow;
end

if isempty(p.Axes)
   p.Axes = gca;
end

% % Convert to old variable names % %
xRange = range(p.XLim);
yRange = range(p.YLim);
roughScale = p.RoughScale;  
xVals = p.XVals;
yVals = p.YVals;

% % do a bit of scaling % % 
mxX = max(xVals);
xVals = roughScale*p.Size * xVals/mxX * xRange;
yVals = roughScale*p.Size * yVals/mxX * yRange;

% % now do the rotation % %

vector = nextPoint - prevPoint;
theta = atan2(vector(2),vector(1));
rotM = [cos(theta) -sin(theta); sin(theta), cos(theta)];
    
newVals = rotM*[xVals; yVals];
xVals = newVals(1,:);
yVals = newVals(2,:);

% % now plot % %
xVals = xVals + point(1);
yVals = yVals + point(2);
h = fill(p.Axes,...
   xVals, yVals, p.FaceColor,...
   'FaceAlpha',p.FaceAlpha,...
   'EdgeColor',p.EdgeColor);

end
