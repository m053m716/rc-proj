%DYNAMICS  Analyses of static linearized dynamics during behavior
% MATLAB Version 9.9 (R2020b Prerelease) 21-July-2020
%
%  This package contains code to handle static linearized dynamics during
%  behavior. Specifically, code pertains to classification of fixed points
%  in the primary neural state space, as well as code to break down
%  contribution from each area using the primary principal component and
%  applying a linearized static dynamics model to that.
%
%  Most functions should take as an input the `D` table that is returned by
%  ```
%     D = analyze.jPCA.multi_jPCA(M);
%     % or
%     load(defaults.files('multi_jpca_long_timescale_matfile'),'D');
%  ```
%  See also: analyze.jPCA, analyze.jPCA.multi_jPCA, defaults.files
%
% Functions
%  primary_regression_space - Classify fixed point in primary regression space of least-squares optimal regression matrix of top PCs