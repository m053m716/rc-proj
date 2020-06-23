% +ANALYZE Package for analyses of spike data
% MATLAB Version 9.7 (R2019b Update 5) 28-May-2020
%
% ------------------------------------------------------------------------
% <strong>A note about Matlab packages:</strong> Matlab package notation 
% essentially creates a "namespace" such that any folder starting with a 
% '+' can be thought of as "on the search path" if that folder is within 
% the Current Folder. To address functions contained inside a "package" 
% folder, simply use '.' notation. For example:
%
% >> S = analyze.slice(T);
%
% This function reference could be achieved in a similar way:
%
% >> import analyze.* % Imports whole `+analyze` package
% >> S = slice(T);
%
% However, then you can run into naming conflicts, etc. so it's suggested
% to keep references in the long form with 'dot'-notation to avoid
% potential conflicts.
% ------------------------------------------------------------------------ 
%
% <strong>Functions</strong> (Common to several analytical flows)
%   factor_pairs - Gives factor cross correlations, as well as indexing
%   example      - Returns random rows from table T (always includes first/last row)
%   slice        - Return "sliced" table using filters in `varargin`
%   sliceRate    - Return "sliced" table & rate using filters in `varargin`
%
% <strong>Sub-Packages</strong> (Track different analytical flows)
%   behavior     - Behaviorally-related analyses (e.g. duration of trials etc)
%   complete     - Analyses related to completed trials only
%   fails        - Analyses related to failed trials only
%   jPCA         - Code from 2006 jPCA Nature paper (credit: Mark Churchland & John P Cunningham)
%   marg         - Package containing functions corresponding to `marg.mlx`
%   nnm          - Package for non-negative matrix factorization analyses
%   nullspace    - Package for relating nullspace activity at different task-relevant epochs
%   pc           - Package for principal components-related analyses and reconstructions
%   rec          - Package for all code applied to data at single-recording level
%   stat         - Package for running Matlab statistical models
%   trials       - Package for all code applied to data at single-trial level
