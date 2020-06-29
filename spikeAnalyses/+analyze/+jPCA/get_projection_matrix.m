function [Mskew,M,Zn,dZn,scl,SS] = get_projection_matrix(scores,maskT1,maskT2,dt,e,epsilon)
%GET_PROJECTION_MATRIX  Core function to return projection matrices
%
%  M = analyze.jPCA.get_projection_matrix(scores,maskT1,maskT2);
%  [Mskew,M] = analyze.jPCA.get_projection_matrix(scores,maskT1,maskT2,dt);
%  [__,Zn,dZn,scl,SS] = analyze.jPCA.get_projection_matrix(__,e,epsilon);
%
% Inputs
%  scores - Principal component scores of original data (after reducing
%           dimensions)
%  maskT1 - Mask for first set of times to be used
%  maskT2 - Mask for second set of times (basically, shifted 1-sample
%              forward, but indexing this way makes you not subtract
%              between-trial differences, for example; must be accounted
%              for in the structure of the mask, of course)
%  dt     - Time-difference (optional; seconds)
%  e      - Total percent of data explained (scaled [0 1]; optional def 1)
%  epsilon- Conditioning noise variance (default: 0)
%
% Output
%  Mskew  - Skew-symmetric projection matrix from least-squares regression
%  M      - Least-squares optimal projection matrix  
%  Zn     - "State" that is essentially the PC scores used as observations
%           -> Mean-subtracted
%  dZn    - "State difference" that are the observed differences (to fit)
%           -> Mean-subtracted
%  scl    - Struct with fields 'Z' and 'dZ' containing corresponding mean
%              and standard deviation scaling factors.
%  SS     - "Sum-of-squares" struct
%
% See also: analyze.jPCA, analyze.jPCA.jPCA, analyze.jPCA.skewSymRegress

if nargin < 6
   epsilon = 0;
end

if nargin < 5
   e = 100;
end

if nargin < 4
   dt = defaults.jPCA('dt_short');
end

scl = struct;

dZ = (scores(maskT2,:) - scores(maskT1,:)) ./ dt;
scl.dZ.mu = mean(dZ,1);
scl.dZ.sigma = std(dZ,[],1);
dZn = (dZ - scl.dZ.mu)./scl.dZ.sigma; % Make sure to remove average

% For convenience, keep the "state" in its own variable (we will use the
% average of the two masks, since each difference estimate is most accurate
% for the point halfway between the two sets of samples)
Z = (scores(maskT1,:) + scores(maskT2,:)) ./ 2;
scl.Z.mu = mean(Z,1);
scl.Z.sigma = std(Z,[],1);
Zn = (Z - scl.Z.mu)./scl.Z.sigma;

% Note on sizes of matrices:
% dState' and preState' have time running horizontally and state dimension running vertically
% We are thus solving for dx = Mx.
% M is a matrix that takes a column state vector and gives the derivative

% now compute Mskew using John's method
% Mskew expects time to run vertically.
Mskew = analyze.jPCA.skewSymRegress(dZn,Zn,epsilon)';  

% Next compute the least-squares optimal regression. 
% We can solve this using standard least-squares regression, which we can 
% implement in MATLAB via `mldivide`. 
% This algorithm is numerically stable due to its use of QR decomposition.
M = (dZn' / Zn')';  % M takes the state and provides a fit to dState

if nargout < 6
   return;
end
SS = struct;
SS.skew = analyze.jPCA.recover_explained_variance(dZn,Zn,Mskew,e);
SS.best = analyze.jPCA.recover_explained_variance(dZn,Zn,M,e);
end