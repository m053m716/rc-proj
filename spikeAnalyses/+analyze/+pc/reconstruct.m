function Xr = reconstruct(Score,Coeff,Mu,nComponents)
%RECONSTRUCT  Reconstruct data from Scores, Coefficients, and Offsets
%
%  Xr = analyze.pc.reconstruct(Score,Coeff,Mu);
%     -> Default `nComponents` is size(Score,1);
%  
%  Xr = analyze.pc.reconstruct(Score,Coeff,Mu,nComponents);
%     -> Uses the top nComponents PCs in reconstruction.
%
%  Score, Coeff, and Mu should be given directly if in the matrix from
%  `+analyze/+nullspace` that is returned in table `D` from
%  `D = analyze.nullspace.sample.grasp(X);`

if nargin < 4
   nComponents = size(Score,1);
end

S = Score(1:nComponents,:).';
mu = Mu.';
coeff = Coeff(:,1:nComponents)';

Xr = (S*coeff + mu).';

end
