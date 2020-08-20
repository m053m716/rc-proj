function SS = recover_explained_variance(dState,State,M,e)
%RECOVER_EXPLAINED_VARIANCE Return struct with % explained var, etc.
%
%  SS = analyze.jPCA.recover_explained_variance(dState,State,M);
%  SS = analyze.jPCA.recover_explained_variance(dState,State,M,e);
%
%  Inputs
%     dState   - Matrix of "Y" data (the independent variables)
%     State    - Matrix of "X" data (dependent variables; derivative)
%     M        - Projection matrix from LS regression
%     e        - Proportion (0 - 1) of original data explained by
%                 PCs that were used for jPCA estimate
%                 -> If not specified, default value is 1
%
%  Output
%     SS       - Struct with fields corresponding to sums of squares
%                 and square error etc.
%
% See also: analyze.jPCA, analyze.jPCA.jPCA

if nargin < 4
   e = 100;
end

% Get the percent explained based on eigenvalues of transform
% matrices:
[d1,d2] = size(M);
if d1 == d2
   [~,D] = eig(M);
else
   [~,D] = eig([M, zeros(d1,d1-d2)]);
end
explained = diag(abs(D)) ./ sum(diag(abs(D)));

% Initialize output data struct
SS = struct(...
   'explained_pcs',e,...
   'info',struct(...
      'M',M,...
      'explained',explained.'),...
   'TSS',[], ...    % Total sum-of-squares   
   'ESS',[], ...    % Explained sum-of-squares (model sum-of-squares or sum-of-squares due to regression, SSR)
   'RSS',[], ...    % Residual sum-of-squares (sum-of-squared estimate of errors, SSE)
   'Rsquared',[], ...
   'mu',[],  ...
   'explained',struct( ...
      'eig',[],...
      'varcapt',[],...
      'plane',struct,...
      'sort',struct) ...
   );


% Make M and Mskew in lower dims (less indexing notation):
proj = State * M;

SS.mu = mean(dState,1); % ybar; the mean of observed variables
ts = bsxfun(@minus,dState,SS.mu).^2; % Total squares
SS.TSS = sum(ts,1);         % Total sum-of-squares = Observed - mean(observed)
es = bsxfun(@minus,proj,SS.mu).^2;  % Explained squares
SS.ESS = sum(es,1);     % Explained sum-of-squares = Predicted - mean(observed)
rs = bsxfun(@minus,proj,dState).^2; % Residual squares
SS.RSS = sum(rs,1);  % Residual sum-of-squares = Observed - Predicted (element-wise)

ess = sum(es(:));
tss = sum(ts(:));
% rss = sum(rs(:));
SS.Total.Rsquared = ess/tss;
n = size(State,1);
p = size(State,2);
SS.Total.df_e = n - p - 1;
SS.Total.df_t = n - 1;
% SS.Total.Rsquared_adj = 1 - ((rss/SS.Total.df_e)/(tss/SS.Total.df_t));
SS.Total.Rsquared_adj = 1 - (1 - SS.Total.Rsquared)*(n - 1)/(n - p - 1);

% Percent of original "eigenspace" (from eigenvalue magnitudes):
SS.explained.eig = SS.info.explained .* e;
SS.Rsquared = SS.ESS ./ SS.TSS; 
SS.explained.varcapt = SS.Rsquared .* e; % Scale to percent of total data

% % Compute the sort order for planes by eigenvalues or R^2 % %
nDim = size(State,2);
nPlane = nDim/2;
SS.explained.plane.eig = sum(reshape(SS.explained.eig,2,nPlane),1);
SS.explained.plane.varcapt = sum(reshape(SS.explained.varcapt,2,nPlane),1);

% Get rankings by variance captured (R^2) %
[~,SS.explained.sort.plane.varcapt] = sort(SS.explained.plane.varcapt,'descend');
SS.explained.sort.vec.varcapt = plane2vec(SS.explained.sort.plane.varcapt);

% Get rankings by eigenvalues proportion %
[~,SS.explained.sort.plane.eig] = sort(SS.explained.plane.eig,'descend');
SS.explained.sort.vec.eig = plane2vec(SS.explained.sort.plane.eig);

   function vecIdx = plane2vec(planeIdx)
      %PLANE2VEC Convert jPC plane indices to matched jPC vector indices
      %
      %  vecIdx = plane2vec(planeIdx);
      %
      % Inputs
      %  planeIdx - Indices corresponding to jPC planes
      %
      % Output
      %  vecIdx   - Indices corresponding to jPC vectors
      
      vecIdx = [(planeIdx-1).*2+1; planeIdx.*2];
      vecIdx = vecIdx(:).';
   end
end