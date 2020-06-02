function [h,p] = circle(p)
%CIRCLE   Return a circle or ellipse object on current or specified axes
%
% h = analyze.jPCA.circle(p);
%
% Inputs
%  p - Parameters struct field from 'Circle' field of `params` obtained via
%        -> `params = defaults.jPCA('rosette_params');`
%     Fields of `p`:
%        radius     :     For circle: scalar radius.
%                         For ellipse: [radiusX, radiusY]
%
%        theta_rot   :     (Optional; default: 0) 
%                             Number of radians to rotate the
%                             circle or ellipse counter-clockwise.
%
%        center     :     [x,y] coordinates of the center of circle. 
%                             Default: [0,0]
%
%        ax          :    (Optional; default: gca) Axes to add the shape to
%
%        pts      :     (Optional; default: 361) Number of points around
%                          perimeter of circle. Alternatively, can be
%                          specified as a vector of radians.
%
%        color     :     Color of circle line (default: 0.6*[1 1 1])
%
%        width     :     Width of circle line (default: 1.5)
%
% Output
%   h - Graphics object (matlab.graphics.primitive.line) of circle/ellipse
%   p - Parameters struct used to create `h`

% PARSE INPUT
if nargin < 1
   p = defaults.jPCA('rosette_params');
   
end
if isfield(p,'Circle')
   p = p.Circle;
end

% Parse old parameters
if isempty(p.Axes)
   p.Axes = gca;
end

ax = p.Axes;
radius = p.Radius;
theta_rot = p.Theta;
center = p.Center;
pts = p.NumPoint;
color = p.Color;
width = p.LineWidth;

if length(radius) == 1
    radius = [radius, radius];
end

% MAKE CIRCLE OR ELLIPSE
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

h = line(ax,x,y,...
   'Color',color,...
   'LineWidth',width,...
   'DisplayName',p.DisplayName,...
   'Tag',p.Tag);
h.Annotation.LegendInformation.IconDisplayStyle = p.Annotation;

end