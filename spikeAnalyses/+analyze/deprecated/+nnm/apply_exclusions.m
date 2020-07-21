function [N,C,exclusions] = apply_exclusions(N,C,exclusions,keyVar)
%APPLY_EXCLUSIONS  Remove rows of [N,C] based on `get_exclusions` result
%
%  [N,C] = analyze.nnm.apply_exclusions(N,C,exclusions);
%  [N,C] = analyze.nnm.apply_exclusions(N,C,exclusions,keyVar);
%     -> If `keyVar` is different (for example key name 'Key' instead of
%        'NNMF_Key'), then this must be specified as fourth arg.
%
%  -- Inputs --
%  N : Table from `[N,C] = analyze.nnm.nnmf_table(T);`
%  C : Table from `[N,C] = analyze.nnm.nnmf_table(T);`
%  exclusions : Struct from `[~,~,~,~,exclusions] = get_exclusions(C);`
%                 (Optional); if not used, parsed from `C` automatically
%
%  -- Output --
%  [N,C] : Same as input, but with outlier rows excluded on the basis of
%           matches to "general" factors as well as RMS difference in
%           reconstruction from derived factors.
%
%  exclusions : Can be returned from this function if needed.

if nargin < 3
   [~,~,~,~,exclusions] = analyze.nnm.get_exclusions(C);
end

if nargin < 4
   keyVar = 'NNMF_Key';
end

% % Find list of "good" keys to keep % %
iKeep = setdiff(1:size(C,1),exclusions.Total.Indices);
goodKeys = C.(keyVar)(iKeep);

% % Keep good blocks only % %
exclusions.Removed = struct(...
   'C',ismember(C.(keyVar),goodKeys),...
   'N',ismember(N.(keyVar),goodKeys)...
   );

C = C(exclusions.Removed.C,:);
N = N(exclusions.Removed.N,:);

end