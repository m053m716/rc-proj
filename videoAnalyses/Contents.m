% VIDEOANALYSES All analyses in RC-Project related to video scoring and metadata alignment etc.
% MATLAB Version 9.7 (R2019b Update 5) 28-May-2020
%
%  Once videos were aligned and metadata was tagged using the pipeline in
%  this sub-folder, analyses were completed using the code contained in the
%  <a href="matlab:cd('../spikeAnalyses');help contents">spikeAnalyses</a> sub-folder.
%
% Helper Classes
%   alignInfo           - Class to keep track of video alignment and update graphics HUD on changes
%   behaviorInfo        - Class to keep track of behavior information and update graphics HUD
%   graphicsUpdater     - Class that implements video scoring UI video frame updates
%   vidInfo             - Class to update graphics HUD with video information
%
% Helper Packages
%   utils               - Package containing miscellaneous utility functions
%
% Helper Functions
%   batch_add_table_var - Batch script to add variable to behaviorData tables
%   trackVideoScoring   - Keep track of video scoring progress
%
% <strong>Main Functions</strong> (Most user interactions with these 2)
%   alignVideo          - Aligns neural data and video so reaching time stamps match
%   scoreVideo          - Locates successful grasps in behavioral video
