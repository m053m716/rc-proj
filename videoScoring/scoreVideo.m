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

Name = strsplit(DIR, filesep);
Name = Name{end};

vF = dir(fullfile(DIR,[Name '*.avi']));         % Video files
aF = dir(fullfile(DIR,[Name '*' ALIGN_ID]));    % Alignment files


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

VideoStart = nan(size(aF));
for ii = 1:numel(aF)
   in = load(fullfile(DIR,aF(ii).name),'VideoStart');
   VideoStart(ii) = in.VideoStart;
end

tic;
fprintf(1,'Please wait, loading video (can be a minute or two)...');
V = VideoReader(fullfile(DIR,vF(1).name));

NumFrames=V.NumberOfFrames; %#ok<VIDREAD>
FPS=V.FrameRate;
TimerPeriod=2*round(1000/FPS)/1000;

%% CONSTRUCT UI
fig=figure('Name','Bilateral Reach Scoring',...
           'Color','k',...
           'Units','Normalized',...
           'Position',[0.1 0.1 0.8 0.8]);
        
% Panel for displaying information text
dispPanel = uipanel(fig,'Units','Normalized',...
                        'BackgroundColor','k',...
                        'Position',[0.76 0.75 0.23 0.24]);

% Panel for selecting which video
vidSelPanel = uipanel(fig,'Units','Normalized',...
                          'BackgroundColor','k',...
                          'Position',[0.76 0.5 0.23 0.24]);
                       
% Panel with controls for setting behavior & manipulating video
conPanel = uipanel(fig,'Units','Normalized',...
                        'BackgroundColor','k',...
                        'Position',[0.76 0.01 0.23 0.48]);
                     
%% BUILD VIDEO PLOT
ax=axes(fig,'Units','Normalized',...
            'Position',[0 0 0.75 1],...
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
im = imagesc(ax,x,y,C); % showing the first frame of the video
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
                    
ScoringTracker_ax = axes(dispPanel,'Units','Normalized',...
                                   'Position',[0.025 0.1 0.95 0.25],...
                                   'NextPlot','replacechildren',...
                                   'XLim',[0 1],...
                                   'YLim',[0 1],...
                                   'XLimMode','manual',...
                                   'YLimMode','manual',...
                                   'YDir','reverse',...
                                   'XTick',[],...
                                   'YTick',[]);

% Create tracker and set all to red to start                                
C = zeros(1,size(behaviorData,1),3);
C(1,:,1) = 1;
ScoringTracker_im = image(ScoringTracker_ax,x,y,C);
ScoringTracker_line = line(ScoringTracker_ax,[0 0],[0 1],'LineWidth',2,...
                           'Color',[0 0.7 0],...
                           'LineStyle',':');

% Make text labels for controls
labs = {'Button:' ; ...
        'Reach Time:'; ...
        'Grasp Time:'; ...
        'Hand Used:'; ...
        'Outcome:'};
yPos = makeLabels(conPanel,labs);

% Make controller for button "trials"
str = cellstr(num2str(behaviorData.Button)); 
str = cellfun(@(x) strrep(x,' ',''),str,'UniformOutput',false); % This makes it look nicer
buttonPop = uicontrol(conPanel,'Style','popupmenu',...
                        'Units','Normalized',...
                        'Position',[0.5 yPos(1) 0.475 0.15],...
                        'FontName','Arial',...
                        'FontSize',14,...
                        'String',str,...
                        'UserData',behaviorData.Button);

% Make video frame object to track video frames
vidInfoObj = vidInfo(1,FPS,VideoStart,NumFrames,1);
vidUpdateObj = vidUpdateListener(vidInfoObj,...
                                    NeuralTimeDisp,VidTimeDisp,V,im,buttonPop);
% Make behavior tracking object as well
behaviorInfoObj = behaviorInfo(1,size(behaviorData,1),vidInfoObj);                                 


%% BUILD VIDEO SELECTION LISTBOX
% List of videos
listBox = uicontrol(vidSelPanel,'Style','listbox',...
                        'Units','Normalized',...
                        'FontName','Arial',...
                        'FontSize',14,...
                        'Position',[0.025 0.025 0.95 0.95],...
                        'String',{vF.name}.',...
                        'Callback',{@changeVideo,vF,vidInfoObj,vidUpdateObj});
 
%% BUILD CONTROL ELEMENTS
% Edit box to show reach time (or N/A)                
reachEdit = uicontrol(conPanel,'Style','edit',...
                        'Units','Normalized',...
                        'Position',[0.5 yPos(2) 0.475 0.15],...
                        'FontName','Arial',...
                        'FontSize',14,...
                        'Enable','off',...
                        'String','N/A');
                     
% Edit box to show grasp time (or N/A)                       
graspEdit = uicontrol(conPanel,'Style','edit',...
                        'Units','Normalized',...
                        'Position',[0.5 yPos(3) 0.475 0.15],...
                        'FontName','Arial',...
                        'FontSize',14,...
                        'Enable','off',...
                        'String','N/A');

% Edit box to show handedness (or ?)  
handEdit = uicontrol(conPanel,'Style','edit',...
                        'Units','Normalized',...
                        'Position',[0.5 yPos(4) 0.475 0.15],...
                        'FontName','Arial',...
                        'FontSize',14,...
                        'Enable','off',...
                        'String','?');

% Edit box to show trial outcome (or ?)  
outcomeEdit = uicontrol(conPanel,'Style','edit',...
                        'Units','Normalized',...
                        'Position',[0.5 yPos(5) 0.475 0.15],...
                        'FontName','Arial',...
                        'FontSize',14,...
                        'Enable','off',...
                        'String','?');

% Listener object for behavioral scoring updates
behaviorUpdateObj = behaviorUpdateListener(behaviorInfoObj,...
                        behaviorData,...
                        ScoringTracker_im,...
                        ScoringTracker_line,...
                        buttonPop,...
                        reachEdit,...
                        graspEdit,...
                        handEdit,...
                        outcomeEdit);

% Set callback for navigating through trials
set(buttonPop,'Callback',{@selectButton,behaviorInfoObj});
                     
% Initialize hotkeys for navigating through movie
set(fig,'WindowKeyPressFcn',...
   {@hotKey,vidInfoObj,behaviorInfoObj,behaviorUpdateObj,fname});

% Update everything to make sure it looks correct
vidUpdateObj.updateVideo(vidInfoObj);


%% Function to set frame when slider is moved
    function setCurrentFrame(newFrame,v)
       v.setFrame(newFrame);       
    end

%% Function to change button push
   function setCurrentButton(newButton,bu)
      bu.setButton(newButton);
   end

%% Function to select button from list
   function selectButton(src,~,bu)
      setCurrentButton(src.Value,bu);
   end

%% Function to change video
   function changeVideo(src,~,vF,v,vl)
      fprintf(1,'Please wait, reading video file(can be a minute)...');
      v_new = VideoReader(fullfile(vF(src.Value).folder,vF(src.Value).name));
      vl.setVideo(v_new);
      v.setCurrentVideo(src.Value);
      fprintf(1,'complete.\n');
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
            setCurrentButton(getTrial(bu)-1,bu);
            
         case 'd' % next frame
            setCurrentFrame(getFrame(v)+1,v);
            
         case 'rightarrow' % next trial
            setCurrentButton(getTrial(bu)+1,bu);
            
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