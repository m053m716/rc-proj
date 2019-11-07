%% BATCH_SET_XC_MEANS_RUN_CONDITION_RESPONSE_CORRELATIONS 

%% Load data
if exist('gData','var')==0
   group.loadGroupData;
end

%% Set cross-day means (can take a while)
setXCmeansTic = tic;
setCrossCondMean(gData);
ticTimes.setXCmeans = round(toc(setXCmeansTic));
fprintf(1,'\n\n-->\tFinished setting cross-day means (%g sec elapsed)\n\n\n',ticTimes.setXCmeans);

%% Get condition-response-correlations (< 1 minute more or less)
getRTic = tic;
[r,err,n] = getChannelResponseCorrelationsByDay(gData);
ticTimes.getR = round(toc(getRTic));
fprintf(1,'\n\n-->\tFinished getting condition-response correlations (%g sec elapsed)\n\n\n',ticTimes.getR);

%% Save data (takes a few minutes usually)
ticTimes = saveGroupData(gData,ticTimes);
