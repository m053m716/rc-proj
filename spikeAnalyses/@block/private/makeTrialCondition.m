function c = makeTrialCondition(data,times,PCs,jPCs,mu,norms)
%MAKETRIALCONDITION Create trial condition struct array for jPCA
%
%  c = makeTrialCondition(data,times,allTimes,PCs,jPCs,mu,norms);
%
% Inputs
%  data  - Trial data: rows are time steps, columns are channels
%  times - Relative times (ms) corresponding to each timestep (row) of data
%  PCs   - Projection matrix for principal components
%  jPCs  - Projection matrix for jPCs
%  mu    - Cross-condition means (optional)
%  norms - Per-channel normalizations (optional)
%
% Output
%  c     - Struct element, part of struct array used in `jPCA` analyses

if nargin < 6
   norms = ones(size(data,2));
end

if nargin < 5
   mu = zeros(size(data,2));
end

if isempty(data)
   c = struct('proj',{},'times',{},'state',{});
   return;
end

c = struct(...
      'proj',{(data./norms-mu) * jPCs},...
      'times',{times},...
      'state',{(data./norms-mu)*PCs});

end
