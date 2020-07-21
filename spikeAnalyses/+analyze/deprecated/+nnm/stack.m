function [S,C] = stack(S,colMask,varname,keyname,h0)
%STACK Output table to "stack" for `splitapply` workflow
%
%  [S,C] = analyze.nnm.stack(S);
%  [S,C] = analyze.nnm.stack(S,colMask);
%  [S,C] = analyze.nnm.stack(S,colMask,varname,keyname,h0);
%
%  -- Inputs --
%  S     : "Sliced" table, based on filtered rate table:
%                 ```
%                    T = getRateTable(gData); 
%                    S = analyze.slice(T,'Filter1','val',...);
%                 ```
%        
%  opts  : `statset` struct (e.g. `opts = statset('Display','off');`)
%  colMask : Logical indexing vector of size [1, size(S.Rate,2)].
%  varname : (Optional) Name of new variable
%  keyname : (Optional) Name of new key
%  h0 : (Optional) "guessed" h0
%
%  -- Output --
%  S : "Sliced" table updated with individual trial values. 
%        -> Contains additional "Key" variable for matching to coefficients
%  C : Table with actual PCA coefficients, means, and % explained

if nargin < 2
   colMask = true(1,size(S.Rate,2));
end

if nargin < 3
   varname = 'NNMF';
end

if nargin < 4
   keyname = 'NNMF_Key';
end

if nargin < 5
   h0 = analyze.nnm.load_init_factors(); 
end
K = size(h0,1);

% % Add "helper" repositories and get default "static" parameters % %
utils.addHelperRepos();
[opts,reps,alg] = defaults.nnmf_analyses('opts','reps','alg');

% % Make sure correct offset is applied to masked data % %
NNMF_Offsets = min(S.Rate(:,colMask),[],2);
Y = S.Rate - NNMF_Offsets;
[NNMF_Scores,NNMF_Coeffs,NNMF_D] = nnmf(Y(:,colMask),K,...
   'h0',h0,...
   'algorithm',alg,...
   'options',opts,...
   'replicates',reps);
Key = tag__.makeKey(1,'unique',[varname '_']);
[xc,i_new] = analyze.factor_pairs(h0,NNMF_Coeffs);
NNMF_Coeffs = {NNMF_Coeffs(i_new,:)};
NNMF_XCorr = {xc(i_new,:)};
NNMF_Offsets = {NNMF_Offsets};
C = table(NNMF_Coeffs,NNMF_Offsets,NNMF_XCorr,NNMF_D);
C.Properties.UserData.t = S.Properties.UserData.t(1,colMask);
nRow = size(S,1);

S.(keyname) = repmat(Key,nRow,1);
C.(keyname) = Key;
S.(varname) = NNMF_Scores(:,i_new); % Make sure to rearrange this as well
C = C(:,[end, 1:(end-1)]);

end