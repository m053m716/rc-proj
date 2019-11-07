%% MAIN     Main code for initializing and running analyses
close all force;
clear; clc;

%% Constants
% Note: correct indexing into gData depends on ordering of RAT in array
RAT = {     ...
   'RC-02'; ... 
   'RC-04'; ... 
   'RC-05'; ... 
   'RC-08'; ... 
   'RC-14'; ... 
   'RC-18'; ... 
   'RC-21'; ... 
   'RC-26'; ... 
   'RC-30'; ... 
   'RC-43'  ... 
   };
SKIP_SAVE = false;

%% Create the group data array (takes forever if rates must be extracted)
gData = construct_gData_array(RAT,SKIP_SAVE);

%% Set the cross-condition means and get condition response correlations
batch_set_xc_means_run_condition_response_correlations;
