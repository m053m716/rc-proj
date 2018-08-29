classdef vidUpdateListener < handle
%% VIDUPDATELISTENER    Class to update video scoring UI on frame update
   

   properties 
%       graphics % Has the following fields:
      neuTime_display  % Text displaying neural data time
      vidTime_display  % Text displaying video time
      videoFile        % VideoReader file object
      image_display    % Graphics image object for displaying current frame
      neuTime_line     % Line indicating neural time
      vidTime_line     % Line indicating video time
      
      zoomOffset = 2; % Offset (sec)
   end


   methods
      % Create the video information listener that updates other objects on
      % a frame change (to prevent copy/paste a lot of the same stuff into
      % many sub-functions of the ScoreVideo main funciton)
      function obj = vidUpdateListener(vidInfo_obj,alignInfo_obj,graphics)
         gobj = fieldnames(graphics);
         for ii = 1:numel(gobj)
            if ismember(gobj{ii},properties(obj))
               obj.(gobj{ii}) = graphics.(gobj{ii});
            end
         end
         
         addlistener(vidInfo_obj,...
            'frameChanged',@obj.updateFrame);
         addlistener(vidInfo_obj,...
            'vidChanged',@obj.updateVideo);
         
         addlistener(alignInfo_obj,...
            'align',@(o,e) obj.updateAlignment(o,e,vidInfo_obj));
         
         obj.updateFrame(vidInfo_obj,nan);
         
      end
      
      function updateAlignment(obj,src,~,v)
         v.setOffset(src.getOffset);
         v.updateTime;
         obj.updateFrame(v,nan);
         
      end
      
      % Change any graphics associated with a frame update
      function updateFrame(obj,src,~)
         set(obj.neuTime_display,'String',...
               sprintf('Neural Time: %0.2f',src.neuralTime));
         set(obj.vidTime_display,'String',...
               sprintf('Video Time: %0.2f',src.vidTime));
         set(obj.image_display,'CData',...
               obj.videoFile.read(src.getFrame));
            
         set(obj.neuTime_line,'XData',ones(1,2) * src.neuralTime);
         set(obj.vidTime_line,'XData',ones(1,2) * src.vidTime);
         
         % Fix axis limits
         if src.vidTime > obj.vidTime_line.Parent.XLim(2)
            if src.neuralTime < src.vidTime
               obj.neuTime_line.Parent.XLim = [src.neuralTime - obj.zoomOffset, ...
                                               src.vidTime + obj.zoomOffset]; 
            else
               obj.neuTime_line.Parent.XLim = [src.vidTime - obj.zoomOffset, ...
                                               src.neuralTime + obj.zoomOffset]; 
            end
         elseif src.vidTime < obj.vidTime_line.Parent.XLim(1)
            if src.neuralTime < src.vidTime
               obj.neuTime_line.Parent.XLim = [src.neuralTime - obj.zoomOffset, ...
                                               src.vidTime + obj.zoomOffset]; 
            else
               obj.neuTime_line.Parent.XLim = [src.vidTime - obj.zoomOffset, ...
                                               src.neuralTime + obj.zoomOffset]; 
            end
         end
         
         drawnow;
         
      end
      
      % Change any graphics associated with a different video
      function updateVideo(obj,src,~)        
         src.setVidTime(src.getVidTime(src.getCurrentNeuralTime));
         
         % Update the correct frame, last
         obj.updateFrame(src,nan);
         
      end
      
      % Change the actual video file
      function setVideo(obj,v)
         delete(obj.videoFile);
         obj.videoFile = v;
      end
      
   end
   
end