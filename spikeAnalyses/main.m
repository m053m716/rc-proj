%% MAIN Analysis outline; use `help spikeAnalyses;` for details
%
%  Serves as an outline/notes for processing/analysis done in `rc-proj`
%
%  Note: if matfile containing `gData` variable (`group` class object)
%        already exists, then a standard workflow consists of:
%        ```
%           gData = group.loadGroupData;
%           T = getRateTable(gData); % Can specify other args
%        ```
%        Once in the "table" format (`T`) many of the ensuing analyses take
%        just that table as the argument, for example:
%        ```
%           % Get subset of table to use for "failures" analyses:
%           U = analyze.fails.get_subset(T);
%           [P,C] = analyze.successful.pca_table(U,4);
%        ```
%        or
%        ```
%           % Get subset of table to use for nullspace analyses:
%           X = analyze.nullspace.get_subset(T);
%        ```
%        or
%        ```
%           % Get subset of table to use for non-negative matrix factors:
%           [N,C,exclusions] = analyze.nnm.nnmf_table(T,false);
%        ```

%% Clear the workspace and command window
close all force;
clear; clc;

%% Load constants into workspace
% Note: correct indexing into gData depends on ordering of RAT in array
[rat,skip_save] = defaults.experiment('rat','skip_save');

%% Create the group data array (takes forever if rates must be extracted)
% Alternative: gData = group.loadGroupData(); --> Takes ~3.5 minutes
[gData,ticTimes] = construct_gData_array(rat,skip_save);

%% Export rate statistics
% Force save non-smoothed Rates:
T = getRateTable(gData,[],[],[],true,false); % (allow ~15-30 minutes)
T = applyTransform(T); % Then, apply transform and overwrite variable 
                       % (large table; saves workspace memory)
writetable(T,defaults.files('rate_csv'));

%% Check on rate principal components
% First, we just run the top 3 principal components and see how they look.
opts = statset('Display','off');
% Note that `analyze.pc.get` uses `splitApply` to just try and find the
% "best fit" for the pcs rather than a homogeneous set of factors
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

% Now we know what the factors look like when not "aligned" in any
% particular fashion when we break down individual recording sessions into
% their primary components. We will now apply PCA to an aggregate matrix of
% spike rates in which each row is a trial (so columns, which are time
% samples, are "variables"). Before any statistics, we are pretty confident
% that the following variables will already have a drastic effect on the
% observed rate profiles:
%
%  * Alignment (Grasp, Reach, Completion, Support)
%  * Outcome (Successful, Unsuccessful)
%  * Group (Intact, Ischemic)
%  * Area (CFA, RFA)
%
%  We're not immediately interested in those differences, which will
%  complicate the analysis (for now). We will narrow our dataset to only 
%  include the following types of rows (observations):
%
%  * Alignment: {Grasp,Reach}
%  * Outcome: Successful
%
%  With the reduced dataset, each PCA will be applied to rate matrices 
%  in which observations will have different values for the following
%  metdata:
%
%  * Animal [Random effect]
%  * Post-Op Day (should correlate with rehabilitation)
%  * Recording Channel [Random effect]
%  * Behavioral Trial  [Each "Trial" has an ID]
%
%  So, ultimately, we will iterate on 2x Alignment, 2x Group, and 2x Area
%  giving us 8 different categories for our PCA table that keeps track of
%  the principal component coefficients.

[P,C] = analyze.pc.pca_table(T,t_start_stop);

%% Non-negative matrix factorization (NNMF)
% Apply non-negative matrix factorization (NNMF) to successful elements
% from all animals. 

% Get initialization guesses
% h0 = analyze.nnm.get_init_factors(T,8);
% save('D:\MATLAB\Data\RC\2020_NNMF\NNMF_h0.mat','h0','-v7.3');

% Return NNMF table (N) for whole dataset, to be exported
[N,C,exclusions] = analyze.nnm.nnmf_table(T,false);

