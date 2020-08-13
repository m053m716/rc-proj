%BEHAVIOR Behaviorally-related analyses (e.g. duration of trials etc)
% MATLAB Version 9.7 (R2019b Update 5) 28-May-2020
%
%  This package contains code to handle strictly behaviorally-related
%  endpoints: total time of each trial (i.e. speed of reach, although that
%  quantity was never directly computed) and the overall performance on a
%  given post-operative day.
%
% Data Functions
%  durations                  - Make figure(s) of durations by Animal using Rate Table
%  epochSpikeTrends           - Plot trends in spike rate for given epoch
%  epochSpikeTrends_Split     - Plot trends in spike rate for given epoch (split panels)
%  getDescriptiveTimingStats  - Returns updated UserData for descriptive stats
%  makeSupportAssociation     - Makes association between Support time & alignment
%  score                      - Estimates behavior score endpoints by BlockID or PostOpDay
%
% Graphics Functions
%  blocks                     - Shows figure(s) of response variable by Block using Rate Table
%  outcomes                   - Plot scatters of the 4 outcome response variables across days
%  show                       - Shows figure(s) of response variable by Animal using Rate Table