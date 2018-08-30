function scoreVideo(varargin)
%% SCOREVIDEO  Locates successful grasps in behavioral video.
%
%  SCOREVIDEO;
%  SCOREVIDEO('NAME',value,...);
%  
% Modifed by: Max Murphy   v3.0  08/07/2018  Basically modified the whole
%                                            thing. Changed to
%                                            object-oriented structure.

%% DEFAULTS
DEF_DIR = 'J:\Rat\BilateralReach\Data';
DIR = nan;

ALIGN_ID = '_VideoAlignment.mat';
BUTTON_ID = '_ButtonPress.mat';
SCORE_ID = '_Scoring.mat';

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% GET VIDEO FILE(S)
if isnan(DIR)
   DIR = uigetdir(DEF_DIR,'Select recording BLOCK');
   if DIR == 0
      error('No BLOCK selected. Script aborted.');
   end
end

addpath('utils');

Name = strsplit(DIR, filesep);
Name = Name{end};

vid_F = dir(fullfile(DIR,[Name '*.avi']));         % Video files
align_F = dir(fullfile(DIR,[Name '*' ALIGN_ID]));    % Alignment files


%% LOAD BEHAVIOR DATA

fname = fullfile(DIR,[Name SCORE_ID]);
if exist(fname,'file')~=0
   load(fname,'behaviorData');
   
else
   tmp = load(fullfile(DIR,[Name BUTTON_ID]),'button');
   Button = tmp.button;
   Button = reshape(Button,numel(Button),1);
   
   Reach = nan(size(Button));
   Grasp = nan(size(Button));
   Outcome = nan(size(Button));
   Forelimb = repmat('?',size(Button,1),1);
   
   behaviorData = table(Button,Reach,Grasp,Outcome,Forelimb);
   save(fname,'behaviorData');
   fprintf(1,'Scoring file for %s created.\n',Name);
   
   
end

VideoStart = nan(size(align_F));
for ii = 1:numel(align_F)
   in = load(fullfile(DIR,align_F(ii).name),'VideoStart');
   VideoStart(ii) = in.VideoStart;
end

tic;
fprintf(1,'Please wait, loading video (can be a minute or two)...');
V = VideoReader(fullfile(DIR,vid_F(1).name));

NumFrames=V.NumberOfFrames; %#ok<VIDREAD>
FPS=V.FrameRate;
TimerPeriod=2*round(1000/FPS)/1000;

%% CONSTRUCT UI
fig=figure('Name','Bilateral Reach Scoring',...
           'Color','k',...
           'Units','Normalized',...
           'Position',[0.1 0.1 0.8 0.8]);
   
% Make custom classes for tracking video and behavioral data
vidInfoObj = vidInfo(fig,dispPanel,vid_F);
behaviorInfoObj = behaviorInfo(fig,behaviorData);                 
 
%% BUILD GRAPHICAL ELEMENTS             
behaviorInfoObj.buildVideoControlPanel;
behaviorInfoObj.buildProgressTracker(dispPanel);
      
graphicsUpdateObj = graphicsUpdater(vid_F);

% Construct video selection interface and load video
vidInfoObj.buildVidSelectionList;

graphics = getGraphics(videoInfoObj);
graphicsUpdateObj.addGraphics(graphics);
graphics = getGraphics(behaviorInfoObj);
graphicsUpdateObj.addGraphics(graphics);


graphicsUpdateObj.addListeners(vidInfoObj,alignInfoObj);

graphicsUpdateObj.setBehaviorData(behaviorData);


% Set callback for navigating through trials
set(trialPop,'Callback',{@selectTrial,behaviorInfoObj});
                     
% Initialize hotkeys for navigating through movie
set(fig,'WindowKeyPressFcn',...
   {@hotKey,vidInfoObj,behaviorInfoObj,behaviorUpdateObj,fname});

% Update everything to make sure it looks correct
graphicsUpdateObj.updateVideo(vidInfoObj);


%% Function to set frame when slider is moved
    function setCurrentFrame(newFrame,v)
       v.setFrame(newFrame);       
    end

%% Function to change button push
   function setCurrentTrial(newButton,bu)
      bu.setButton(newButton);
   end 

%% Function to add/remove current frame as Reach
   function addRemoveReach(v,bu,t)
      if isnan(t)
         curTime = getTime(v);
      else
         curTime = t;
      end
      
      bu.setReachTime(curTime);
   end

%% Function to add/remove current frame as Grasp
   function addRemoveGrasp(v,bu,t)
      if isnan(t)
         curTime = getTime(v);
      else
         curTime = t;
      end
      
      bu.setGraspTime(curTime);      
   end

%% Function to set trial handedness
   function setTrialHand(hand,bu)
      bu.setHandedness(hand);
   end

%% Function to set trial outcome
   function setTrialOutcome(outcome,bu)
       bu.setOutcome(outcome);    
   end

%% Function to save scoring data
   function saveScoring(beh,fname)
      % Done this way to avoid global variable
      out = struct('behaviorData',beh.behaviorData);

      % Save data
      save(fname,'-struct','out');
   end

%% Function for hotkeys
   function hotKey(~,evt,v,bu,beh,fname)
      switch evt.Key
         case 'r' % set reach trial
            addRemoveReach(v,bu,nan);
            
         case 'g' % set grasp trial
            addRemoveGrasp(v,bu,nan);
            
         case 'w' % set outcome as Successful
            setTrialOutcome(1,bu);
            
         case 'x' % set outcome as Unsuccessful
            setTrialOutcome(0,bu);
            
         case 'e' % set hand as Right
            setTrialHand('R',bu);
            
         case 'q' % set hand as Left
            setTrialHand('L',bu);
            
         case 'a' % previous frame
            setCurrentFrame(getFrame(v)-15,v);
            
         case 'leftarrow' % previous trial
            setCurrentTrial(getTrial(bu)-1,bu);
            
         case 'd' % next frame
            setCurrentFrame(getFrame(v)+1,v);
            
         case 'rightarrow' % next trial
            setCurrentTrial(getTrial(bu)+1,bu);
            
         case 's' % alt + s = save
            if strcmpi(evt.Modifier,'alt')
               fprintf(1,'Saving %s...',fname);
               saveScoring(beh,fname);
               fprintf(1,'complete.\n');
            end
            
         case 'delete'
            addRemoveReach(v,bu,inf);
            addRemoveGrasp(v,bu,inf);
            
         case 'space'
            v.playPauseVid;
      end
   end

end