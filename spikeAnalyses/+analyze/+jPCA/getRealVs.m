function Vr = getRealVs(V,lambda,Ared,nSamples)
%GETREALVS  Get the real analogue of the eigenvectors
%
%  Vr = GETREALVS(V,lambda,Ared)
%
% Inputs
%  V        - Conjugate pair of eigenvectors
%  lambda   - Eigenvalues corresponding to the eigenvectors
%  Ared     - Reduced matrix of data projected on the top PCs 
%                    (number dims is specified in DEFAULTS.JPCA)
%  nSamples - Number of analyzed samples (time bins) per trial
%
% Output
%  Vr       - Real analogue of estimated eigenvectors

if isscalar(nSamples)
   planSamples = 1:nSamples:size(Ared,1);
else
   planSamples = nSamples;
end

% by paying attention to this order, things will always rotate CCW
if abs(lambda(1))>0  % if the eigenvalue with negative imaginary component comes first
   Vr = [V(:,1) + V(:,2), (V(:,1) - V(:,2))*1i];
else
   Vr = [V(:,2) + V(:,1), (V(:,2) - V(:,1))*1i];
end
Vr = Vr / sqrt(2);

% now get axes aligned so that plan is spread mostly along the horizontal axis
testProj = (Vr'*Ared(planSamples,:)')'; % just picks out the plan times
rotV = pca(testProj);
crossProd = cross([rotV(:,1);0], [rotV(:,2);0]);
if crossProd(3) < 0 
   rotV(:,2) = -rotV(:,2); 
end   % make sure the second vector is 90 degrees clockwise from the first
Vr = Vr*rotV;

% flip both axes if necessary so that the maximum move excursion is in the positive direction
testProj = (Vr'*Ared')';  % all the times
if max(abs(testProj(:,2))) > max(testProj(:,2))  % 2nd column is the putative 'muscle potent' direction.
   Vr = -Vr;
end

end