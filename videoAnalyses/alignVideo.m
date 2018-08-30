function alignVideo(varargin)
%% ALIGNVIDEO  Aligns neural data and video so reaching time stamps match.
%
%  ALIGNVIDEO('NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%  varargin       :     (Optional) 'NAME', value input argument pairs.
%
%  --------
%   OUTPUT
%  --------
%  Saves a file in OUT_DIR that contains "VideoStart" variable, which is a
%  scalar that relates the relative time of the neural data to the onset of
%  the video (i.e. if the neural recording was started, then video started
%  30 seconds later, VideoStart would have a value of +30).
%
% By: Max Murphy  v2.1  08/29/2018  Changed alignment method from toggling
%                                   using the "o" key to just click and
%                                   drag the red (beam break) trace and
%                                   line it up however looks best against
%                                   the blue one.
%
%                 v2.0  08/17/2018  Made a lot of changes from previous
%                                   version, which had a different name as
%                                   well.

%% DEFAULTS
FNAME = nan;   % Full filename of the beam break file.
DEF_DIR = 'P:\Extracted_Data_To_Move\Rat\TDTRat'; % Default UI prompt dir

VID_DIR = 'K:\Rat\Video\BilateralReach\RC'; % MUST point to where the videos are
VID_TYPE = '.avi';
DLC_TYPE = '.csv';

OUT_ID = '_VideoAlignment';

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% PARSE INPUT
if isnan(FNAME)
   [FNAME,DIR] = uigetfile('*Bea*1.mat','Select Beam Break File',DEF_DIR);
   
   if FNAME == 0
      error('No Beam Break file selected. Video alignment canceled.');
   end
   
else
   [DIR,FNAME,EXT] = fileparts(FNAME);
   FNAME = [FNAME EXT];
end

%% PARSE FILE NAMES
Name = strsplit(FNAME,'_Bea2');
Name = Name{1};

Block = strsplit(DIR,filesep);
Block = strjoin(Block(1:(end-1)),filesep);

dig_F = dir(fullfile(DIR,[Name '*Bea2*.mat']));
vid_F = dir(fullfile(VID_DIR,[Name '*' VID_TYPE]));
dlc_F = dir(fullfile(VID_DIR,[Name '*' DLC_TYPE]));

if isempty(vid_F)
   disp('No video file located!');
   error('Please check VID_DIR or missing video for that session.');
end

%% CONSTRUCT UI
fig=figure('Name','Bilateral Reach Scoring',...
   'Color','k',...
   'Units','Normalized',...
   'Position',[0.1 0.1 0.8 0.8],...
   'UserData',struct('flag',false,'h',[]));

% Panel for displaying information text
dispPanel = uipanel(fig,'Units','Normalized',...
   'BackgroundColor','k',...
   'Position',[0 0.75 0.75 0.25]);


%% CONSTRUCT CUSTOM CLASS OBJECTS
% Make video alignment information object
alignInfoObj = alignInfo(fig,dig_F,dlc_F);

% Make video frame object to track video frames
vidInfoObj = vidInfo(fig,dispPanel,vid_F);
vidInfoObj.setOffset(alignInfoObj.getOffset);

% Make listener object to integrate class information
graphicsUpdateObj = graphicsUpdater(vid_F);
graphicsUpdateObj.addListeners(vidInfoObj,alignInfoObj);

% Construct video selection interface and load video
graphics = vidInfoObj.getGraphics;
graphicsUpdateObj.addGraphics(graphics);
vidInfoObj.buildVidSelectionList;

% Add associated graphics objects to listener
graphics = alignInfoObj.getGraphics;
graphicsUpdateObj.addGraphics(graphics);
graphics = vidInfoObj.getGraphics;
graphicsUpdateObj.addGraphics(graphics);

%% SET HOTKEY AND MOUSE MOVEMENT FUNCTIONS
fname = fullfile(DIR,[strrep(vid_F(1).name,VID_TYPE,'') OUT_ID, '.mat']);
set(fig,'KeyPressFcn',{@hotKey,vidInfoObj,alignInfoObj,fname});
set(fig,'WindowButtonMotionFcn',{@trackCursor,alignInfoObj});
 
%% Function for tracking cursor
   function trackCursor(src,~,a)
      a.setCursorPos(src.CurrentPoint(1,1));  
   end

%% Function for hotkeys
   function hotKey(~,evt,v,a,fname)
      switch evt.Key     
         case 's' % Press 'alt' and 's' at the same time to save
            if strcmpi(evt.Modifier,'alt')
               a.saveAlignment(fname);
            end
            
         case 'a' % Press 'a' to go back one frame
            v.retreatFrame(1);
            
         case 'leftarrow' % Press 'leftarrow' key to go back 5 frames
            v.retreatFrame(5);
            
         case 'd' % Press 'd' to go forward one frame
            v.advanceFrame(nan,nan);
            
         case 'rightarrow' % Press 'rightarrow' key to go forward one frame
            v.advanceFrame(nan,nan);
            
         case  'subtract' % Press numpad '-' key to zoom out on time series
            a.zoomOut;
            
         case 'add' % Press numpad '+' key to zoom in on time series
            a.zoomIn;
            
         case 'space' % Press 'spacebar' key to play or pause video
            v.playPauseVid;
      end
   end
end