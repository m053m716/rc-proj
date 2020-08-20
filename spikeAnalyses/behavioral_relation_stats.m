%BEHAVIORAL_RELATION_STATS Create figure S4 (Heatmaps)
clc;
clearvars -except r
if exist('r','var')==0
   fprintf(1,'Loading raw rates table...');
   r = getfield(load(defaults.files('learning_rates_table_file'),'r'),'r');
   fprintf(1,'complete\n');
else
   fprintf(1,'Found `r` (<strong>%d</strong> rows) in workspace.',size(r,1));
   k = 5;
   fprintf(1,'\n\t->\tPreview (%d rows):\n\n',k);
   disp(r(randsample(size(r,1),k),:));
end
% `r` has the following exclusions:
%  -> 'Grasp' aligned only
%  -> Min total trial rate: > 2.5 spikes/sec
%  -> Max total trial rate: < 300 spikes/sec
%  -> Min trial duration: 100-ms
%  -> Max trial duration: 750-ms
%  -> Note: some of these are taken care of by
%     r.Properties.UserData.Excluded
PRE_GRASP = [-1350, -750]; % ms
GRASP = [-150 150]; % ms
rSub = r(...
   (r.N_Total > (2.5*2.4)) & ...
   (r.N_Total < (300*2.4)) & ...
   (r.Duration > 0.100)    & ...
   (r.Duration < 0.750)    & ...
   (r.PelletPresent=="Present"),:);

% Get groupings
[G,TID] = findgroups(rSub(:,{'Group','AnimalID','PostOpDay','ICMS','Area','ChannelID','Outcome'}));

% Get Pre-Grasp epoch spike rates
TID.Pre_Mean = splitapply(@nanmean,sqrt(rSub.N_Pre_Grasp./diff(PRE_GRASP*1e-3)),G);
TID.Pre_SD = splitapply(@nanstd,sqrt(rSub.N_Pre_Grasp./diff(PRE_GRASP*1e-3)),G);

% Get epoch spike rates for others
TID.Reach_Mean = splitapply(@(n,t)nanmean(sqrt(n./t)),rSub.N_Reach,rSub.Reach_Epoch_Duration,G);
TID.Reach_SD = splitapply(@(n,t)nanstd(sqrt(n./t)),rSub.N_Reach,rSub.Reach_Epoch_Duration,G);

TID.Retract_Mean = splitapply(@(n,t)nanmean(sqrt(n./t)),rSub.N_Retract,rSub.Retract_Epoch_Duration,G);
TID.Retract_SD = splitapply(@(n,t)nanstd(sqrt(n./t)),rSub.N_Retract,rSub.Retract_Epoch_Duration,G);

TID.Grasp_Mean = splitapply(@(n)nanmean(sqrt(n./diff(GRASP*1e-3))),rSub.N_Grasp,G);
TID.Grasp_SD = splitapply(@(n)nanstd(sqrt(n./diff(GRASP*1e-3))),rSub.N_Grasp,G);

TID.Rate = cell2mat(splitapply(@(rate)...
   {sgolayfilt(nanmean(sgolayfilt(sqrt(rate./2.4),3,7,ones(1,7),2),1),3,13,ones(1,13),2)},rSub.Rate,G));
[~,iMax] = max(TID.Rate,[],2);
[~,iSort] = sort(iMax,'ascend');

tid = TID(iSort,:);

% Create corresponding figures.
outPath = defaults.files('reach_extension_figure_dir');
if exist(outPath,'dir')==0
   mkdir(outPath);
end

fig = figure('Name','Successful Rate Heat Maps','Color','w',...
   'Units','Normalized','Position',[0.16 0.24 0.26 0.57]); 
colormap('jet');
ax = subplot(2,2,1);
imagesc(ax,rSub.Properties.UserData.t,[0 1],tid.Rate(tid.Area=="CFA" & tid.Group=="Intact" & tid.Outcome=="Successful",:));
set(ax,'CLim',[0 3.5]);
colorbar;
title(ax,'Intact::CFA');
ax = subplot(2,2,2);
imagesc(ax,rSub.Properties.UserData.t,[0 1],tid.Rate(tid.Area=="CFA" & tid.Group=="Ischemia" & tid.Outcome=="Successful",:));
set(ax,'CLim',[0 3.5]);
colorbar;
title(ax,'Ischemia::CFA');
ax = subplot(2,2,3);
imagesc(ax,rSub.Properties.UserData.t,[0 1],tid.Rate(tid.Area=="RFA" & tid.Group=="Intact" & tid.Outcome=="Successful",:));
set(ax,'CLim',[0 3.5]);
colorbar;
title(ax,'Intact::RFA');
ax = subplot(2,2,4);
imagesc(ax,rSub.Properties.UserData.t,[0 1],tid.Rate(tid.Area=="RFA" & tid.Group=="Ischemia" & tid.Outcome=="Successful",:));
set(ax,'CLim',[0 3.5]);
colorbar;
title(ax,'Ischemia::RFA');
suptitle('Successful Trials Only');

savefig(fig,fullfile(outPath,'Fig5a - Rate Successful Grasp Heatmaps.fig'));
saveas(fig,fullfile(outPath,'FigS5a - Rate Successful Grasp Heatmaps.png'));
delete(fig);

fig = figure('Name','Successful Rate Heat Maps','Color','w',...
   'Units','Normalized','Position',[0.46 0.24 0.26 0.57]); 
colormap('jet');
ax = subplot(2,2,1);
imagesc(ax,rSub.Properties.UserData.t,[0 1],tid.Rate(tid.Area=="CFA" & tid.Group=="Intact" & tid.Outcome=="Unsuccessful",:));
set(ax,'CLim',[0 3.5]);
colorbar;
title(ax,'Intact::CFA');
ax = subplot(2,2,2);
imagesc(ax,rSub.Properties.UserData.t,[0 1],tid.Rate(tid.Area=="CFA" & tid.Group=="Ischemia" & tid.Outcome=="Unsuccessful",:));
set(ax,'CLim',[0 3.5]);
colorbar;
title(ax,'Ischemia::CFA');
ax = subplot(2,2,3);
imagesc(ax,rSub.Properties.UserData.t,[0 1],tid.Rate(tid.Area=="RFA" & tid.Group=="Intact" & tid.Outcome=="Unsuccessful",:));
set(ax,'CLim',[0 3.5]);
colorbar;
title(ax,'Intact::RFA');
ax = subplot(2,2,4);
imagesc(ax,rSub.Properties.UserData.t,[0 1],tid.Rate(tid.Area=="RFA" & tid.Group=="Ischemia" & tid.Outcome=="Unsuccessful",:));
set(ax,'CLim',[0 3.5]);
colorbar;
title(ax,'Ischemia::RFA');
suptitle('Unsuccessful Trials Only');

savefig(fig,fullfile(outPath,'FigS5b - Rate Unsuccessful Grasp Heatmaps.fig'));
saveas(fig,fullfile(outPath,'FigS5b - Rate Unsuccessful Grasp Heatmaps.png'));
delete(fig);