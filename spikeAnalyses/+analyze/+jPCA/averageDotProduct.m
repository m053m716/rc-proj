function [avgDP,x] = averageDotProduct(angles, compAngle, w)
%AVERAGEDOTPRODUCT Returns average dot product with a comparison angle
%
%  [avgDP,x] = analyze.jPCA.averageDotProduct(angles,compAngle,w)
%
% Inputs
%  angles     - Input angles to compare
%  compAngle  - Angle for comparison
%  w          - (Optional) Angle weightings (default: ones size of angles)
%
% Output
%  avgDP      - Weighted average dot-product with comparison angle
%  x          - Cosine component (as transform for strength of angle)

% PARSE INPUT
if nargin < 3
   w = ones(size(angles));
end

x = cos(angles-compAngle);
avgDP = mean(x.*w) / mean(w);  % weighted sum

end