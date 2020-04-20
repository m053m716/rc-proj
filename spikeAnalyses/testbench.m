%TESTBENCH  Script for constructing `group`, `rat`, and `block` objects
clear; 
clc; 
maintic = tic;
pars = defaults.experiment();

ratArray = [];
for ii = 1:numel(pars.rat) % ~ 2 minutes (have to manually score though)
% for ii = 9:numel(RAT) % debug for RC-30 issue with data_screening_UI
   ratArray = [ratArray; rat(fullfile(...
      'P:\Rat\BilateralReach\RC',pars.rat{ii}))]; %#ok<*AGROW>
end
toc(maintic);

%% SPLIT AND SAVE DATA AND CONDITIONAL SUB-GROUPS
gData = [group(pars.group_names{1},ratArray(pars.group_assignments{1}));
         group(pars.group_names{2},ratArray(pars.group_assignments{2}))];
s  = defaults.jPCA('jpca_start_stop_times');
align = defaults.jPCA('jpca_align');
objName = sprintf('ObjectData_%gms_to_%gms_%s.mat',s(1),s(2),align);
save(objName,'gData','-v7.3');

%% EXPORT AGGREGATE SUCCESSFUL RATE STATISTICS
stats = getChannelwiseRateStats(gData,'Grasp','Successful');
writetable(stats,'RateStats.xls');


%% GET AND ASSIGN DIVERGENCE DATA
J = getjPCA(gData,'Grasp','All','Unified.Full');
[Td,S,Cs] = plotProj3D(J);
T = exportDivergenceStats(J,Td,S,Cs);
assignDivergenceData(gData,T);
runFun(gData,'snapFrames');

%% GET PREMOTOR NEURAL VARIABILITY STATS
stats = getChannelwiseRateStats(gData,'Grasp','Successful');
plotNV(stats);

toc(maintic);