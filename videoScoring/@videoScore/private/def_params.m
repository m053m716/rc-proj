function videoScoreObj = def_params(videoScoreObj)
%% DEF_PARAMS  Sets default parameters for VIDEOSCORE object
%
%  videoScoreObj = DEF_PARAMS(videoScoreObj);
%
% By: Max Murphy  v1.0  08/09/2018  Original version (R2017b)

%% Modify default private properties here
videoScoreObj.DEF_DIR = 'P:\Rat\BilateralReach\Murphy';
videoScoreObj.DIR = nan;
videoScoreObj.ALIGN_ID = '_VideoAlignment.mat';
videoScoreObj.BUTTON_ID = '_ButtonPress.mat';
videoScoreObj.SCORE_ID = '_Scoring.mat';

end