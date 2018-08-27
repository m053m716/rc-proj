classdef vidUpdateListener < handle
%% VIDUPDATELISTENER    Class to update video scoring UI on frame update
   

   properties 
      neuTime_display  % Text displaying neural data time
      vidTime_display  % Text displaying video time
      videoFile        % VideoReader file object
      image_display    % Graphics image object for displaying current frame
      buttonList_display % ListBox with trials as button times
   end


   methods
      % Create the video information listener that updates other objects on
      % a frame change (to prevent copy/paste a lot of the same stuff into
      % many sub-functions of the ScoreVideo main funciton)
      function obj = vidUpdateListener(vidInfo_obj,neuTime_obj,vidTime_obj,vid_obj,im_obj,btnList_obj)
         obj.neuTime_display = neuTime_obj;
         obj.vidTime_display = vidTime_obj;
         obj.videoFile = vid_obj;
         obj.image_display = im_obj;
         obj.buttonList_display = btnList_obj;
         
         addlistener(vidInfo_obj,...
            'frameChanged',@obj.updateFrame);
         
         addlistener(vidInfo_obj,...
            'vidChanged',@obj.updateVideo);
      end
      
      % Change any graphics associated with a frame update
      function updateFrame(obj,src,~)
         set(obj.neuTime_display,'String',...
               sprintf('Neural Time: %0.2f',src.neuralTime));
         set(obj.vidTime_display,'String',...
               sprintf('Video Time: %0.2f',src.vidTime));
         set(obj.image_display,'CData',...
               obj.videoFile.read(src.getFrame));
         
      end
      
      % Change any graphics associated with a different video
      function updateVideo(obj,src,~)
         neuButtonTimes = obj.buttonList_display.UserData;
         vidButtonTimes = src.getVidTime(neuButtonTimes);
         
         % Make sure it's the correct orientation (column vector)
         vidButtonTimes = reshape(vidButtonTimes,numel(vidButtonTimes),1);
         
         % This part takes away unwanted space from the front of the times
         str = cellstr(num2str(vidButtonTimes));
         str = cellfun(@(x) strrep(x,' ',''),str,'UniformOutput',false);
         
         set(obj.buttonList_display,'String',str);
         
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