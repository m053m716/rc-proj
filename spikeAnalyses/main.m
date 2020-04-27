%% MAIN     Main code for initializing and running analyses
close all force;
clear; clc;

%% Constants
% Note: correct indexing into gData depends on ordering of RAT in array
pars = defaults.experiment();

%% Create the group data array (takes forever if rates must be extracted)
% Alternative: gData = group.loadGroupData(); --> Takes ~3.5 minutes
[gData,ticTimes] = construct_gData_array(pars.rat,pars.skip_save);

%% Set marginal rate averages
batch_marginal_rate_averages;

%% Set the cross-condition means and get condition response correlations
% batch_set_xc_means_run_condition_response_correlations;
