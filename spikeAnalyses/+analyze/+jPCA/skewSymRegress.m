function M = skewSymRegress(dX,X)
%SKEWSYMREGRESS Apply least-squares regression to recover skew-symmetric M
%
% M = analyze.jPCA.skewSymRegress(dX,X);
%
% Inputs
%  dX - "Target" matrix of differences, based on published paper this
%        should be differences in the top rate principal components.
%
%  X -  "Data" matrix of observed rates (or principal components, in order
%        to reduce the number of simultaneously-observed variables and
%        prevent chances of ill-conditioned covariance matrix).
%
% Output
%  M - Skew-symmetric transformation matrix such that M = -M' and dX = XM
%
%
% -- Notes --
% This function does least squares regression between a matrix dX and X.
% It finds a matrix M such that dX = XM (as close as possible in the
% least squares sense).  Unlike regular least squares regression (M = X\dX)
% this function find M such that M is a skew symmetric matrix, that is,
% M = -M^T.
%
% Put another way, this is least squares regression over the constrained 
% set of skew-symmetric matrices.
%
% This can be solved by treating M as a vector of the unique elements that
% exist in a skew-symmetric matrix.
%
% A skew-symmetric matrix M of size n by n really only
% has n*(n-1)/2 unique entries.  That is, the diagonal is 0, and the
% upper/lower triangle is the negative transpose of the lower/upper.  So,
% we can just think of such a matrix as a vector x of size n(n-1)/2.
%
% Corresponding to this change in M, we would have to change X to be quite
% big and quite redundant.  That can be done, but an easier and faster and 
% more stable thing to do is to use an iterative solver that takes a 
% function and gradient evaluation.
%
% This iterative procedure is numerically accurate, etc, etc.
%
% So, this allows us to never make a big X skew matrix, and we just have to
% reshape M between vector and skew-symmetric matrix form as appropriate.
%
% See Also: analyze.jPCA.jPCA, analyze.jPCA.skewSymLSEval,
%           analyze.jPCA.reshapeSkew, analyze.jPCA.minimize
%
% John P Cunningham
% 2010
%
% skewSymRegress

% % % % % % % % % % % % % About initializing m0 % % % % % % % % % % % %
% As this function is convex, the choice of starting point should not %
% matter! There is a provable unique minimizer.                       %
%                                                                     %
% In theory, a good initialization helps the optimization converge    %
% faster (although in practice this is so fast that it is unnoticed)  %                                             %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

M0 = X\dX; % the non-skew-symmetric matrix.
M0k = 0.5*(M0 - M0'); % the skew-symmetric matrix component...
% Note 1: This is the same as M, if the data is white (ie X'X=I)
m0 = analyze.jPCA.reshapeSkew(M0k);

% Note 2: You can verify the empirical convergence of this algorithm by
%         insertion of either of the following lines for the initialization
%         guess:

%m0 = zeros(size(m0));
%m0 = 100*randn(size(m0));

% % % % % % % % % % % % % % % % % % % % %
% The following call does all the work: %
% % % % % % % % % % % % % % % % % % % % %

% just call minimize.m with the appropriate function...
[m,~,iter] = analyze.jPCA.minimize(...
   m0,...  % Initial guess (and first input to skewSymLSeval)
   'analyze.jPCA.skewSymLSeval',... % Function to minimize
   1000,... % Maximum # of iterations (should not come close to 1000)
   dX,...   % Second argument to skewSymLSeval
   X);      % Third argument to skewSymLSeval

% check to make sure that nothing was funky.
if iter > 500
   warning(['JPCA:' mfilename ':WeirdOptimization'],...
      ['\n\t->\t<strong>[SKEWSYMREGRESS]:</strong> ' ...
      'More than <strong>500</strong> line searches were required ' ...
      'for `analyze.jPCA.minimize` to complete!\n'...
      '\t\t\t(Note: because this is a convex optimization with ' ...
      'analytical gradient computation, it should converge ' ...
      'much more quickly than that. Check the code or the ' ...
      'conditioning of the data matrices to it is not ill-posed)\n']);
end
% return the matrix
M = analyze.jPCA.reshapeSkew(m);

end
