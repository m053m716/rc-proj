% TRIALS  Package for all code applied to data at single-trial level
% MATLAB Version 9.7 (R2019b Update 5) 28-May-2020
%
% <strong>Initialize</strong>
%   make_table                - Create table where each row represents a trial
%
% Functions
%  addConfusionData           - Add variables: 'TP' 'FP' 'TN' 'FN' for confusion matrix
%  addCountVariables          - Adds count variables to data table in `r`
%  computeWeeklyChannelROC    - Compute area under curve for individual channel ROC and optionally plot the ROC
%  countSpikes                - Count spikes in binned vector x, given ts & interval (t1, t2]
%  fitOutcomeClassifier       - Fit classification model for individual channels to recover `predicted` label of each trial
%  getChannelWeeklyGroupings  - Returns weekly groupings table for unit_learning_stats
%  weeklyConfusion            - Return data for weekly confusion tabulation
%
% Graphics
%  plotChannelTrends          - Plot model fit per-channel trends across weeks
%  plotTableData              - Plot struct data tables for weekly spike counts
%  plotPosterior              - Plot posterior based on Naive Bayes classifier