classdef alignInfo < handle
%% ALIGNINFO  Class to update HUD & track alignment information

%% Properties 
   properties(SetAccess = private, GetAccess = public)
      % Graphics objects
      ax       % Axes to plot streams on
      curNeuT  % Line indicating current video time
      
      % Data streams
      pellet   % Pellet break times (may not exist)
      beam     % Beam break times      
      paw      % Paw guesses from DLC
      
      alignLag % Buest guess or current alignment lag offset
   end
   
   properties(SetAccess = private, GetAccess = private)
      FS = 125;
      VID_FS = 30000/1001;
      currentVid = 1;
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
      function obj = alignInfo(dig_F,dlc_F,plt_ax,FPS)
         obj.setDigitalStreams(dig_F);
         obj.setDLCStreams(dlc_F);
         
         obj.VID_FS = FPS;
         obj.ax = plt_ax;
         
         obj.guessAlignment;
         
      end
      
      % Load the digital stream data (alignments like beam,pellet break)
      function setDigitalStreams(obj,dig_F)
         if numel(dig_F)==2
            obj.pellet = loadDigital(fullfile(dig_F(2).folder,dig_F(2).name));
         else
            obj.pellet = nan;
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
         align_offset = obj.curNeuT.XData(1) - x;
         align_offset = obj.alignLag - align_offset;
         
         obj.setAlignment(align_offset);
      end
      
      % Return the current alignment offset
      function lag = getOffset(obj)
         lag = obj.alignLag;
      end
      
      function h = getNeuralTimeHandle(obj)
         h = obj.curNeuT;
      end
      
      % Save the output file
      function saveAlignment(obj,fname)
         VideoStart = obj.alignLag;
         fprintf(1,'Please wait, saving %s...',fname);
         save(fname,'VideoStart','-v7.3');
         fprintf(1,'complete.\n');
      end
      
   end
   
   methods (Access = private)
      function guessAlignment(obj)
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
         fprintf(1,'complete.\n');
         toc;
      end
      
      function plotStreams(obj)
         if ~isfield(obj.paw,'h')
            obj.paw.h = plot(obj.ax,...
                          obj.paw.t,...
                          obj.paw.data,'LineWidth',1.5,'Color','b');
                       
            plot(obj.ax,...
              obj.beam.t,...
              obj.beam.data,'LineWidth',1.5,'Color','r');
            if isstruct(obj.pellet)
               plot(obj.ax,...
                    obj.pellet.t,...
                    obj.pellet.data,'LineWidth',1.5,'Color','m');
               legend(obj.ax,{'Paw';'Beam';'Pellet'},...
                  'FontName','Arial',...
                  'FontSize',14);
            else
               legend(obj.ax,{'Paw';'Beam'},...
                  'FontName','Arial',...
                  'FontSize',14);
            end

            x = ones(1,2) * obj.alignLag;
            y = [0 1];
            obj.curNeuT = line(obj.ax,x,y,...
               'LineStyle','--',...
               'LineWidth',2,...
               'Color','k');
            
                       
         else
            obj.paw.h.XData = obj.paw.t;
         end
         
         
      end
      
      % Set the trial hand and emit a notification about the event
      function setAlignment(obj,align_offset)
         obj.alignLag = align_offset;
         obj.paw.t = obj.paw.t + align_offset;
         obj.plotStreams;
         notify(obj,'align');
      end
      
      
   end

end