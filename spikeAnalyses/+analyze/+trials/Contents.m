% TRIALS  Package for all code applied to data at single-trial level
% MATLAB Version 9.7 (R2019b Update 5) 28-May-2020
%
% <strong>Initialize</strong>
%   make_table                - Create table where each row represents a trial
%
% Functions
%  addCountVariables          - Adds count variables to data table in `r`
%  countSpikes                - Count spikes in binned vector x, given ts & interval (t1, t2]
%  getChannelWeeklyGroupings  - Returns weekly groupings table for unit_learning_stats
%
% Graphics
%  plotChannelTrends          - Plot model fit per-channel trends across weeks
%  plotTableData              - Plot struct data tables for weekly spike counts