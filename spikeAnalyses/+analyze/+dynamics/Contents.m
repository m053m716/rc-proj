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
%  exportSubTable             - Create table for GLME model fit, using only R^2_adj
%  exportTable                - Create table for GLME model fit
%  fp_classify                - Classify fixed-point for row of table D
%  getPredictionMask          - Return mask for matched samples for fitting prediction
%  parseSingleR2              - Used to update R^2 estimate for adjusted R^2 etc using proj
%  plotSliceSampleTrends      - Use model-based surrogates with slicesample to generate by-day trends with 95% confidence bounds
%  primary_regression_space   - Classify fixed point in primary regression space of least-squares optimal regression matrix of top PCs
%  primaryPCDynamicsByArea    - Test main PC "plane" by top PC of both area states
%
% Graphics
%  inputDistribution          - Plot observed distribution & smoothed cdf estimate
%  makeJointDistViz           - Visualize joint distribution between R2 & %-explained
%  plotPhaseQuiver            - Plot the phase portrait given M the linearized system
%  scatterR2andPerf           - Scatter R^2_BEST on x-axis and y-axis as behavioral perf
%  scatterR2ByDayAndExplained - Create scatter plot for R2 fit by day & % exp