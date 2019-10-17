%% TESTBENCH Main code for generating the array of GROUP, RAT, and BLOCK objects

clear; 
clc; 
maintic = tic;

RAT = {     ...
   'RC-02'; ... % re-extract spike rates
   'RC-04'; ... % re-extract spike rates
   'RC-05'; ... % re-extract spike rates
   'RC-08'; ... % re-extract spike rates
   'RC-14'; ... % re-extract spike rates
   'RC-18'; ... % re-extract spike rates
   'RC-21'; ... % re-extract spike rates
   'RC-26'; ... % re-extract spike rates
   'RC-30'; ... % re-extract spike rates
   'RC-43'  ... % re-extract spike rates
   };

ratArray = [];
for ii = 1:numel(RAT) % ~ 2 minutes (have to manually score though)
% for ii = 9:numel(RAT) % debug for RC-30 issue with data_screening_UI
   ratArray = [ratArray; rat(fullfile(...
      'P:\Rat\BilateralReach\RC',RAT{ii}))]; %#ok<*AGROW>
end
toc(maintic);

%% SPLIT AND SAVE DATA AND CONDITIONAL SUB-GROUPS
gData = [group('Ischemia',ratArray([1:4,8:9]));
         group('Intact',ratArray([5:7,10]))];
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