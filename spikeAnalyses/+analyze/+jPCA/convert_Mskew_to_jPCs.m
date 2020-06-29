function jPCs = convert_Mskew_to_jPCs(Mskew,sortIndices)
%CONVERT_MSKEW_TO_JPCS Convert projection matrix to jPC vector pairs
%
%  jPCs = analyze.jPCA.convert_Mskew_to_jPCs(Mskew,scores);
%  % jPCs = analyze.jPCA.convert_Mskew_to_jPCs(Mskew,scores,planSamples);
%  % jPCs = analyze.jPCA.convert_Mskew_to_jPCs(__,sortIndices);
%
% Inputs
%  Mskew       - Skew-symmetric projection matrix for jPCA
%  scores      - PC-scores from PCA on multi-channel data (`A`)
%  planSamples - Scalar or vector of samples to use from each trial in
%                 order to determine the general orientation of the
%                 projection matrix.
%  sortIndices - Sort order for eigenvectors of skew-symmetric projection
%                 matrix (indexing vector).
%  
% Output
%  jPCs  - Essentially, Mskew, but formatted for only real-values and with
%          orientation of pairs of eigenvectors such that rotations are
%          designed to run clockwise
%
% See also: analyze.jPCA, analyze.jPCA.jPCA

[V,D] = eig(Mskew);
lambda = diag(D);
if nargin < 2
   [~,sortIndices] = sort(abs(lambda),1,'descend');
end

V = V(:,sortIndices);  % reorder the eigenvectors (base on eigenvalue size)
lambda_i = imag(lambda(sortIndices)); % order eigvals & remove tiny real part
jPCs = zeros(size(V));

nPlane = numel(sortIndices)/2;
for pair = 1:nPlane
   vi1 = 1+2*(pair-1);
   vi2 = 2*pair;
   
   VconjPair = V(:,[vi1,vi2]);  % a conjugate pair of eigenvectors
   evConjPair = lambda_i([vi1,vi2]); % and their eigenvalues
%    VconjPair = analyze.jPCA.getRealVs(VconjPair,evConjPair,scores,planSamples);
   VconjPair = analyze.jPCA.getRealVs(VconjPair,evConjPair);
   
   jPCs(:,[vi1,vi2]) = VconjPair;
end

end