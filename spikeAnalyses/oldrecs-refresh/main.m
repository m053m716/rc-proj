%% MAIN  Batch for keeping track of code to move old processed recordings

%% 0) LOAD FILE FOR RUNNING BATCH STUFF
clear; clc;
close all force;
load('J:\Rat\BilateralReach\Data\info.mat','block');

%% 1) LOAD BLOCK STRUCT FROM DISKSTATION AND SEND CORRECT BLOCKS TO ISILON
block([2,68:76]) = [];
sa = load('alert.mat','fs','sfx');
alertplayer = audioplayer(sa.sfx,sa.fs);
[F,surgDict] = moveToIsilon(block);
moveAlignmentToIsilon(block);
save('P:\Extracted_Data_To_Move\Rat\TDTRat\RC-tmp.mat','F','surgDict','-v7.3');
play(alertplayer,[1,sa.fs]);

%% 2) MAKE SURE "DIGITAL" FILES ARE IN CORRECT FORMAT
vidPath = 'K:\Rat\Video\BilateralReach\RC';
tankPath = 'P:\Extracted_Data_To_Move\Rat\TDTRat';

% Save "paw" and "beam" series
batchSavePawSeries(tankPath,vidPath);
batchSaveBeamSeries(tankPath);

% Generate correct format of "behaviorData" table using previous scoring
batchSaveScoring(block);
play(alertplayer,[1,sa.fs]);

%% -- DO VIDEO SCORING --

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% NOTE: AT THIS STAGE, SOME ADDITIONAL VIDEO SCORING IS NECESSARY IN      %
%       ORDER TO PROPERLY ASSOCIATE ALL METADATA WITH EACH TRIAL          %
%                                                                         %
% USE scoreVideo.m IN THE RC-PROJ REPO, WHICH HAS A GITHUB REMOTE AS WELL %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

cd('C:\MyRepos\shared\rc-proj\videoAnalyses');

%% 