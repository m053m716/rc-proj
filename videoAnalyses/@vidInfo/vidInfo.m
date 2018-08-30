classdef vidInfo < handle
%% VIDINFO  Class to update HUD with video information

%% Properties
   properties(SetAccess = private, GetAccess = public)
      parent          % Parent figure
      panel           % Container for display graphics
      
      neuralTime      % Current neural data time
      vidTime         % Current video time
      currentVid = 0  % Current video in use (from array)
      playTimer       % Video playback timer
      
      vid_F           % Struct from 'dir' of videos associated with object
   end
   
   properties(SetAccess = private, GetAccess = private)
      videoStart        % Video offset from neural data (seconds)
      currentFrame = 0; % Frame currently viewed
      FPS               % Frames per second
      maxFrame          % Total number of frames in video
      TimerPeriod       % Time between video play timer refresh requests
      
      % Graphics objects
      NeuralTimeDisp
      AnimalNameDisp
      VidTimeDisp
      VidSelectPanel
      VidSelectListBox
      VidImAx
      VidIm
   end
   
%% Events
   events
      frameChanged  % Emitted any time a frame is changed
      vidChanged    % Emitted any time the video is changed
   end
   
%% Methods
   methods (Access = public)
      % Create the video information object
      function obj = vidInfo(figH,display_container,vid_F)
         obj.parent = figH;
         obj.panel = display_container;
         obj.vid_F = vid_F;  
         obj.buildVidDisplay;
      end
      
      % Add information about a new video file
      function setVideoInfo(obj,frameRate,nFrames,fname)

         obj.FPS = frameRate; 
         obj.maxFrame = nFrames;

         obj.TimerPeriod = 2*round(1000/obj.FPS)/1000;
         obj.playTimer = timer('TimerFcn',@obj.advanceFrame, ...
                               'ExecutionMode','fixedRate');
                            
         obj.buildHeadsUpDisplay(fname);
        
         setFrame(obj);
      end
      
      % Set the current video frame
      function setFrame(obj,newFrame)
         if exist('newFrame','var')==0
            newFrame = 1;
         end
         
         if (newFrame ~= obj.currentFrame) && ...
            (newFrame > 0) && ...
            (newFrame <= obj.maxFrame)
            
            obj.currentFrame = newFrame;
            obj.updateTime;
            
            
            notify(obj,'frameChanged');
         end
         
      end
      
      % Update the video and neural times
      function updateTime(obj)
         obj.vidTime = obj.currentFrame / obj.FPS;
         obj.neuralTime = obj.vidTime + obj.videoStart(obj.currentVid);
      end
      
      % Change the video offset
      function setOffset(obj,new_offset)
         obj.videoStart = new_offset;
      end
      
      % Play or pause the video
      function playPauseVid(obj)
         %toggle between stoping and starting the "play video" timer
         if strcmp(get(obj.playTimer,'Running'), 'off')
            set(obj.playTimer, 'Period', obj.TimerPeriod);
            start(obj.playTimer);
         else
            stop(obj.playTimer);
         end
      end
      
      % Function that runs while video is playing from timer object
      function advanceFrame(obj,~,~)  
         %executed at each timer period, when playing the video
         newFrame = obj.currentFrame + 1;
         obj.setFrame(newFrame);
      end
      
      % Function to go backwards some frames
      function retreatFrame(obj,n)
         newFrame = obj.currentFrame - n;
         obj.setFrame(newFrame);
      end
      
      % Set the current video time (just translate to the correct frame)
      function setVidTime(obj,newVidTime)
         newVidFrame = round(newVidTime * obj.FPS);
         setFrame(obj,newVidFrame);
         
      end
      
      % Get the current video frame
      function curFrame = getFrame(obj)
         curFrame = obj.currentFrame;
      end
      
      % Get the current video time
      function curVidTime = getVidTime(obj)
         curVidTime = obj.vidTime;
      end
   
      % Get the current neural time
      function curNeuTime = getNeuTime(obj)
         curNeuTime = obj.neuralTime;
      end
      
      % Get "neural time" from corresponding video timestamp
      function neuTime = toNeuTime(obj,vid_t)
         neuTime = vid_t + obj.videoStart(obj.currentVid);
      end
      
      % Get "video time" from corresponding neural timestamp
      function vidTime = toVidTime(obj,neu_t)
         vidTime = neu_t - obj.videoStart(obj.currentVid);
      end  
      
      % Set the current video index for the listener object
      function setCurrentVideo(obj,src,~)
         if src.Value ~= obj.currentVid
            obj.currentVid = src.Value;
            notify(obj,'vidChanged');
         end
      end
      
      % Return graphics objects struct associated with video object
      function graphics = getGraphics(obj)
         graphics = struct('animalName_display',obj.AnimalNameDisp,...
            'neuTime_display',obj.NeuralTimeDisp,...
            'vidTime_display',obj.VidTimeDisp,...
            'vidSelect_listBox',obj.VidSelectListBox,...
            'image_display',obj.VidIm,...
            'image_displayAx',obj.VidImAx);
      end
      
      % Build video display
      function buildVidDisplay(obj)
         % Make image object container axes
         obj.VidImAx=axes(obj.parent,...
            'Units','Normalized',...
            'Position',[0 0 1 0.5],...
            'NextPlot','replacechildren',...
            'XTick',[],...
            'YTick',[],...
            'XLim',[0 1],...
            'YLim',[0 1],...
            'XLimMode','manual',...
            'YLimMode','manual',...
            'YDir','reverse');
         
         % Make image object
         C=zeros(2,2); 
         x = [0 1];
         y = [0 1];
         obj.VidIm = imagesc(obj.VidImAx,x,y,C); 
      end
      
      % Build listbox for video selection
      function buildVidSelectionList(obj)
         % Panel for selecting which video
         obj.VidSelectPanel = uipanel(obj.parent,'Units','Normalized',...
            'BackgroundColor','k',...
            'Position',[0.75 0.75 0.25 0.25]);
         
         % List of videos
         obj.VidSelectListBox = uicontrol(obj.VidSelectPanel,...
            'Style','listbox',...
            'Units','Normalized',...
            'FontName','Arial',...
            'FontSize',14,...
            'Position',[0.025 0.025 0.95 0.95],...
            'Value',1,...
            'String',{obj.vid_F.name}.',...
            'Callback',@obj.setCurrentVideo);
         
         obj.setCurrentVideo(obj.VidSelectListBox,nan);
      end
      
   end

   methods (Access = private)
      function buildHeadsUpDisplay(obj,fname)
         obj.AnimalNameDisp = annotation(obj.panel,...
            'textbox',[0.025 0.4 0.25 0.20],...
            'Units', 'Normalized', ...
            'Position', [0.025 0.4 0.25 0.20], ...
            'Color',[0.94 0.94 0.94],...
            'FontName','Arial',...
            'FontSize',20,...
            'FontWeight','bold',...
            'String', strrep(fname,'_','\_'));
         
         obj.VidTimeDisp = annotation(obj.panel, ...
            'textbox',[0.325 0.4 0.25 0.20],...
            'Units', 'Normalized', ...
            'Position', [0.325 0.4 0.25 0.20], ...
            'FontName','Arial',...
            'FontSize',20,...
            'FontWeight','bold',...
            'Color','w',...
            'String','loading...');
         
         
         obj.NeuralTimeDisp = annotation(obj.panel,...
            'textbox',[0.625 0.4 0.25 0.20],...
            'Units', 'Normalized', ...
            'Position', [0.625 0.4 0.25 0.20], ...
            'Color',[0.94 0.94 0.94],...
            'FontName','Arial',...
            'FontSize',20,...
            'FontWeight','bold',...
            'String', 'loading...');
      end
      
   end
   
end