classdef graphicsUpdater < handle
%% GRAPHICSUPDATER   Class to update video scoring UI on frame update
   

   properties (SetAccess = private, GetAccess = public)
      parent % figure handle
      
      videoFile_list       % 'dir' struct of videos
      videoFile            % VideoReader file object
      
      % 'graphics' arg fields from vidInfoObj
      animalName_display   % Text displaying animal name/recording
      neuTime_display      % Text displaying neural data time
      vidTime_display      % Text displaying video time
      image_display        % Graphics object for displaying current frame
      image_displayAx      % Axes container for image display
      vidSelect_listBox    % Video selection listbox
      
      % 'graphics' arg fields for alignInfoObj:
      neuTime_line         % Line indicating neural time
      vidTime_line         % Line indicating video time
      
      % 'graphics' arg fields for behaviorInfoObj:
      trialTracker_display          % Graphic for displaying trial progress
      trialTracker_displayOverlay   % Graphic for tracking current trial
      trialPopup_display            % Graphic for selecting current trial
      editArray_display             % Array of edit box display graphics
      
      
      % Information variables for video scoring: 
      % State variables for updating the "progress tracker" for each trial
      graspState = false
      reachState = false
      outcomeState = false
      supportState = false
      
      
      % Constant for alignment tracking:
      zoomOffset = 2; % Offset (sec)
   end


   methods
      
      % Create the video information listener that updates other objects on
      % a frame change (to prevent copy/paste a lot of the same stuff into
      % many sub-functions of the scoreVideo main funciton)
      function obj = graphicsUpdater(vid_F)
         % Get list of video files
         obj.videoFile_list = vid_F;
         
      end
      
      function addListeners(obj,vidInfo_obj,varargin)
         % Add listeners for event notifications from video object
         addlistener(vidInfo_obj,...
            'frameChanged',@obj.updateFrame);
         addlistener(vidInfo_obj,...
            'vidChanged',@obj.updateVideo);
         
         % Add listeners for event notifications from associated
         % information tracking object
         for iV = 1:numel(varargin)
            switch class(varargin{iV})
               case 'behaviorInfo'
                  addlistener(varargin{iV},...
                     'newTrial',@obj.updateBehavior);
                  addlistener(varargin{iV},...
                     'update',@obj.addRemoveValue);
                  
               case 'alignInfo'
                  addlistener(varargin{iV},...
                     'saveFile',@obj.updateSaveStatus);
                  addlistener(varargin{iV},...
                     'align',@(o,e) obj.updateAlignment(o,e,vidInfo_obj));
                  addlistener(varargin{iV},...
                     'skip',@(o,e) obj.skipToVidTime(o,e,vidInfo_obj));
                  
               otherwise
                  fprintf(1,'%s is not a class supported by vidUpdateListener.\n',...
                     class(varargin{iV}));
            end
         end
      end
      
      % Add graphics object handles to properties
      function addGraphics(obj,graphics)
         % Get graphics objects
         gobj = fieldnames(graphics);
         for ii = 1:numel(gobj)
            if ismember(gobj{ii},properties(obj))
               obj.(gobj{ii}) = graphics.(gobj{ii});
            end
         end
      end
      
      % Update image object
      function updateImageObject(obj,x,y,C)
         set(obj.image_display,'XData',x,'YData',y,'CData',C);
      end
      
      %% Functions for vidInfo class:
      % Change any graphics associated with a frame update
      function updateFrame(obj,src,~)
         set(obj.neuTime_display,'String',...
               sprintf('Neural Time: %0.2f',src.neuralTime));
         set(obj.vidTime_display,'String',...
               sprintf('Video Time: %0.2f',src.vidTime));
         set(obj.image_display,'CData',...
               obj.videoFile.read(src.getFrame));
            
         if ~isempty(obj.neuTime_line)
            set(obj.neuTime_line,'XData',ones(1,2) * src.neuralTime);
            set(obj.vidTime_line,'XData',ones(1,2) * src.vidTime);

            % Fix axis limits
            xl = obj.vidTime_line.Parent.XLim;
            if src.vidTime > xl(2)
               obj.vidTime_line.Parent.XLim = [xl(2),xl(2)+obj.zoomOffset*2];
            elseif src.vidTime < xl(1)
               obj.vidTime_line.Parent.XLim = [xl(1)-obj.zoomOffset*2,xl(1)];
            end
         end         
      end
      
      % Change any graphics associated with a different video
      function updateVideo(obj,src,~)   
         % Get the file name information
         path = obj.videoFile_list(src.currentVid).folder;
         fname = obj.videoFile_list(src.currentVid).name;
         vfname = fullfile(path,fname);
         
         % Read the actual video file
         obj.setVideo(vfname);
         
         % Update metadata about new video
         FPS=obj.videoFile.FrameRate;
         nFrames=obj.videoFile.NumberOfFrames; 
         src.setVideoInfo(FPS,nFrames,fname);
         
         % Update the image (in case dimensions are different)
         C = obj.videoFile.read(1);
         x = [0,1];
         y = [0,1];
         obj.updateImageObject(x,y,C);

         % Move video to the correct time
         src.setVidTime(src.toVidTime(src.getNeuTime));
         
         % Update the correct frame, last
         obj.updateFrame(src,nan);
         
      end
      
      % Change the actual video file
      function setVideo(obj,vfname)
         delete(obj.videoFile);
         tic;
         [~,name,ext] = fileparts(vfname);
         fprintf(1,'Please wait, loading %s.%s (can be a minute or two)...',...
            name,ext);
         obj.videoFile = VideoReader(vfname);   
         fprintf(1,'complete.\n'); 
         toc;

      end
      
      % Skip to a point from clicking in axes plot
      function skipToVidTime(~,src,~,v)
         v.setVidTime(src.cp);
      end
      
      %% Functions for alignInfo class:
      % Change color of the animal name display
      function updateSaveStatus(obj,~,~)
         set(obj.animalName_display,'Color',[0.2 0.9 0.2]);
      end
      
      % Change the neural and video times in the videoInfoObject
      function updateAlignment(obj,src,~,v)
         v.setOffset(src.getOffset);
         v.updateTime;
         obj.updateFrame(v,nan);
         
      end
      
      %% Functions for behaviorInfo class:
      % Input the behavior Data table
      function setBehaviorData(obj,behaviorData_table)
         obj.behaviorData = behaviorData_table;
      end
      
      % Go to the next candidate trial
      function updateTrial(obj,src,~)
         obj.graspState = ~isnan(obj.behaviorData.Grasp(src.getTrial));
         obj.reachState = ~isnan(obj.behaviorData.Reach(src.getTrial));
         
         obj.outcomeState = ~isnan(obj.behaviorData.Outcome(src.getTrial));
         obj.supportState = ~strcmp(obj.behaviorData.Forelimb(src.getTrial),'?');
         
         if obj.reachState && ~isinf(obj.behaviorData.Reach(src.getTrial))
            t = src.vidInfo.toVidTime(...
               obj.behaviorData.Reach(src.getTrial));
            src.vidInfo.setVidTime(t);
         elseif obj.graspState && ~isinf(obj.behaviorData.Grasp(src.getTrial))
            t = src.vidInfo.toVidTime(...
               obj.behaviorData.Grasp(src.getTrial));
            src.vidInfo.setVidTime(t);
         else
            t = src.vidInfo.toVidTime(...
               obj.behaviorData.Button(src.getTrial));
            src.vidInfo.setVidTime(t);
         end
         
         while src.stepIdx
            
         end
         obj.updateGraspEdit(src.getTrial,src.vidInfo);
         obj.updateReachEdit(src.getTrial,src.vidInfo);
         obj.updateOutcomeEdit(src.getTrial);
         obj.updateSupportEdit(src.getTrial);
         
         obj.updateTrialPopup(src.getTrial);
         obj.updateTracker(src.getTrial);
         obj.updateCurrentTrackerTrial(src.getTrial);
      end
      
      % Add or remove the grasp time for this trial
      function addRemoveValue(obj,src,~)
         t = src.vidInfo.toNeuTime(src.graspTime);
         if obj.behaviorData.Grasp(src.getTrial)==t
            obj.behaviorData.Grasp(src.getTrial) = nan;
            obj.graspState = false;
         else
            obj.behaviorData.Grasp(src.getTrial) = t;
            obj.graspState = true;
         end
         obj.updateGraspEdit(src.getTrial,src.vidInfo);
         obj.updateTracker(src.getTrial);
         
      end

      % Update the tracker image by reflecting the "state" using red or
      % blue coloring in an image
      function updateTracker(obj,idx)
         if obj.reachState && obj.graspState && ...
               obj.outcomeState && obj.supportState
            
            obj.trialTracker_display.CData(1,idx,:)=[0 0 1];
         else
            obj.trialTracker_display.CData(1,idx,:)=[1 0 0];

         end
         
      end
      
      % Update the tracker to reflect which trial is being looked at
      % currently
      function updateCurrentTrackerTrial(obj,idx)
         x = linspace(0,1,size(obj.trialTracker_display.CData,2)+1);
         x = x(2:end) - mode(diff(x))/2;
         obj.trialTracker_displayOverlay.XData = [x(idx), x(idx)];
      end
      
      % Update the graphics object associated with grasp time
      function updateEditBox(obj,idx,v)
         if obj.graspState
            obj.graspEdit_display.String = num2str(v.toVidTime(obj.behaviorData.Grasp(idx)));
         else
            obj.graspEdit_display.String = 'N/A';
         end
      end
      
      % Update the graphics object associated with trial button
      function updateTrialPopup(obj,idx)
         obj.trialPopup_display.Value = idx;         
      end
      
   end
end