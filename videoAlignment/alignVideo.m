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


%% 
if isempty(vid_F)
   error('No video file located. Please check VID_DIR or perhaps no recording was taken for that TDT Block.');
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
                        'Position',[0 0.75 1 0.25]);
                       
                     
%% BUILD VIDEO PLOT
vid_ax = axes(fig,'Units','Normalized',...
            'Position',[0 0 1 0.5],...
            'NextPlot','replacechildren',...
            'XTick',[],...
            'YTick',[],...
            'XLim',[0 1],...
            'YLim',[0 1],...
            'XLimMode','manual',...
            'YLimMode','manual',...
            'YDir','reverse');

%% BUILD ANNOTATIONS
AnimalNameDisp = annotation(dispPanel,...
   'textbox',[0.025 0.4 0.25 0.20],...
   'Units', 'Normalized', ...
   'Position', [0.025 0.4 0.25 0.20], ...
   'Color',[0.94 0.94 0.94],...
   'FontName','Arial',...
   'FontSize',20,...
   'FontWeight','bold',...
   'String', strrep(vid_F(1).name,'_','\_'));

VidTimeDisp = annotation(dispPanel, ...
   'textbox',[0.325 0.4 0.25 0.20],...
   'Units', 'Normalized', ...
   'Position', [0.325 0.4 0.25 0.20], ...
   'FontName','Arial',...
   'FontSize',20,...
   'FontWeight','bold',...
   'Color','w',...
   'String','loading...');


NeuralTimeDisp = annotation(dispPanel,...
   'textbox',[0.625 0.4 0.25 0.20],...
   'Units', 'Normalized', ...
   'Position', [0.625 0.4 0.25 0.20], ...
   'Color',[0.94 0.94 0.94],...
   'FontName','Arial',...
   'FontSize',20,...
   'FontWeight','bold',...
   'String', 'loading...');

tic;
fprintf(1,'Please wait, loading video (can be a minute or two)...');
V = VideoReader(fullfile(VID_DIR,vid_F(1).name));
NumFrames=V.NumberOfFrames; %#ok<VIDREAD>
FPS=V.FrameRate;
C=V.read(1); %#ok<VIDREAD> % reading first frame of the video
x = [0 1];
y = [0 1];
im = imagesc(vid_ax,x,y,C); % showing the first frame of the video
fprintf(1,'complete.\n'); 
toc;

% Make video alignment information object
alignInfoObj = alignInfo(fig,dig_F,dlc_F,FPS);

% Make video frame object to track video frames
vidInfoObj = vidInfo(fig,1,FPS,getOffset(alignInfoObj),NumFrames,1);

% Pass everything to listener object in graphics struct
graphics = struct('animalName_display',AnimalNameDisp,...
                  'neuTime_display',NeuralTimeDisp,...
                  'vidTime_display',VidTimeDisp,...
                  'videoFile',V,...
                  'image_display',im,...
                  'neuTime_line',getNeuralTimeHandle(alignInfoObj),...
                  'vidTime_line',getVidTimeHandle(alignInfoObj));


% Now that video info object is complete, set it in the alignment info obj
alignInfoObj.setVidInfoObj(vidInfoObj);
   

vidUpdateObj = vidUpdateListener(vidInfoObj,alignInfoObj,graphics);

fname = fullfile(DIR,[strrep(vid_F(1).name,VID_TYPE,'') OUT_ID, '.mat']);
set(fig,'KeyPressFcn',{@hotKey,vidInfoObj,alignInfoObj,fname});
set(fig,'WindowButtonMotionFcn',{@trackCursor,alignInfoObj});
 
%% Function for tracking cursor
   function trackCursor(src,~,a)
      a.setCursorPos(src.CurrentPoint(1,1));  
%       drawnow;
   end

%% Function for hotkeys
   function hotKey(~,evt,v,a,fname)
      switch evt.Key  
         
         case 's' % alt + s = save
            if strcmpi(evt.Modifier,'alt')
               a.saveAlignment(fname);
            end
         case 'a'
            v.retreatFrame(1);
         case 'leftarrow'
            v.retreatFrame(5);
         case 'd'
            v.advanceFrame(nan,nan);
         case 'rightarrow'
            v.advanceFrame(nan,nan);
         case  'subtract'
            a.zoomOut;
         case 'add'
            a.zoomIn;
         
         case 'space'
            v.playPauseVid;
      end
   end
end