%BEHAVIOR Behaviorally-related analyses (e.g. duration of trials etc)
% MATLAB Version 9.7 (R2019b Update 5) 28-May-2020
%
%  This package contains code to handle strictly behaviorally-related
%  endpoints: total time of each trial (i.e. speed of reach, although that
%  quantity was never directly computed) and the overall performance on a
%  given post-operative day.
%
% Data Functions
%  durations                     - Make figure(s) of durations by Animal using Rate Table
%  epochSpikeFits                - Plot smoothed model trends in spike rate for given epoch (split by Area/Group)
%  epochSpikeFits_Animals        - Plot smoothed trends in per-animal spike rate for given epoch (split by Area/Group)
%  epochSpikeFits_Split          - Plot smoothed model trends in spike rate for given epoch (split panels)
%  epochSpikeTrends              - Plot trends in spike rate for given epoch
%  epochSpikeTrends_Split        - Plot trends in spike rate for given epoch (split panels)
%  getDescriptiveTimingStats     - Returns updated UserData for descriptive stats
%  makeSupportAssociation        - Makes association between Support time & alignment
%  mergePredictionData           - Merge data from prediction models with data table
%  mergeRatePerformance          - Merge rate (count) table and performance table
%  score                         - Estimates behavior score endpoints by BlockID or PostOpDay
%  writeUTrialsTable             - Write/return table with descriptive Duration stats
%
% Graphics Functions
%  bar_animal_counts             - Create bar plot figure of counts or ratios
%  blocks                        - Shows figure(s) of response variable by Block using Rate Table
%  makeDurationDensities         - Make figure with duration overlays for different epochs of behavior, by groupings
%  outcomes                      - Plot scatters of the 4 outcome response variables across days
%  per_animal_trends             - Plot per-animal trends
%  per_animal_mean_trends        - Plot per-animal (mean) trends
%  per_animal_area_mean_rates    - Plot per-animal, per-area (mean) RATE trends
%  per_animal_area_mean_trends   - Plot per-animal, per-area (mean) trends
%  show                          - Shows figure(s) of response variable by Animal using Rate Table
%  surfSampleTrend               - Surface: x - PostOpDay, y - % Explained, z - R^2_MLS