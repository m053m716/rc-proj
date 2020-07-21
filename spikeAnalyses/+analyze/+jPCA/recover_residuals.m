function P = recover_residuals(P,type)
%RECOVER_RESIDUALS Add struct array field '[type]_proj_resid'
%
%  P = analyze.jPCA.recover_residuals(P);
%  P = analyze.jPCA.recover_residuals(P,type);
%
% Inputs
%  P     - Projection array struct or cell array of such array structs
%           -> See: analyze.jPCA.jPCA output
%  type  - (Optional) 'best' | 'skew' | {'best','skew'} (default)
%
% Output
%  P     - Same as input, but with '[type]_proj_resid' field added
%           -> This field is the residual from the [type] projection using 
%              the fields `Z` (normalized state) and `dZ` 
%              (normalized state differences corresponding to `Z`)
%
% See also: analyze.jPCA, analyze.jPCA.jPCA

if nargin < 2
   type = {'best','skew'};
end

% Iterate on `Projection` cell array (if needed)
if iscell(P)
   for ii = 1:numel(P)
      P{ii} = analyze.jPCA.recover_residuals(P{ii},type);
   end
   return;
end
% Iterate on `type` cell array (if needed)
if iscell(type)
   for ii = 1:numel(type)
      P = analyze.jPCA.recover_residuals(P,type{ii});
   end
   return;
end

inputField = sprintf('M%s',lower(type));
outputField = sprintf('%s_proj_resid',lower(type));
matField_best = sprintf('M%s_res_best',lower(type));
matField_skew = sprintf('M%s_res_skew',lower(type));

M = P(1).misc.(inputField);
fProj = @(s)s.dZ - (s.Z * M);
fixTimeIndexing = @(Z)...
   [...
      Z(1,:);                            ... % Halfway between regular t1 and t2
      (Z(1:(end-1),:) + Z(2:end,:))./2;  ... % Regular t2 to regular t_(end-1)
      Z(end,:)                           ... % Halfway between regular t_(end-1) and t(end)
   ];

fRecover = @(s)fProj(s);
fResidual = @(s)fixTimeIndexing(fProj(s));
fTime = @(s)fixTimeIndexing(s.Zt);

rec = arrayfun(@(s)fRecover(s),P,'UniformOutput',false);
output = arrayfun(@(s)fResidual(s),P,'UniformOutput',false);
t = arrayfun(@(s)fTime(s),P,'UniformOutput',false);

[P.(outputField)] = deal(output{:});
[P.t_err] = deal(t{:});

% Recover linearized error dynamics using least-squares regression.
Mres_best = (vertcat(rec{:})' / vertcat(P.Z)')';
Mres_skew = analyze.jPCA.skewSymRegress(vertcat(rec{:}),vertcat(P.Z),eps)'; 

for ii = 1:numel(P)
   P(ii).misc.(matField_best) = Mres_best;
   P(ii).misc.(matField_skew) = Mres_skew;
end

end