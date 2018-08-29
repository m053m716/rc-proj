classdef alignInfo < handle
%% ALIGNINFO  Class to update HUD & track alignment information

%% Properties 
   properties(SetAccess = private, GetAccess = public)
      % Graphics objects
      parent      % Parent figure object
      ax          % Axes to plot streams on
      curNeuT     % Line indicating current neural time
      curVidT     % Line indicating current video time
      v           % VidInfoObj
      
      % Data streams
      pellet   % Pellet break times (may not exist)
      beam     % Beam break times   
      paw      % Paw guesses from DLC
      
      alignLag = nan; % Best guess or current alignment lag offset
   end
   
   properties(SetAccess = private, GetAccess = private)
      FS = 125;                  % Resampled rate for correlation
      VID_FS = 30000/1001;       % Frame-rate of video
      currentVid = 1;            % If there is a list of videos
      axLim;                     % Stores "outer" axes ranges
      zoomOffset = 2;            % # Seconds to buffer zoom window
      moveStreamFlag = false;    % Flag for moving objects on top axes
      cursorX;                   % Current cursor X position on figure
      curOffsetPt;               % Last-clicked position for dragging line
   end
   
%% Events
   events % These correspond to different scoring events
      align
      switchVid
   end
   
%% Methods
   methods (Access = public)
      % Construct the object for keeping track of which "button press" (or
      % trial) we are currently looking at
      function obj = alignInfo(parentFig,dig_F,dlc_F,FPS)
         % Parse parent (must be figure)
         if isa(parentFig,'matlab.ui.Figure')
            obj.parent = parentFig;
         else
            error('parentFig argument must be a figure handle.');
         end
         
         obj.setDigitalStreams(dig_F);
         obj.setDLCStreams(dlc_F);
         
         obj.VID_FS = FPS;
         
         obj.guessAlignment;
         
      end
      
      % Set the video info object for this alignment object
      function setVidInfoObj(obj,vidInfoObj)
         obj.v = vidInfoObj;
      end
      
      % Load the digital stream data (alignments like beam,pellet break)
      function setDigitalStreams(obj,dig_F)
         obj.pellet = nan;
         if numel(dig_F)>1
            for ii = 2:numel(dig_F)
               str = dig_F(ii).name((end-8):(end-4));
               switch str
                  case 'Guess'
                     load(fullfile(dig_F(ii).folder,dig_F(ii).name),'alignGuess');
                     obj.alignLag = alignGuess;
                  otherwise
                     obj.pellet = loadDigital(fullfile(dig_F(ii).folder,dig_F(ii).name));
               end
                  
            end
         end
         obj.beam = loadDigital(fullfile(dig_F(1).folder,dig_F(1).name));
      end
      
      
      % Set the alignment stream from markerless DLC tracking
      function setDLCStreams(obj,dlc_F)
         vidTracking = importRC_Grasp(...
            fullfile(dlc_F(obj.currentVid).folder,...
                     dlc_F(obj.currentVid).name));
         obj.paw.data = vidTracking.grasp_p;
         obj.paw.fs = obj.VID_FS;
         obj.paw.t = linspace(0,...
            (numel(obj.paw.data)-1)/obj.paw.fs,...
             numel(obj.paw.data));
         
      end
      
      % Set the current video
      function setVideo(obj,curVidNum)
         obj.currentVid = curVidNum;
         notify(obj,'switchVid');
      end
      
      % Set new neural time
      function setNewOffset(obj,x)
         align_offset = x - obj.curNeuT.XData(1);
         align_offset = obj.alignLag - align_offset;
         
         obj.setAlignment(align_offset);
      end
      
      % Return the current alignment offset
      function lag = getOffset(obj)
         lag = obj.alignLag;
      end
      
      % Get handle to neural time indicator line
      function h = getNeuralTimeHandle(obj)
         h = obj.curNeuT;
      end
      
      % Get handle to video time indicator line
      function h = getVidTimeHandle(obj)
         h = obj.curVidT;
      end
      
      % Save the output file
      function saveAlignment(obj,fname)
         VideoStart = obj.alignLag;
         fprintf(1,'Please wait, saving %s...',fname);
         save(fname,'VideoStart','-v7.3');
         fprintf(1,'complete.\n');
      end
      
      % Zoom out on beam break/paw probability time series (top axis)
      function zoomOut(obj)
         set(obj.ax,'XLim',obj.axLim);
         set(obj.paw.h,'LineWidth',1);
         set(obj.beam.h,'LineWidth',1);
      end
      
      % Zoom in on beam break/paw probability time series (top axis)
      function zoomIn(obj)
         set(obj.ax,'XLim',[obj.curVidT.XData(1) - obj.zoomOffset,...
                            obj.curVidT.XData(1) + obj.zoomOffset);
         
         set(obj.paw.h,'LineWidth',2);
         set(obj.beam.h,'LineWidth',3);
      end
      
      % Update the current cursor X-position in figure frame
      function setCursorPos(obj,x)
         obj.cursorX = x * diff(obj.ax.XLim) + obj.ax.XLim(1);
         if obj.moveStreamFlag
            new_align_offset = obj.computeOffset(obj.curOffsetPt,obj.cursorX);
            obj.curOffsetPt = obj.cursorX;
            obj.setAlignment(new_align_offset); % update the shadow positions
            
         end
      end
      
   end
   
   methods (Access = private)
      function guessAlignment(obj)
         % If guess already exists, skip this part
         if ~isnan(obj.alignLag)
            disp('Found alignment lag guess. Skipping computation');
            return;
         end
         
         % Upsample by 16 because of weird FS used by TDT...
         ds_fac = round((double(obj.beam.fs) * 16) / obj.FS);
         x = resample(double(obj.beam.data),16,ds_fac);
         
         % Resample DLC paw data to approx. same FS
         y = resample(obj.paw.data,obj.FS,round(obj.paw.fs));
         
         % Guess the lag based on cross correlation between 2 streams
         tic;
         fprintf(1,'Please wait, making best alignment offset guess (usually 1-2 mins)...');
         [R,lag] = getR(x,y);
         setAlignment(obj,parseR(R,lag));
         obj.plotStreams;
         fprintf(1,'complete.\n');
         toc;
      end
      
      % Make all the graphics for tracking relative position of neural
      % (beam/pellet) and video (paw probability) time series
      function plotStreams(obj)
         % Make axes for graphics objects
         obj.ax = axes(obj.parent,'Units','Normalized',...
              'Position',[0 0.51 1 0.24],...
              'NextPlot','add',...
              'XColor','w',...
              'YLim',[-0.2 1.2],...
              'YTick',[],...
              'ButtonDownFcn',@obj.clickAxes);
         
         % Make current position indicators for neural and video times
         x = zeros(1,2); % Vid starts at zero
         y = [0 1];
         obj.curVidT = line(obj.ax,x,y,...
            'LineStyle',':',...
            'LineWidth',2,...
            'Color',[0.2 0.2 0.9]);
         
         x = ones(1,2) * obj.alignLag; % Neural data is relative to vid
         y = [0 1];
         obj.curNeuT = line(obj.ax,x,y,...
            'LineStyle','--',...
            'LineWidth',2,...
            'Color',[0.9 0.2 0.2]);
         
         
         
         % Plot paw probability time-series from DeepLabCut
         obj.paw.h = plot(obj.ax,...
            obj.paw.t,...
            obj.paw.data,...
            'Color','b',...
            'DisplayName','paw',...
            'ButtonDownFcn',@obj.clickAxes);
         
         % Make beam plot and if present, pellet breaks
         obj.beam.h = plot(obj.ax,...
            obj.beam.t,...
            obj.beam.data,...
            'Color','r',...
            'Tag','beam',...
            'DisplayName','beam',...
            'ButtonDownFcn',@obj.clickSeries);
         if isstruct(obj.pellet)
            obj.pellet.h = plot(obj.ax,...
               obj.pellet.t,...
               obj.pellet.data,...
               'Tag','pellet',...
               'DisplayName','pellet',...
               'Color','m',...
               'ButtonDownFcn',@obj.clickSeries);
            legend(obj.ax,{'Vid-Time';'Offset';'Paw';'Beam';'Pellet'},...
               'FontName','Arial',...
               'FontSize',14);
         else
            legend(obj.ax,{'Vid-Time';'Offset';'Paw';'Beam'},...
               'FontName','Arial',...
               'FontSize',14);
         end
         
         % Make "fake" beam-plot for shadow when "dragging"
         obj.beam.sh = plot(obj.ax,...
            obj.beam.t,...
            obj.beam.data,...
            'LineWidth',1.5,...
            'Color',[0.40 0.40 0.40],...
            'LineStyle',':',...
            'Tag','beam',...
            'Visible','off',...
            'DisplayName','beam-move',...
            'ButtonDownFcn',@obj.clickAxes);
         
         if isstruct(obj.pellet)
            % Make "fake" pellet-plot for shadow when "dragging"
            obj.pellet.sh = plot(obj.ax,...
               obj.pellet.t,...
               obj.pellet.data,...
               'LineWidth',1.5,...
               'Color',[0.60 0.60 0.60],...
               'LineStyle',':',...
               'Tag','pellet',...
               'Visible','off',...
               'DisplayName','pellet-move',...
               'ButtonDownFcn',@obj.clickAxes);
         end
         
         % Get the max. axis limits and then zoom in
         obj.axLim = get(obj.ax,'XLim');
         zoomIn(obj);
         
      end
      
      % ButtonDownFcn for top axes and children
      function clickAxes(obj,~,~)
         cp = obj.ax.CurrentPoint(1,1);
         
         % If FLAG is enabled
         if obj.moveStreamFlag
            % Place the (dragged) neural (beam/pellet) streams with cursor
%             new_align_offset = obj.computeOffset(obj.curOffsetPt,cp);
%             obj.setAlignment(new_align_offset);
            obj.beam.h.Visible = 'on';
            obj.beam.sh.Visible = 'off';
            if isstruct(obj.pellet)
               obj.pellet.h.Visible = 'on';
               obj.pellet.sh.Visible = 'off';
            end
            obj.moveStreamFlag = false;            
         else % Otherwise, allows to skip to point in video
            % (Referencing things to the VIDEO time)
            obj.v.setVidTime(cp);
         end
      end
      
      % ButtonDownFcn for neural sync time series (beam/pellet)
      function clickSeries(obj,src,~)
         if ~obj.moveStreamFlag
            obj.moveStreamFlag = true;
            obj.curOffsetPt = obj.cursorX;
            obj.(src.Tag).sh.Visible = 'on';
            src.Visible = 'off';
         end
         
      end
      
      % Compute the relative change in alignment and update alignment Lag
      function new_align_offset = computeOffset(obj,init_pt,moved_pt)
         align_offset_delta = init_pt - moved_pt;
         new_align_offset = obj.alignLag + align_offset_delta;
         
      end
      
      
      % Set the trial hand and emit a notification about the event
      function setAlignment(obj,align_offset)
         obj.alignLag = align_offset;
         obj.updateStreamTime;
         notify(obj,'align');
      end
      
      % Updates stream times and graphic object times associated with
      function updateStreamTime(obj)
         % Moves the beam and pellet streams, relative to VIDEO
         obj.beam.t = obj.beam.t0 - obj.alignLag;
         obj.beam.h.XData = obj.beam.t;
         obj.beam.sh.XData = obj.beam.t;
         
         if isstruct(obj.pellet)
            obj.pellet.t = obj.pellet.t0 - obj.alignLag;
            obj.pellet.h.XData = obj.pellet.t;
            obj.pellet.sh.XData = obj.pellet.t;
            
         end
      end
      
      
   end

end