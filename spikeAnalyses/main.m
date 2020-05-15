%% MAIN     Main code for initializing and running analyses
close all force;
clear; clc;

%% Constants
% Note: correct indexing into gData depends on ordering of RAT in array
pars = defaults.experiment();

%% Create the group data array (takes forever if rates must be extracted)
% Alternative: gData = group.loadGroupData(); --> Takes ~3.5 minutes
[gData,ticTimes] = construct_gData_array(pars.rat,pars.skip_save);

%% Export rate statistics
T = getRateTable(gData);
save(defaults.files('rate_table'),'T','-v7.3');
writetable(T,defaults.files('rate_csv'));

%% Check on rate principal components
% First, we just run the top 3 principal components and see how they look.
opts = statset('Display','off');
pc = analyze.pc.get(T,3,opts);
% Noticed here that smoothing introduces large artifact:
make.fig.check_nth_pc(pc,1); 
% (See: D:\MATLAB\Data\RC\scratchwork\PCA\Top-PC after rate smoothing.png)

% So, we need to get the correct indices to a subset of rates to use for
% computing the principal components so we don't introduce the large
% spurious first principal component:
t_start_stop = defaults.experiment('t_start_stop_reduced'); % (ms) -- avoid "edge effects"
pc = analyze.pc.get(T,3,opts,t_start_stop); 
make.fig.check_nth_pc(pc,3:-1:1); 
% Here, we noticed that PCs look like the overtones (or harmonics) of a
% standing wave, for example when a string is plucked
save(fullfile('D:\MATLAB\Data\RC\scratchwork\PCA','PC-Struct.mat'),...
   'pc','-v7.3'); % For future reference (on MAX-pc)

% Need to change the grouping indices and get combinatorial factors
P = make.pc_table(T,3,opts,t_start_stop);
