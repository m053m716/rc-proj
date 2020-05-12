function h = circle(radius,theta_rot,center,ax,pts,color,width)
%% CIRCLE   Return a circle or ellipse object
%
%  h = CIRCLE(radius);
%  h = CIRCLE(radius,theta_rot);
%  h = CIRCLE(radius,theta_rot,center);
%  h = CIRCLE(radius,theta_rot,center,ax);
%  h = CIRCLE(radius,theta_rot,center,ax,pts);
%  h = CIRCLE(radius,theta_rot,center,ax,pts,color,width)
%
%  --------
%   INPUTS
%  --------
%   radius     :     For circle: scalar radius.
%                    For ellipse: [radiusX, radiusY]
%
%  theta_rot   :     (Optional; default: 0) Number of radians to rotate the
%                          circle or ellipse counter-clockwise.
%
%   center     :     [x,y] coordinates of the center of circle. 
%                       Default: [0,0]
%
%     ax       :     (Optional; default: gca) Axes to add the shape to.
%
%     pts      :     (Optional; default: 361) Number of points around
%                          perimeter of circle. Alternatively, can be
%                          specified as a vector of radians.
%
%    color     :     Color of circle line (default: 0.6*[1 1 1])
%
%    width     :     Width of circle line (default: 1.5)

%% PARSE INPUT
if nargin < 1
   radius = 1;
end

if nargin < 2
   theta_rot = 0;
end

if nargin < 3
   center = [0,0];
end

if nargin < 4
   ax = gca;
end

if nargin < 5
   pts = 361;
end

if nargin < 6
   color = 0.6*[1 1 1];
end

if nargin < 7
   width = 1.5;
end

if length(radius) == 1
    radius = [radius, radius];
end

%% MAKE CIRCLE OR ELLIPSE
if numel(pts) == 1
   theta_pts = linspace(0,2*pi,pts);
else
   theta_pts = pts;
end

theta_pts = reshape(theta_pts,1,numel(theta_pts));

X = [center(1)+radius(1)*cos(theta_pts);...
     center(2)+radius(2)*sin(theta_pts)];

% Rotation matrix
R = [cos(theta_rot), -sin(theta_rot);
     sin(theta_rot),  cos(theta_rot)];

Y = R * X;
x = Y(1,:);
y = Y(2,:);

h = plot(ax,x,y,'Color',color,'LineWidth',width);

end