classdef vidInfo < handle
%% VIDINFO  Class to update HUD with video information

%% Properties
   properties(SetAccess = private, GetAccess = public)
      neuralTime  % Current neural data time
      vidTime     % Current video time
      currentVid  % Current video in use (from array)
      playTimer   % Video playback timer
   end
   
   properties(SetAccess = private, GetAccess = private)
      videoStart % Video offset from neural data (seconds)
      currentFrame = 0; % Frame currently viewed
      FPS  % Frames per second
      maxFrame % Total number of frames in video
      TimerPeriod
   end
   
%% Events
   events
      frameChanged  % Emitted any time a frame is changed
      vidChanged    % Emitted any time the video is changed
   end
   
%% Methods
   methods (Access = public)
      % Create the video information object
      function obj = vidInfo(curFrame,frameRate,vStart,maxframe,curVid)
         obj.videoStart = vStart;
         obj.FPS = frameRate; 
         obj.maxFrame = maxframe;
         obj.currentVid = curVid;
         obj.TimerPeriod = 2*round(1000/obj.FPS)/1000;
         obj.playTimer = timer('TimerFcn',@obj.advanceFrame, ...
                               'ExecutionMode','fixedRate');
         
         
         setFrame(obj,curFrame);
      end
      
      % Set the current video frame
      function setFrame(obj,newFrame)
         
         if (newFrame ~= obj.currentFrame) && ...
            (newFrame > 0) && ...
            (newFrame <= obj.maxFrame)
            
            obj.currentFrame = newFrame;
            obj.vidTime = obj.currentFrame / obj.FPS;
            obj.neuralTime = obj.vidTime + obj.videoStart(obj.currentVid);
            
            notify(obj,'frameChanged');
         end
         
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
      function curTime = getTime(obj)
         curTime = obj.vidTime;
      end
   
      % Get the current neural time
      function curNeuTime = getCurrentNeuralTime(obj)
         curNeuTime = obj.neuralTime;
      end
      
      % Functions for transposing between neural and video time (depends on
      % which video is used)
      function neuTime = getNeuralTime(obj,vid_t)
         neuTime = vid_t + obj.videoStart(obj.currentVid);
      end
      
      function vidTime = getVidTime(obj,neu_t)
         vidTime = neu_t - obj.videoStart(obj.currentVid);
      end  
      
      function setCurrentVideo(obj,vid_idx)
         obj.currentVid = vid_idx;
         notify(obj,'vidChanged');
      end
   end

end