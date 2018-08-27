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
% By: Max Murphy  v2.0  08/17/2018  Made a lot of changes from previous
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
tic;
fprintf(1,'Please wait, loading video (can be a minute or two)...');
V = VideoReader(fullfile(VID_DIR,vid_F(1).name));

NumFrames=V.NumberOfFrames; %#ok<VIDREAD>
FPS=V.FrameRate;

%% CONSTRUCT UI
fig=figure('Name','Bilateral Reach Scoring',...
           'Color','k',...
           'Units','Normalized',...
           'Position',[0.1 0.1 0.8 0.8],...
           'UserData',struct('flag',false,'h',[]));
        
% Panel for displaying information text
dispPanel = uipanel(fig,'Units','Normalized',...
                        'BackgroundColor','k',...
                        'Position',[0.76 0.51 0.23 0.49]);

% Panel for selecting which video
vidSelPanel = uipanel(fig,'Units','Normalized',...
                          'BackgroundColor','k',...
                          'Position',[0.76 0 0.23 0.49]);
                       
                     
%% BUILD VIDEO PLOT
plt_ax = axes(fig,'Units','Normalized',...
              'Position',[0 0.75 0.75 0.25],...
              'NextPlot','add',...
              'YLim',[-0.2 1.2],...
              'YTick',[]);
           
vid_ax = axes(fig,'Units','Normalized',...
            'Position',[0 0 0.75 0.75],...
            'NextPlot','replacechildren',...
            'XTick',[],...
            'YTick',[],...
            'XLim',[0 1],...
            'YLim',[0 1],...
            'XLimMode','manual',...
            'YLimMode','manual',...
            'YDir','reverse');
         
C=V.read(1); %#ok<VIDREAD> % reading first frame of the video
x = [0 1];
y = [0 1];
im = imagesc(vid_ax,x,y,C); % showing the first frame of the video
fprintf(1,'complete.\n'); 
toc;

%% BUILD ANNOTATIONS
VidTimeDisp=annotation(dispPanel, ...
                       'textbox',[0.025 0.7 0.95 0.25],...
                       'Units', 'Normalized', ...
                       'Position', [0.025 0.7 0.95 0.25], ...
                       'FontName','Arial',...
                       'FontSize',16,...
                       'Color','w',...
                       'String','loading...');


NeuralTimeDisp = annotation(dispPanel,...
                       'textbox',[0.025 0.4 0.95 0.25],...
                       'Units', 'Normalized', ...
                       'Position', [0.025 0.4 0.95 0.25], ...
                       'Color',[0.94 0.94 0.94],...
                       'FontName','Arial',...
                       'FontSize',16,...
                       'String', 'loading...');
                    

% Make video alignment information object
alignInfoObj = alignInfo(dig_F,dlc_F,plt_ax,FPS);

% Make video frame object to track video frames
vidInfoObj = vidInfo(1,FPS,getOffset(alignInfoObj),NumFrames,1);
vidUpdateObj = vidUpdateListener(vidInfoObj,...
                                 NeuralTimeDisp,...
                                 VidTimeDisp,...
                                 V,...
                                 im,...
                                 getNeuralTimeHandle(alignInfoObj));
                                 
% Make line object for setting new offsets
fig.UserData.h = line([nan nan],[0 1],...
   'Color',[0.75 0.75 0.75],...
   'LineStyle',':',...
   'LineWidth',2);

set(plt_ax,'ButtonDownFcn',{@clickAxes,vidInfoObj,alignInfoObj});
fname = fullfile(DIR,[strrep(vid_F(1).name,VID_TYPE,'') OUT_ID, '.mat']);
set(fig,'KeyPressFcn',{@hotKey,vidInfoObj,alignInfoObj,fname});

%% Function for clicking in axes to set offset
    function clickAxes(src, ~, v, a)
        cp = src.CurrentPoint;
        if src.Parent.UserData.flag
           set(src.Parent.UserData.h,'XData',[cp(1) cp(1)]);
        else
           % Everything is relative to neural time, so subtract offset
           v.setVidTime(cp(1) - getOffset(a));
        end
    end

 
 %% Function for hotkeys
   function hotKey(src,evt,v,a,fname)
      switch evt.Key  
         case 'o' % Toggle setting or keeping the offset
            if src.UserData.flag
               % Update alignment offset
               a.setNewOffset(src.UserData.h.XData(1));
               
               % Make the alignment line disappear
               src.UserData.h.XData = [nan, nan];
               
               % Clicking now skips through the video
               src.UserData.flag = false;
            else
               % Clicking now makes the alignment line appear
               src.UserData.flag = true;
            end
         
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
         case 'space'
            v.playPauseVid;
      end
   end
end