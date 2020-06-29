% JPCA Package to apply jPCA analysis 
%  (see many helpful works by John P. Cunningham & Mark Churchland et al)
%   This package contains slight modifications to original code, as well as
%   additions to documentation added by Max Murphy as he learned the 
%   concepts related to the contained analyses. 
%
%   It's strongly recommended that you retrieve the unmodified <a href="https://www.dropbox.com/sh/2q3m5fqfscwf95j/AAC3WV90hHdBgz0Np4RAKJpYa?dl=0">source code</a> 
%   that was meant for distribution from the original authors directly. 
%
%   See other useful source code here:
%
%     https://churchland.zuckermaninstitute.columbia.edu/content/code
%
% Notes: <strong>Data Format</strong>
%   ---------------------------------------------------------------------
%     You must organize your data the way that the example structure 'Data'
%     is organized. Data should be a structure that is at least one element
%     long. For the example, 'Data' is 27 elements long, one for each 
%     condition (reach type) that the monkey performed.  If you have only 
%     one condition (e.g., when we analyze a 30 second period of walking) 
%     then you will just have one element. Data.A should be a matrix, with 
%     time running vertically (rows) and neurons (channels) running 
%     horizontally (columns). This is the same format as when using the 
%     built-in <a href="matlab:help pca">PCA</a>. Data.times should be some 
%     set of times that you understand.  You will ask for the analysis / 
%     plots to apply to subsets of these times.
%   ---------------------------------------------------------------------
%
% Math Helper Functions
%   averageDotProduct               - Get the average dot product with a comparison angle
%   convert_Mskew_to_jPCs           - Convert projection matrix to jPC vector pairs
%   getPhase                        - Get the phase for a given plane over its timecourse
%   getPlane                        - Return plane `i` from data struct or matrix
%   getRealVs                       - Get the real analogue of the eigenvectors
%   minimize                        - Minimize a differentiable multivariate function. 
%   minusPi2Pi                      - Return value in range [-pi,pi]
%   multi_jPCA                      - Apply jPCA to short segments of `Data` focused on tagged events
%   recover_explained_variance      - Return struct with % explained var, etc.
%   reshapeSkew                     - Reindexes a vector to a matrix or vice versa
%   skewSymLSeval                   - Evaluates distance & derivative, imposing skew symmetry on M
%   skewSymRegress                  - Apply least-squares regression to recover skew-symmetric M
%   updateState                     - Update `state_rot` field of Projection data struct array
%   zeroCenterPoints                - Ensures that element "zero_index" starts at 0
%
% Deprecated or Unused Functions: Residual from halted modifications
%   format                          - Convert data to format used by <a href="matlab:help analyze.jPCA.jPCA">jPCA</a> (specific to Cortical Plasticity Lab; moved to `deprecated` but still works for some formats)
%   formatWarped                    - Convert "warped" rate data <strong>deprecated</strong>
%   export_jPCA_movie               - Export movie created by <a href="matlab:help analyze.jPCA.phaseMovie">phaseMovie</a> <strong>deprecated</strong>
%   reshapeSkew_orth                - Reshape matrix for minimization with increased constraints <strong>deprecated</strong>
%   skewSymLSeval_orth              - Evaluate LS function with increased constraint from SKEWSYMLSEVAL <strong>deprecated</strong>
%   skewSymRegress_orth             - Find sets of orthogonal subspaces with rotatory structure <strong>deprecated</strong>
%
% Graphics Helper Functions
%   arrowMMC                        - Returns nice "arrow" for animated vectors, etc.
%   AxisMMC                         - plots an axis / calibration
%   blankFigure                     - produces a blank figure with everything turned off
%   circle                          - Return a circle or ellipse object
%   plotMultiRosette                - Plot multiple rosettes
%   printFigs                       - Export vectorized figures for insertion to other documents etc
%   RC_cmap                         - Returns specific color map for RC project success vs fail trials
%   rotate2jPCA                     - Rotate a trajectory to the corresponding jPCA projection
%   rotationMovie                   - This is a hastily written and not well commented function.
%   stemPCvariance                  - Stem plot of variance explained per Principal Component
%
% Export Functions
%   export_table                    - Create table that can be exported for JMP statistics
%
% <strong>Main Functions</strong>
%   convert_table                   - Converts from table format to jPCA struct array format
%   jPCA                            - Recover rotatory projections from spiking rate time-series
%
% <strong>Main Visualization Tools</strong>
%   phaseMovie                      - For making rosette movies for the paper
%   phaseSpace                      - For making publication quality rosette plots
%   plotPhaseDiff                   - Plots histogram of angle between dx(t)/dt and x(t) 
%   plotRosette                     - Plot the rosette (lines with arrows) itself
%
% Scripts
%   example                         - Get `example.mat` dataset from the <a href="https://www.dropbox.com/sh/2q3m5fqfscwf95j/AAC3WV90hHdBgz0Np4RAKJpYa?dl=0">source website</a>