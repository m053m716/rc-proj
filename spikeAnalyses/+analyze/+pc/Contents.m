% PC Package for principal components-related analyses and reconstructions
% MATLAB Version 9.7 (R2019b Update 5) 28-May-2020
%
% <strong>Initialize</strong>
%   pca_table                 - Makes table for export based on PCA factor loadings
%
% Functions
%   apply                     - Applies PCA using `splitapply` built-in syntax
%   get                       - Gets PCs by groupings
%   reconstruct               - Reconstruct data from Scores, Coefficients, and Offsets
%   stack                     - Output table to "stack" for `splitapply` workflow
%   view_coeffs               - Make figures showing each row of `C` table of coefficients
%
% Graphics
%	perChannelPCgplotMatrix   - Group matrix scatter for top-3 PCs
%   perChannelPCtrends        - Create stem and trend plots for PC data struct
%   perChannelPCtrendscatter  - 3D scatter of coefficients for PC trends