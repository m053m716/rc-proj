%% BATCH_MARGINAL_RATE_AVERAGES  Script for batch plot and/or save marginal rate figures
clearvars -except gData
clc;

%% Load data
ticTimes = struct;
if exist('gData','var')==0
   loadTic = tic;
   fprintf(1,'Loading gData object...');
   load(defaults.experiment('group_data_name'),'gData');
   ticTimes.load = round(toc(loadTic));
   fprintf(1,'complete (%g sec elapsed)\n',ticTimes.load);
end

%% Set "include" structs here to specify marginalizations
ALIGN = {'Reach','Grasp'}; % Iterate on this for marginalizations as well

includeStruct = {utils.makeIncludeStruct({'Reach','Grasp','Outcome'},[]); ...
   utils.makeIncludeStruct({'Reach','Grasp','Outcome'},[]);...
   utils.makeIncludeStruct({'Reach','Grasp','Complete'},{'PelletPresent'});...
   utils.makeIncludeStruct({'Grasp','Complete','PelletPresent'},[])}; 

includeStructMarg = {utils.makeIncludeStruct({'Reach','Grasp','Outcome'},[]); ...
   utils.makeIncludeStruct({'Reach','Grasp','Complete'},[]);...
   utils.makeIncludeStruct({'Reach','Grasp','Complete'},{'PelletPresent'});...
   utils.makeIncludeStruct({'Grasp','Complete','PelletPresent'},[])}; 

%% Plot normalized averages by different conditions
plotTic = tic;
plotNormAverages(gData,ALIGN,{'Successful','Unsuccessful','All'});
plotNormAverages(gData,ALIGN,includeStruct([1,3,4]));
ticTimes.plotAverages = toc(plotTic);
fprintf(1,'\n-->\tFinished plotting averages (%g sec elapsed)\n',...
   ticTimes.plotAverages);

%% Plot marginalized averages by different conditions
marginalTic = tic;
plotMargAverages(gData,ALIGN,includeStruct,includeStructMarg);
ticTimes.plotMarginalizations = toc(marginalTic);
fprintf(1,'\n-->\tFinished plotting averages (%g sec elapsed)\n',...
   ticTimes.plotMarginalizations);

%% Make a single figure (ad hoc; gData(1) = lesion group; 2 = intact group)
% fig = plotMargAverages(gData(1),'Grasp',includeStruct{1},includeStructMarg{1});