%% MAIN Analysis outline; use `help spikeAnalyses;` for details
%
%  Serves as an outline/notes for processing/analysis done in `rc-proj`
%  -> This is meant to be run one section at a time, and really shouldn't
%     be run all at once. Rather, note the .mlx files the relevant section
%     points to and load or generate the relevant tables to be able to
%     execute those files.
%
%  -- CAUTION : RUNNING THIS SCRIPT WILL USE A LOT OF MEMORY AND    --
%  --           TAKE FOREVER! "RUN ALL" AT YOUR OWN RISK!           --
%  --           IT WILL ALSO SAVE SOME LARGE-ISH TABLES LOCALLY     --
%  --           SO CHECK WHAT YOU WANT TO DO BEFORE CLICKING RUN!   --
%
%  General workflow, if `gData` has been generated:
%        ```
%           gData = group.loadGroupData;
%           T = getRateTable(gData); % Can specify other args
%        ```
%  Or, just load the saved rate table from matfile.
%
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
[gData,ticTimes] = construct_gData_array(rat,skip_save); % Auto-saves gData if skip_save is false

%% Export statistics tables
p = defaults.experiment('event_opts','rate_table_includes');
T = getRateTable(gData,p.event_opts,p.rate_table_includes,{'RFA','CFA'},...
   false,false); % (allow ~15-30 minutes)
save(defaults.files('rate_table_matfile'),'T','-v7.3'); % takes a while
t = applyTransform(T); % Then, apply transform
writetable(t,defaults.files('rate_csv')); clear t; % Remove from workspace
T = analyze.slice(T,...
   'Alignment',{'Reach','Grasp'},...
   'Outcome','Successful',...
   'PelletPresent','Present'); % Slice to subset of table
save(defaults.files('rate_table_default_matfile'),'T','-v7.3'); % Save smaller table also
clear gData; % Remove from workspace (temporarily)

%% Export single-channel spike rates
G = analyze.stat.get_fitted_table(T); % Takes a while
save(defaults.files('default_gauspuls_table'),'G','-v7.3');
clear G; % Remove from workspace (temporarily)

%% Export jPCA dynamics tables
opentoline(which('rates_to_jPCA.m'),1);
rates_to_jPCA; % It's already in script format
opentoline(which('main.m'),74);
clear;

%% Export raw spike rate counts table
A = {'Reach','Grasp','Support','Complete'};
pars = defaults.block('fname_norm_rate','spike_bin_w');
group.loadGroupData; % Re-load group data
for iA = 1:numel(A)
   runFun(gData,'updateSpikeRateData',A{iA},'All',pars);
end
save(defaults.files('group_data_file_raw_binned_version'),'gData','-v7.3');
R = getRateTable(gData,p.event_opts,p.rate_table_includes,{'RFA','CFA'},false,false);
save(defaults.files('raw_rates_table_file'),'R','-v7.3');
clear;
% % % Now all tables should be generated % % %

%% Run behavior statistics
opentoline(which('behavior_timing.mlx'),1);
matlab.internal.liveeditor.executeAndSave(which('behavior_timing.mlx'));
matlab.internal.liveeditor.openAndConvert(which('behavior_timing.mlx'),...
   fullfile(defaults.files('html_result_dir'),'Trial_Durations.html'));
opentoline(which('main.m'),97);

%% Run single-channel (raw & normalized) rate statistics
opentoline(which('raw_rate_stats.mlx'),1);
matlab.internal.liveeditor.executeAndSave(which('raw_rate_stats.mlx'));
matlab.internal.liveeditor.openAndConvert(which('raw_rate_stats.mlx'),...
   fullfile(defaults.files('html_result_dir'),'Raw_Rate_Stats.html'));
opentoline(which('single_channel_stats.mlx'),1);
matlab.internal.liveeditor.executeAndSave(which('single_channel_stats.mlx'));
matlab.internal.liveeditor.openAndConvert(which('single_channel_stats.mlx'),...
   fullfile(defaults.files('html_result_dir'),'Single_Channel_Stats.html'));
opentoline(which('main.m'),107);

%% Run population dynamics rate statistics
opentoline(which('population_dynamic_stats.mlx'),95);
matlab.internal.liveeditor.executeAndSave(which('population_dynamics_stats.mlx'));
matlab.internal.liveeditor.openAndConvert(which('population_dynamics_stats.mlx'),...
   fullfile(defaults.files('html_result_dir'),'Population_Dynamics_Stats.html'));
opentoline(which('main.m'),107);