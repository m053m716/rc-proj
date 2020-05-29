% NNM Package for non-negative matrix factorization analyses
% MATLAB Version 9.7 (R2019b Update 5) 28-May-2020
%
% <strong>Initialize</strong>
%   nnmf_table        - Makes table for export based on NNMF factor loadings
%
% Functions
%   append_meta       - Append metadata to `C` from `N` table
%   apply_exclusions  - Remove rows of [N,C] based on `get_exclusions` result
%   compare_factors   - Plot factor comparison between two NNMF factor sets
%   get_exclusions    - Get locations (indices) for excluded NNMF Blocks
%   get_init_factors  - Get factor estimates for K factors
%   load_init_factors - Load initial factor coefficients guess
%   stack             - Output table to "stack" for `splitapply` workflow
%   view_all_corrs    - Plot all cross-correlations for "main-diagonal" 
%   view_h0           - Make figures showing h0 for each row of h0
