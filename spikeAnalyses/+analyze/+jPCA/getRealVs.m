function Vr = getRealVs(V,lambda)
%GETREALVS  Get the real analogue of the eigenvectors
%
%  Vr = analyze.jPCA.getRealVs(V,lambda);
%
% Inputs
%  V        - Conjugate pair of eigenvectors
%  lambda   - Eigenvalues corresponding to the eigenvectors
%  State    - Reduced matrix of data projected on the top PCs 
%  nSamples - Number of analyzed samples (time bins) per trial
%
% Output
%  Vr       - Real analogue of estimated eigenvectors

% if nargin < 3
%    planSamples = 
% else
%    if isscalar(nSamples)
%       planSamples = 1:nSamples:size(State,1);
%    else
%       planSamples = nSamples;
%    end
% end

% by paying attention to this order, things will always rotate CCW
if abs(lambda(1))>0  % if the eigenvalue with negative imaginary component comes first
   Vr = [V(:,1) + V(:,2), (V(:,1) - V(:,2))*1i];
else
   Vr = [V(:,2) + V(:,1), (V(:,2) - V(:,1))*1i];
end
Vr = Vr / sqrt(2);

% % % Align "axes" so that spread is mostly along the horizontal axis % %
% testProj = (Vr'*State(planSamples,:)')'; % just picks out the plan times
% rotV = pca(testProj);
% 
% % Extend the vectors to "3D" space; now we can take the cross-product and
% % recover the "average" direction depending on if that is "up" or "down"
% crossProd = cross([rotV(:,1);0], [rotV(:,2);0]);
% if crossProd(3) < 0 
%    rotV(:,2) = -rotV(:,2); 
% end   % make sure the second vector is 90 degrees clockwise from the first
% Vr = Vr*rotV;
% 
% % flip both axes if necessary so that the maximum move excursion is in the positive direction
% testProj = (Vr'*State')';  % all the times
% if max(abs(testProj(:,2))) > max(testProj(:,2))  % 2nd column is the putative 'muscle potent' direction.
%    Vr = -Vr;
% end

end