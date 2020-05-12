function F = run_Kinematic_extraction(varargin)
%% RUN_KINEMATIC_EXTRACTION  Batch script for handling DeepLabCut part of RC analyses
%
%  F = RUN_KINEMATIC_EXTRACTION
%  F = RUN_KINEMATIC_EXTRACTION('NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%  varargin    :     (Optional) 'NAME' value input argument pairs.
%
%  --------
%   OUTPUT
%  --------
%     F        :     Struct array (in DIR format) of all DLC files that
%                       were actually extracted.
%
% By: Max Murphy  v1.0  07/24/2018  Original version (R2017b)
%                 v1.1  07/30/2018  Added manually scored video times

%% DEFAULTS
% General experimental parameters
E_PRE = 2.0;                % Epoch before grasp
E_POST = 1.0;               % Epoch after grasp
FRAME_RATE = 30000/1001;    % Video framerate

% For batch script execution:
LOW_D_DATA_SAVE_PATH = fullfile(pwd,'Pose_Data');

% For rlm_importDeepLabCutLabeling:
VAR_NAMES = {'frame', ...
             'd1_d_x','d1_d_y','d1_d_p', ... % Distal digit-1
             'd1_p_x','d1_p_y','d1_p_p', ... % Proximal digit-1
             'd2_d_x','d2_d_y','d2_d_p', ...
             'd2_p_x','d2_p_y','d2_p_p', ...
             'd3_d_x','d3_d_y','d3_d_p', ...
             'd3_p_x','d3_p_y','d3_p_p', ...
             'd4_d_x','d4_d_y','d4_d_p', ...
             'd4_p_x','d4_p_y','d4_p_p', ...
             'hand_x','hand_y','hand_p', ...
             'pellet_x','pellet_y','pellet_p', ...
             'support_x','support_y','support_p'}; % support hand

START_ROW = 4;                               % First row after header
END_ROW = inf;                               % Last row to read until
READ_IN_DELIM = ',';                         % Within-line delimiter
END_OF_LINE = '\r\n';                        % End-of-line indicator
DIR = 'P:\Rat\BilateralReach\Kinematics\RC'; % Location of data

% For rlm_thresholdDeepLabCutLabels:
MARKER_THRESH = 0.95;    % Exclude markers below this threshold
SUPPORT_THRESH = 0.95;   % Support limb detection threshold
PELLET_THRESH = 0.99;    % Pellet detection threshold
VAR_NAME_DELIM = '_';    % Delimiter for different info in variable names

% For rlm_plotDeepLabCutThresholdedOutput:
VID_DIMS = [0 708; 0 384];
N_BINS = 100;               % # bins per dimension for 2D pellet histogram
X_PEL_LIM = [-30 30];     % X - Pellet ROI zone limits
Y_PEL_LIM = [-10 20];    % Y - Pellet ROI zone limits
DEBOUNCE = 1.5;             % Debounce time (sec)
N_PLOT = 9;                 % Number to plot
N_CANDIDATE = 10;           % Number of candidate pellet peaks
CLOSE_FIGURES = true;       % Close figures for batch running

% -> No additional params for rlm_estimateDeepLabCutPose

% For rlm_pose2features:
N_INTERP = 600;          % (300 = bins of ~5 ms for -1.0 to +0.5 sec)
NUM_DIMENSIONS = 3;      % Number of t-SNE embedded dimensions
PERPLEXITY = 6;          % Perplexity parameter for t-SNE
EXAGGERATION = 4;        % Exaggeration parameter for t-SNE
MIN_DIM_PCT = 0.66;      % Minimum percent of features to compute t-SNE
ROI_TOL = 125;

% For batch_genClusterFigs:
T_SLICE = -0.2:0.2:0.2;           % Relative time to group poses
TRIAL_CLUSTER_FIG_SAVE_PATH = fullfile(pwd,'Trial_Cluster_Figures');
TRIAL_DATA_SAVE_PATH = fullfile(pwd,'Trial_Cluster_Data');

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% Get a list of *.csv files to import to iterate on
load('..\info.mat','block');
F = [];
iB = 1;
while iB <= numel(block) %#ok<*NODEF>
   in = dir(fullfile('K:\Rat\Video\BilateralReach\RC\',...
      [block(iB).name '*.csv']));
   if isempty(in)
      block(iB) = []; %#ok<*AGROW,*SAGROW>
   else
      iB = iB + 1;
      F = [F; in]; 
   end
end

%% Loop on that list
tic;
iF = 1;
while iF <= numel(F)
   % Get markerless label pixel estimates from DeepLabCut model:
   T = importDLC(F(iF).name,START_ROW,END_ROW,...
         'DELIM',READ_IN_DELIM,...
         'DIR',DIR,...
         'END_OF_LINE',END_OF_LINE,...
         'VAR_NAMES',VAR_NAMES);  
   P = thresholdDLClabs(T);
   
   % Make exemplars of candidate "grasp" trajectories and get a list of
   % times around which those trajectories are centered:
   nameIdx = regexp(F(iF).name,'_Deep')-1;                      
             
   blockIdx = ismember(blockNames,F(iF).name(1:16));
   if (sum(blockIdx) < 1)
      fprintf(1,'No block corresponding to %s. Skipped.\n',F(iF).name(1:16));
      F(iF) = [];
      continue;
   elseif (sum(blockIdx) > 1)
      fprintf(1,'Multiple blocks corresponding to %s. Skipped.\n',F(iF).name(1:16));
      F(iF) = [];
      continue;
   end
   
   % Use local stuff in slightly different format, instead
   scoreFile = fullfile(block(blockIdx).folder,...
            block(blockIdx).name,...
            [block(blockIdx).name '_Scoring.mat']);
   if exist(scoreFile,'file')==0
      fprintf(1,'File not found: %s. Skipped.\n',scoreFile);
      F(iF) = [];
      continue;
   else
      load(scoreFile,'VideoStart');
   end
   
   load(['..\aligned\' block(blockIdx).name '_aligned.mat'],'grasp');
   tPellet = [grasp.s.'; grasp.f.'] - VideoStart;
   
   % Estimate kinematic "snippets" around times where the paw may have
   % entered the zone where the pellet typically is:
   pose = estimateDLCpose(P,tPellet,...
            'E_PRE',E_PRE,...
            'E_POST',E_POST,...
            'FRAME_RATE',FRAME_RATE);
   
   % For each trial, estimate an interpolated trajectory for each
   % markerless feature that is being tracked, and use that to compute
   % "embeddings" with the t-SNE algorithm. The motivation for this is to
   % generate low-dimensional representations of markers corresponding to
   % movement, so that different types of behaviors for the same task can
   % be segmented into groups and then properly dealt with from there:
   nTrial = size(pose,1);
   data = cell(nTrial,1);
   h = waitbar(0,'Please wait, computing embeddings...');
   for k = 1:nTrial
      data{k} = interpolatePose(pose,k,...
               'N_INTERP',N_INTERP,...
               'NUM_DIMENSIONS',NUM_DIMENSIONS,...
               'PERPLEXITY',PERPLEXITY,...
               'EXAGGERATION',EXAGGERATION,...
               'FRAME_RATE',FRAME_RATE,...
               'MIN_DIM_PCT',MIN_DIM_PCT);
      waitbar(k/nTrial);
   end
   delete(h);
   
   
   if exist(LOW_D_DATA_SAVE_PATH,'dir')==0
      mkdir(LOW_D_DATA_SAVE_PATH);
   end
   
   poseDataName = fullfile(LOW_D_DATA_SAVE_PATH,...
                           [block(blockIdx).name '_pose.mat']);
   tPellet = [pose.ts].';                     
   save(poseDataName,'data','tPellet','pose','-v7.3');
   
   
   % For all trials, extract pose "class" based on high-dimensional
   % features (i.e. position of lots of markerless tracking labels, with
   % respec to "X" and "Y" pixel dimension). This could be useful for
   % grouping similar styles of behavior together or eliminating common
   % noise modes.
   if exist(TRIAL_CLUSTER_FIG_SAVE_PATH,'dir')==0
      mkdir(TRIAL_CLUSTER_FIG_SAVE_PATH);
   end  
   
   trialFigName = fullfile(TRIAL_CLUSTER_FIG_SAVE_PATH,...
                           [F(iF).name(1:nameIdx) '_trialClusters']);
   
   trial = batch_genClusterFigs(data,T_SLICE,...
      'SAVE_AS',trialFigName,...
      'ROI',ROI,...
      'ROI_TOL',ROI_TOL);
   
   if exist(TRIAL_DATA_SAVE_PATH,'dir')==0
      mkdir(TRIAL_DATA_SAVE_PATH);
   end 
   
   trialDataName = fullfile(TRIAL_DATA_SAVE_PATH,...
                           [F(iF).name(1:nameIdx) '_trial.mat']);
   save(trialDataName,'trial','-v7.3');
   
end
toc; % Roughly, 5 hours on HP Z230 desktop with 32 GB RAM

end