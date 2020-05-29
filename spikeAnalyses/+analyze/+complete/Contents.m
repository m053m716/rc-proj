% COMPLETE Analyses related to completed trials only
% MATLAB Version 9.7 (R2019b Update 5) 28-May-2020
%
%     <strong>------------------------------------------------</strong>
%     <strong>Completed Trials</strong>: Definitions
%     <strong>------------------------------------------------</strong>
%        1. A "Complete" video frame was tagged when the rat had fully
%           retracted its paw into the box and either brought its paw to 
%           its face or the last frame in which there was a retracting 
%           movement. A "Reach" video frame was tagged as the first frame
%           in which the rat began moving its paw through the box aperture
%           targeted towards retrieving the pellet.
%        2. If the rat reached and then immediately attempted a second 
%           attempt (i.e. "flailed at the pellet"), then the "Complete" 
%           time for that trial was scored as `infinite` and the trial 
%           itself was not flagged as a "completed" trial due to the 
%           non-stereotyped behavior present there, which would undoubtedly
%           conflate neurophysiological analysis and assessment of the 
%           more-subtle factors related to unsuccessful reaching during 
%           more-similar reaches compared between ischemic and intact
%           animals.
%        3. Trials were further screened for these analyses by the
%           following factors:
%              * "Duration" ("Complete" - "Reach") >= 100-ms and <= 750-ms
%              * "Reach," "Grasp," and "Complete" events are all present.
%              * A pellet is present ("PelletPresent"=='Present')
%              * Outcomes could be Successful or Unsuccessful.
%     ------------------------------------------------
%
% <strong>Initialize</strong>
%   get_subset  - Returns subset of full table for "Completed" trials analyses
%
% Functions
%   pca_table   - Makes table for export based on PCA factor loadings
%   view_coeffs - Make figures showing each row of `C` table of coefficients
%   view_scores - Plot PCA scores for grasps
