%% MAIN  -- Deprecated -- Batch for main RC analysis functions (to stay organized)
%
%  This was written after the RC paper was rejected by Journal of
%  Neurophysiology. 
%
% By: Max Murphy  v1.0  07/30/2018  Original
%                 v1.1  08/15/2018  Remove some obsolete batch functions
%                                   that are no longer analyses under
%                                   consideration. Fix naming of sub-batch
%                                   scripts.
%                 v1.2  12/27/2018  Start over with just simple linear
%                                   analysis in epochs around behavior.

%% CLEAR WORKSPACE
clear; clc;
addpath('libs');

%% 00) Extract spikes
% cd ('spike-extract');
% batchEpochSD;
% cd('..');

%% 01) EXTRACT ALIGNED SPIKES AND LINEAR RATES
saveAlignment;

%% 02) PLOT SUPERIMPOSED RATES FOR EACH DAY, BY CHANNEL
plotRateByDay;

%% 03) EXPORT RATES FOR LFADS?


% %% 01) VISUALIZE BEHAVIORALLY-ALIGNED RASTERS
% cd('01_visualize-behavior-rasters');
% main__01;
% cd('..');
% 
% %% 02) GET RATE ESTIMATES USING LINEAR KERNEL
% cd('02_do-linear-smoothing');
% main__02; % NOTE: Doing the rate estimation takes a long time (~45 min?)
% cd('..');
% 
% %% 03) PLOT CHANNEL-WISE & ICMS-WISE RATE MODULATION
% cd('03_estimate-rate-progression');
% main__03; % NOTE: Loading the table with rates takes a long time (18 GB in physical memory)
% cd('..');
% 
% %% 04) GET KINEMATIC LABELS FROM DEEPLABCUT
% cd('04_DeepLabCut');
% main__04;
% cd('..');
% 
% %% 05) EXPORT KALMAN FILTER DECODING ACCURACY FOR STATISTICS
% cd('05_estimate-Kalman');
% main__05;
% cd('..');
% 
% %% 06) EXPORT STATS WORKSHEETS
% cd('06_stats');
% main__06;
% cd('..');
% 
% %% 07) MAKE SAMPLE FIGURES OF NEURAL RECORDINGS
% cd('07_plot-sample-rec');
% main__07;
% cd('..');