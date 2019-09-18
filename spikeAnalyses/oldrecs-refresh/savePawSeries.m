function savePawSeries(trackingName,frameRate,saveName)
%% SAVEPAWSERIES  Saves paw series from DLC file to CPL Block format
%
%  SAVEPAWSERIES(trackingName,framerate,saveName);
%
%  --------
%   INPUTS
%  --------
%  trackingName   :     Name of DLC tracking file (.csv)
%
%  frameRate      :     Sampling rate of video file
%
%  saveName       :     Name of output probability stream save file.
%
% By: Max Murphy  v1.0   09/01/2018    Original version (R2017b)

%% EXTRACT DATA
vidTracking = importRC_Grasp(trackingName);

%% FORMAT OUTPUT
data = reshape(vidTracking.grasp_p,1,numel(vidTracking.grasp_p));
fs = frameRate;

%% SAVE DATA STREAM
save(saveName,'data','fs','-v7.3');

end