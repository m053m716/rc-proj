% +STAT Package for running Matlab statistical models
% MATLAB Version 9.7 (R2019b Update 5) 18-Jun-2020
%
% Deprecated Functions
%  get_glme_table       - Return table for generalized linear mixed effect regression
%  fit_vdp_ode          - Returns `mu` for Van der Pol oscillator & weight for GOF
%  plot_glme_pdp        - Plot generalized linear mixed-effects model partial-dependence plot
%
% Helper (Math) Functions
%  batch_estimate_reconstruction_error - Redo reconstruction error estimate
%  fit_gauspuls                        - Function that goes to the fmincon procedure of fit_transfer_fcn for gauspuls fit
%  nonlinear_constraint                - Nonlinear constraint(s) on parameter array p
%  reconstruct_gauspuls                - Returns reconstructed Gaussian pulse modulated oscillation (primarily used in fit_gauspuls)
%  remove_excluded                     - Remove outlier data or categories otherwise not in model
%
% Graphics/Visualization Functions
%  plot_example_fit     - Plot example of reconstructed Gaussian-pulse oscillation
%  plot_glme_residuals  - Plot generalized linear mixed-effects model residuals
%  plot_pc_summary      - Plot PCs summarizing system fit
%  printFigs            - Export vectorized figures for insertion to other documents etc
%
% Main Functions
%  fit_transfer_fcn     - Get transfer function parameters and observation weights
%  get_fitted_table     - Return table for statistics after consolidating Rate using fmincon and gauspuls using fit_transfer_fcn

