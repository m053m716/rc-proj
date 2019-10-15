%% BATCH_DOWNSAMPLE_RATES  Batch script to downsample high-resolution rate estimates

clear; clc;
load('allBlocks.mat','F');
for iF = 1:numel(F)
% for iF = 143:numel(F)
   blockObj = block(fullfile(F(iF).folder,F(iF).name));
   clear blockObj;
end