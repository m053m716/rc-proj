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
DEF_DIR = 'P:\Extracted_Data_To_Move\Rat\TDTRat';
% VID_DIR = 'K:\Rat\Video\BilateralReach\RC';
VID_DIR = 'C:\Users\Max Murphy\Desktop\tmp';
FILE = nan;

VARS = {'Trial','Reach','Grasp','Support','Outcome'};
ALIGN_ID = '_VideoAlignment.mat';
TRIAL_ID = '_Trials.mat';
SCORE_ID = '_Scoring.mat';

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% GET TRIALS FILE
if exist(VID_DIR,'dir')==0
   VID_DIR = inputdlg({['Bad video directory. ' ...
      'Specify VID_DIR here (change variable for next time).']},...
      'Invalid VID_DIR path',1,{'C:/vid/dir/path'});
   if isempty(VID_DIR)
      error('No valid video directory specified. Script canceled.');
   else
      VID_DIR = VID_DIR{1};
   end
end

if isnan(FILE)
   [FILE,DIR] = uigetfile(['*' TRIAL_ID],'Select TRIALS file',DEF_DIR);
   if FILE == 0
      error('No file selected. Script aborted.');
   end
else
   [DIR,FILE,ext] = fileparts(FILE);
   FILE = [FILE,ext];
end


%% MAKE UI WINDOW AND DISPLAY CONTAINER
fig=figure('Name','Bilateral Reach Scoring',...
           'NumberTitle','off',...
           'Color','k',...
           'Units','Normalized',...
           'Position',[0.1 0.1 0.8 0.8]);
        
% Panel for displaying information text
dispPanel = uipanel(fig,'Units','Normalized',...
   'BackgroundColor','k',...
   'Position',[0 0 0.75 1]);

        
%% CREATE BEHAVIOR INFORMATION OBJECT

Name = strsplit(FILE, TRIAL_ID);
Name = Name{1};

% All potential datapoints
F = struct('vectors',struct(...
      'Trials',struct('folder',DIR,'name',[Name TRIAL_ID])),...
   'scalars',struct(...
      'VideoStart',struct('folder',DIR,'name',[Name ALIGN_ID])),...
   'tables',struct(...
      'behaviorData',struct('folder',DIR,'name',[Name SCORE_ID])));

behaviorInfoObj = behaviorInfo(fig,F,VARS);


%% LOAD VIDEO DATA
vid_F = dir(fullfile(VID_DIR,[Name '*.avi']));         % Video files

% Make custom classes for tracking video and behavioral data
vidInfoObj = vidInfo(fig,dispPanel,vid_F);
 
%% BUILD GRAPHICAL ELEMENTS                   
graphicsUpdateObj = graphicsUpdater(vid_F,VARS);

% Construct video selection interface and load video
vidInfoObj.buildVidSelectionList;

graphics = getGraphics(vidInfoObj);
graphicsUpdateObj.addGraphics(graphics);
graphics = getGraphics(behaviorInfoObj);
graphicsUpdateObj.addGraphics(graphics);


graphicsUpdateObj.addListeners(vidInfoObj,behaviorInfoObj);
                     
% Initialize hotkeys for navigating through movie
set(fig,'WindowKeyPressFcn',...
   {@hotKey,vidInfoObj,behaviorInfoObj});

% Update everything to make sure it looks correct
vidInfoObj.setOffset(behaviorInfoObj.VideoStart);
notify(vidInfoObj,'vidChanged');
behaviorInfoObj.setTrial(nan,behaviorInfoObj.cur,true);

%% Function to set frame when a key is pressed
    function setCurrentFrame(newFrame,v)
       v.setFrame(newFrame);       
    end

%% Function to change button push
   function setCurrentTrial(newTrial,b)
      b.setTrial(nan,newTrial);
   end 

%% Function to add/remove current frame as Reach
   function markReachFrame(b,t)
      b.setValue(2,t);
   end

%% Function to add/remove current frame as Grasp
   function markGraspFrame(b,t)
      b.setValue(3,t);    
   end

%% Function to add/remove "both" hands (support)
   function markSupportFrame(b,t)
      b.setValue(4,t); 
   end

%% Function to set trial outcome
   function markTrialOutcome(outcome,b)
       b.setValue(5,outcome);    
   end

%% Function for hotkeys
   function hotKey(~,evt,v,b)
      t = getVidTime(v);
      switch evt.Key
         case 'r' % set reach frame
            markReachFrame(b,t);
            
         case 'g' % set grasp frame
            markGraspFrame(b,t);
            
         case 'b' % set "both" (support) frame
            markSupportFrame(b,t);
            
         case 'v' % (next to 'b') -> no "support" for this trial
            markSupportFrame(b,inf);
            
         case 'w' % set outcome as Successful
            markTrialOutcome(1,b);
            
         case 'x' % set outcome as Unsuccessful
            markTrialOutcome(0,b);
            
         case 'a' % previous frame
            setCurrentFrame(getFrame(v)-15,v);
            
         case 'leftarrow' % previous trial
            setCurrentTrial(b.cur-1,b);
            
         case 'd' % next frame
            setCurrentFrame(getFrame(v)+1,v);
            
         case 'rightarrow' % next trial
            setCurrentTrial(b.cur+1,b);
            
         case 's' % alt + s = save
            if strcmpi(evt.Modifier,'alt')
               b.saveScoring;
            end
            
         case 'delete'
            b.removeTrial;
         case 'space'
            v.playPauseVid;
      end
   end

end