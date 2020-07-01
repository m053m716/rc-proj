function [yn,o,s,pol] = scaleResponse(x,y)
%SCALERESPONSE Scale y to be "well-tolerated" for logistic regression
%
%  [yn,s,o,pol] = analyze.stat.scaleResponse(x,y);
%
% Inputs
%  x  - Observed independent variable
%  y  - Observed response of interest
%
% Output
%  yn - "Normalized" response that is bounded on open interval (0,1)
%  o  - Offset constant:
%        ```
%           mu = median(y);
%           yc = y - mu;
%           ys = (yc) ./ s;
%           o = min(ys) + e;
%        ```
%  s  - Scale constant:
%        ```
%           mu = median(y);
%           yc = y - mu;
%           [s1,idx] = max(abs(yc));
%           s = s1*sign(yc(idx)) + epsilon*sign(yc(idx));
%           e = epsilon*sign(yc(idx));
%        ```
%  pol - Signal polarity at maximum deviation
%  Default epsilon value is 1e-3
%
% yn = (y - o)./s;
% y  = yn.*s + o;

dY = pdist(y,@(y1,y2)minus(y1,y2));
dX = pdist(x,@(y1,y2)minus(y1,y2));
pol = sign(median(dY ./ dX));
o = min(y) - eps;
s = max(y - o) + eps;
yn = (y - o) ./ s;

end