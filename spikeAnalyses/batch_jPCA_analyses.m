%% BATCH_JPCA_ANALYSES  Script for batch run on jPCA
clearvars -except gData
clc;

%% Load data
ticTimes = struct;
if exist('gData','var')==0
   loadTic = tic;
   fprintf(1,'Loading gData object...');
   load('Updated_Scoring_gData.mat','gData');
   ticTimes.load = round(toc(loadTic));
   fprintf(1,'complete (%g sec elapsed)\n',ticTimes.load);
end

%% Run jPCA initial estimations & reprojections
jPCA_tic = tic;
jPCA(gData,'Grasp');
jPCA_All(gData,'Grasp');

% % Note: jPCA "by area" is not working as intended currently (10/18/19)
% jPCA_suppress(gData,'RFA','Grasp','Successful');
% jPCA_suppress(gData,'CFA','Grasp','Successful');
% jPCA_All(gData,'Grasp','CFA');
% jPCA_All(gData,'Grasp','RFA');

unifyjPCA(gData,'Grasp');
ticTimes.extract = round(toc(jPCA_tic));
fprintf(1,'\n\t\t------\njPC extractions complete\n\t\t------\n-->\t(%g sec elapsed).\n',...
   ticTimes.extract);

%% MAKE INDIVIDUAL MOVIES
clc;
movieTic = tic;
J = getProp(gData,'Data');
fprintf(1,'Exporting movies...\n\n');
for iJ = 1:size(J,1)
% for iJ = 42:size(J,1)
   export_single_day_phase_movies(J,iJ,'Grasp','Successful','Full');
end
fprintf(1,'\n-->\t Movie export complete!\n');
ticTimes.movie_export = round(toc(movieTic));
fprintf(1,'\t-->\t(%g sec elapsed)\n\n',ticTimes.movie_export);

%% SAVE AT END
fprintf(1,'Saving...');
saveTic = tic;
save('Updated_Scoring_gData.mat','gData','-v7.3');
ticTimes.save = round(toc(saveTic));
fprintf(1,'complete (%g sec elapsed)\n\n\n',ticTimes.save);