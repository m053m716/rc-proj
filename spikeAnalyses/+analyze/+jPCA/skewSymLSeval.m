function [f, df] = skewSymLSeval(m,dX,X)
%SKEWSYMLSEVAL Evaluates distance & derivative, imposing skew symmetry on M
%
% [f,df] = skewSymLSeval(m,dX,X);
%
% Inputs
%  m - Vector of unique values in the skew-symmetrix matrix M
%  dX - The matrix of "targets" we seek to recover via transformation M
%  X - The original data (generally, the spike rates during behavior
%       trials)
%
% Output
%  f - Distance metric, under constraint that transformation M is
%        skew-symmetric (due to evaluation only using unique values `m`)
%  df - Distance derivative, for internal use by optimizer function
%
% John P Cunningham
% 2010
%
% skewSymLSeval.m
%
% This function evaluates the least squares function and derivative.
% The derivative is taken with respect to the vector m, which is the vector
% of the unique values in the skew-symmetric matrix M.
%
% A typical least squares regression of Az = b is z = A\b.  
% That is equivalent to an optimization: minimize norm(Az-b)^2.
%
% In matrix form, if we are doing a least squares regression of AM = B,
% that becomes: minimize norm(AM-B,'fro')^2, where 'fro' means frobenius
% norm.  Put another way, define error E = AM-B, then norm(E,'fro') is the
% same as norm(E(:)).
%
% Here, we want to evaluate the objective AM-B, where we call A 'X' and B
% 'dX'.  That is, we want to solve: minimize norm(dX - XM,'fro')^2.
% However, we want to constrain our solutions to just those M that are
% skew-symmetric, namely M = -M^T.  
%
% So, instead of just using M = X\dX, we here evaluate the objective and
% the derivative with respect to the unique elements of M (the vector m),
% for use in an iterative minimizer.
%
% See notes p80-82 for the derivation of the derivative.  
%
% See Also: analyze.jPCA.jPCA, analyze.jPCA.skewSymRegress,
%           analyze.jPCA.reshapeSkew

% since this function is internal, we do very little error checking.  Also
% the helper functions and internal functions should throw errors if any of
% these shapes are wrong.

%%%%%%%%%%%%%
% Evaluate objective function
%%%%%%%%%%%%%

f = norm( dX - X*analyze.jPCA.reshapeSkew(m) , 'fro')^2;

%%%%%%%%%%%%%
% Evaluate derivative
%%%%%%%%%%%%%
D = (dX - X*analyze.jPCA.reshapeSkew(m))'*X;

df = 2*analyze.jPCA.reshapeSkew( D - D' );

end