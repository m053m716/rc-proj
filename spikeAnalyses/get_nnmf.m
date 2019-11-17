function [W,H] = get_nnmf(X,k,opt)
%% GET_NNMF    [W,H] = get_nnmf(X,k,opt);
%
%  - Input -
%  X: nTimesteps x nChannels data matrix of (average) spike rates aligned
%        to some behavior of interest.
%  k: Number of nonnegative factors (optional; default: 6)
%  opt: Matlab statset object with options for factorization (optional)
%
%  - Output -
%  W: Nonnegative factors of X (correspond to timesteps; rows of X)
%  H: Factor coefficients for each channel.
%  

%%
if nargin < 2
   k = 3; % default
end

if nargin < 3
   % Parallel [1000 iter, 10000 reps, 1e-6 TolX & TolFun, 12 fac] = 255 sec
   % Parallel [5000 iter, 10000 reps, 1e-12 TolX & TolFun, 3 fac] = 421 sec
   % Serial [1000 iter, 10000 reps, 1e-6 TolX & TolFun, 12 fac] = 990 sec
   opt = statset(...
      'MaxIter',5000,...
      'Display','off',...
      'TolFun',1e-12,...
      'TolX',1e-12,...
      'UseParallel',true); 
end

[W,H,D] = nnmf(X,k,...
   'replicates',10000,...
   'options',opt,...
   'algorithm','mult');
disp(['RMS Residual = ' num2str(D)]);

end