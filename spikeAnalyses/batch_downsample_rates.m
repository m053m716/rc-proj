%% BATCH_DOWNSAMPLE_RATES  Batch script to downsample high-resolution rate estimates
%
clc;

%% Load data (if not in workspace already)
if exist('gData','var')==0
   clear; 
   load('Updated_Scoring_gData.mat','gData');
else
   clearvars -except gData
end

%% Do batch run of downsampling (assuming LONG rate extraction done already)
% Before doing this, check defaults.block to make sure that the settings
% for downsampling are appropriately set.
maintic = tic;
runFun(gData,'doRateDownsample');

%% Do batch update to associate newly-downsampled/filtered rates with blocks
outcome = defaults.block('all_outcomes');
align = defaults.block('all_events');
for iO = 1:numel(outcome)
   for iA = 1:numel(align)
      updateSpikeRateData(gData,align{iA},outcome{iO});
   end
end
save('Updated_Scoring_gData.mat','gData','-v7.3');
toc(maintic);