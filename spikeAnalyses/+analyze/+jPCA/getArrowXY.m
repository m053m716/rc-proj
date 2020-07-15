function [xVals,yVals] = getArrowXY(prevPoint,point,nextPoint,varargin)
%GETARROWXY Get X and Y coordinate pairs for arrow graphic
%
%  [xVals,yVals] = analyze.jPCA.getArrowXY(prevPoint,point,nextPoint);
%  [xVals,yVals] = analyze.jPCA.getArrowXY(prevPoint,point,'name',val,...);
%
% Inputs
%  prevPoint
%  point
%  nextPoint
%
% Output
%  xVals       - X-coordinate points for arrow graphic
%  yVals       - Y-coordinate points for arrow graphic
%
% See also: analyze.jPCA, analyze.jPCA.arrowMMC

p = struct;
p.Size = 5;
p.XLim = [-5 5];
p.YLim = [-5 5];
p.XVals = [0; -1.5; 4.5; -1.5; 0];
p.YVals = [0; 2; 0; -2; 0];
p.RoughScale = 0.004;
fn = fieldnames(p);

if (nargin < 3) || isempty(nextPoint)
   nextPoint = point + point-prevPoint;
elseif isstruct(nextPoint)
   p = nextPoint;
   nextPoint = point + point-prevPoint;
end

if nargin > 3
   if isstruct(varargin{1})
      p = varargin{1};
      varargin(1) = [];
   end
end

for iV = 1:2:numel(varargin)
   idx = strcmpi(fn,varargin{iV});
   if sum(idx) == 1
      p.(fn{idx}) = varargin{iV+1};
   end
end

% % Convert to old variable names % %
xRange = range(p.XLim);
yRange = range(p.YLim);
roughScale = p.RoughScale;  
xVals = p.XVals;
yVals = p.YVals;

% % Scale the coordinates forming the arrow shape % % 
mxX = max(xVals);
xVals = roughScale*p.Size * xVals/mxX * xRange;
yVals = roughScale*p.Size * yVals/mxX * yRange;

% % Rotate the arrow coordinates to point in direction of trajectory % %
vector = nextPoint - prevPoint;
theta = atan2(vector(2),vector(1));

% Standard rotation matrix, based on estimated theta %
rotM = [cos(theta) sin(theta); -sin(theta), cos(theta)];    
newVals = [xVals, yVals]*rotM;
xVals = newVals(:,1);
yVals = newVals(:,2);

% Add position to rotated coordinates (last step) %
xVals = xVals + point(1);
yVals = yVals + point(2);

end