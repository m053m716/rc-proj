function [smoothedData,allDays] = smoothFitDays(dataToSmooth,postOpDay)
%SMOOTHFITDAYS  Interpolate to all post-op days and smooth data by day
%
%  [smoothedData,allDays] = SMOOTHFITDAYS(dataToSmooth,postOpDay);
%
%  --------
%   INPUTS
%  --------
%  dataToSmooth   :     Vector of data to smooth across days.
%
%  postOpDay      :     Corresponding vector of post-op days for each data
%                          point.
%
%  --------
%   OUTPUT
%  --------
%  smoothedData   :     Vector of data interpolated so that there is a
%                          point for each day between the first and last
%                          post-op Day, and smoothed (e.g.
%                          low-pass-filtered) to make visualization of
%                          trends easier.
%
%  allDays        :     Corresponding days for smoothedData; days start on
%                          the first post-op Day and increments by 1 day
%                          until the last post-op Day.

% PARSE INPUT
if numel(dataToSmooth) ~= numel(postOpDay)
   error('dataToSmooth and postOpDay must have same number of elements.');
end

% INTERPOLATE
allDays = postOpDay(1):postOpDay(end);
iBad = isnan(dataToSmooth) | isinf(dataToSmooth);
dataToSmooth(iBad) = [];
postOpDay(iBad) = [];

if isempty(dataToSmooth)
   smoothedData = nan(size(allDays));
   return;
end

if numel(allDays) == numel(postOpDay)
   x = dataToSmooth;
else   
   x = interp1(postOpDay,dataToSmooth,allDays);
end

% SMOOTH
[b,a] = butter(4,0.2);
smoothedData = filtfilt(b,a,x);



end