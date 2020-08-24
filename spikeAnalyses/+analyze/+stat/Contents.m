% +STAT Package for running Matlab statistical models
% MATLAB Version 9.7 (R2019b Update 5) 18-Jun-2020
%
% Helper (Math) Functions
%  batch_estimate_reconstruction_error - Redo reconstruction error estimate
%  fit_gauspuls                        - Function that goes to the fmincon procedure of fit_transfer_fcn for gauspuls fit
%  interpolateUniformTrend             - Interpolates trends between per-day averages
%  nonlinear_constraint                - Nonlinear constraint(s) on parameter array p
%  random_levels_2_double              - Helper to convert levels of random effects to numeric double to help match with original data
%  reconstruct_gauspuls                - Returns reconstructed Gaussian pulse modulated oscillation (primarily used in fit_gauspuls)
%  remove_excluded                     - Remove outlier data or categories otherwise not in model
%
% Graphics/Visualization Functions
%  addJitteredScatter                  - Adds jittered scatter plot to current axes
%  addLinearRegression                 - Helper for splitapply to add lines for animals
%  addLogisticRegression               - Helper for splitapply to add lines for animals
%  panelized_residuals                 - Plot generalized linear model residuals in panels
%  plot_example_fit                    - Plot example of reconstructed Gaussian-pulse oscillation
%  plot_glme_residuals                 - Plot generalized linear mixed-effects model residuals
%  plot_pc_summary                     - Plot PCs summarizing system fit
%  plotROC                             - Plot ROC for prediction model of Successful/Unsuccessful by trial
%  printFigs                           - Export vectorized figures for insertion to other documents etc
%  qPDP                                - Quick partial-dependence plot
%  scatter_var                         - Make grouped scatter plot of response variable by day
%  surf_partial_dependence             - Create partial-dependence plot (PDP) surface
%  surf_predicted                      - Visualize model prediction surface w.r.t. 2 variables
%
% Supplementary Functions
%  fit_full_spike_count_glme           - Fit "full" (fixed) Generalized Linear Mixed-Effects model for spike counts, incorporating all alignments of interest
%  fit_spike_count_glme                - Fit Generalized Linear Mixed-Effects model for spike counts
%  getCB95                             - Return 95% confidence bounds
%  groupLevelTests                     - Get statistical test for each {'Group','Area','Week'}level
%  parseLevelTests                     - Get statistical test for each row of `rWeek`
%  weekTrendTable                      - Return summary trend table by week 
%
% Main Functions
%  fit_transfer_fcn      - Get transfer function parameters and observation weights
%  get_fitted_table      - Return table for statistics after consolidating Rate using fmincon and gauspuls using fit_transfer_fcn