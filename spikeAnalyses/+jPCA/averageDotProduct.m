function avgDP = averageDotProduct(angles, compAngle, w)
%% AVERAGEDOTPRODUCT  Get the average dot product with a comparison angle
%
%  avgDP = AVERAGEDOTPRODUCT(angles,compAngle,w)
%
%  --------
%   INPUTS
%  --------
%   angles     :     Input angles to compare
%
%  compAngle   :     Angle for comparison
%
%     w        :     Angle weightings

%% PARSE INPUT
if nargin < 3
   w = ones(size(angles));
end

x = cos(angles-compAngle);
avgDP = mean(x.*w) / mean(w);  % weighted sum

end