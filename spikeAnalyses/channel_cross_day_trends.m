%CHANNEL_CROSS_DAY_TRENDS Define channel trend subtypes for Figs. 3, S6: Can we define sub-types of unit activity trends and associate them with an area/group combination? 
%  Evaluate trends on a per-channel basis across days, with respect to 
%  spike rates in pre-defined epochs as they fluctuate over the time-course
%  of all recordings. 
%
% Treats the spike rates during these epochs as a spline effect; values are
% interpolated and smoothed (using sgolayfilt). 

%% Load data
clc;
clearvars -except r
if exist('r','var')==0
   r = utils.loadTables('rate');
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
%              r.Properties.UserData.Excluded
r.Properties.UserData.Excluded = ...
   (r.Alignment~="Grasp") | ...
   (r.N_Total./2.4 >= 300) | ...
   (r.N_Total./2.4 <= 2.5) | ...
   (r.Duration <= 0.100) |  ...
   (r.Duration >= 0.750);

% % Get data table where rows are Channel observations across all days % %
Y = analyze.stat.interpolateUniformTrend(r);

% % Create output data structs using PCA % %
Grasp = struct('epoch','Grasp','desc',["Early","Mid","Late"],'day',Y.Properties.UserData.PostOpDay,'Group',Y.Group,'Area',Y.Area);
[Grasp.coeff,Grasp.score,~,~,Grasp.explained,Grasp.mu] = pca(Y.Grasp' - Y.Pre');
Reach = struct('epoch','Reach','desc',["Late","Mid","Early"],'day',Y.Properties.UserData.PostOpDay,'Group',Y.Group,'Area',Y.Area);
[Reach.coeff,Reach.score,~,~,Reach.explained,Reach.mu] = pca(Y.Reach' - Y.Pre');
Retract = struct('epoch','Retract','desc',["Late","Mid","Early"],'day',Y.Properties.UserData.PostOpDay,'Group',Y.Group,'Area',Y.Area);
[Retract.coeff,Retract.score,~,~,Retract.explained,Retract.mu] = pca(Y.Retract' - Y.Pre');
Reach.labels = categorical(strcat(string(Y.Group),"::",string(Y.Area)));
Grasp.labels = categorical(strcat(string(Y.Group),"::",string(Y.Area)));
Retract.labels = categorical(strcat(string(Y.Group),"::",string(Y.Area)));

% Set parameters
pars.Group = ["Ischemia";"Intact"]; 
pars.Area = ["RFA";"CFA"];
pars.gplotPars = struct;
pars.gplotPars.Groups = categorical(strcat(string(Y.Group),"::",string(Y.Area)));
pars.gplotPars.clr = [0.4 0.4 1.0; 0.2 0.2 0.8; 1.0 0.4 0.4; 0.8 0.2 0.2];
pars.gplotPars.sym = 'sox.';
pars.gplotPars.siz = 10;
pars.gplotPars.doleg = true;
pars.gplotPars.dispopt = 'grpbars';
pars.gplotPars.xnam = ["PC-1","PC-2","PC-3"];
pars.mrk = struct('Ischemia',...
   struct('RFA','.',...
          'CFA','x'), ...
       'Intact',...
    struct('RFA','o',...
           'CFA','s'));
pars.C = struct('Ischemia',...
   struct('RFA',[0.8 0.2 0.2],...
          'CFA',[1.0 0.4 0.4]), ...
       'Intact',...
    struct('RFA',[0.2 0.2 0.8],...
           'CFA',[0.4 0.4 1.0]));

%% Make figures
% % % % Generate Figures % % % %
% Step 1: Visualize distribution of principal components -- are there
%  trends in these data, in terms of "groupings" of channel-level trends
%  across days?

outPath = defaults.files('reach_extension_figure_dir');
if exist(outPath,'dir')==0
   mkdir(outPath);
end

% Create figures for Grasp trends %
% % Create Line Plots for primary channel trends across days % %
fig = analyze.pc.perChannelPCtrends(Grasp);
saveas(fig,fullfile(outPath,'FigS6 - Grasp Channel Trends.png'));
savefig(fig,fullfile(outPath,'FigS6 - Grasp Channel Trends.fig'));
delete(fig);

% % Plot 3D Scatter of coefficients % %
fig = analyze.pc.perChannelPCtrendScatter(Grasp,pars);
saveas(fig,fullfile(outPath,'FigS6 - Grasp PC Coefficients.png'));
savefig(fig,fullfile(outPath,'FigS6 - Grasp PC Coefficients.fig'));
delete(fig);

fig = analyze.pc.perChannelPCgplotMatrix(Grasp,pars);
saveas(fig,fullfile(outPath,'FigS6 - Grasp PC Coeff GPlotMatrix.png'));
savefig(fig,fullfile(outPath,'FigS6 - Grasp PC Coeff GPlotMatrix.fig'));
delete(fig);

% Create figures for Reach trends %
% % Create Line Plots for primary channel trends across days % %
fig = analyze.pc.perChannelPCtrends(Reach);
saveas(fig,fullfile(outPath,'FigS6 - Reach Channel Trends.png'));
savefig(fig,fullfile(outPath,'FigS6 - Reach Channel Trends.fig'));
delete(fig);

% % Plot 3D Scatter of coefficients % %
fig = analyze.pc.perChannelPCtrendScatter(Reach,pars);
saveas(fig,fullfile(outPath,'FigS6 - Reach PC Coefficients.png'));
savefig(fig,fullfile(outPath,'FigS6 - Reach PC Coefficients.fig'));
delete(fig);

fig = analyze.pc.perChannelPCgplotMatrix(Reach,pars);
saveas(fig,fullfile(outPath,'FigS6 - Reach PC Coeff GPlotMatrix.png'));
savefig(fig,fullfile(outPath,'FigS6 - Reach PC Coeff GPlotMatrix.fig'));
delete(fig);

% Create figures for Retract trends %
fig = analyze.pc.perChannelPCtrends(Retract);
saveas(fig,fullfile(outPath,'FigS6 - Retract Channel Trends.png'));
savefig(fig,fullfile(outPath,'FigS6 - Retract Channel Trends.fig'));
delete(fig);

% % Plot 3D Scatter of coefficients % %
fig = analyze.pc.perChannelPCtrendScatter(Retract,pars);
saveas(fig,fullfile(outPath,'FigS6 - Retract PC Coefficients.png'));
savefig(fig,fullfile(outPath,'FigS6 - Retract PC Coefficients.fig'));
delete(fig);

fig = analyze.pc.perChannelPCgplotMatrix(Retract,pars);
saveas(fig,fullfile(outPath,'FigS6 - Retract PC Coeff GPlotMatrix.png'));
savefig(fig,fullfile(outPath,'FigS6 - Retract PC Coeff GPlotMatrix.fig'));
delete(fig);

% %
D = utils.loadTables('multi'); % Load "multi-jPCA" table.
CID = vertcat(D.CID{:});
CID = outerjoin(CID,Y,...
   'Keys',{'AnimalID','Alignment','ChannelID','ICMS','Area'},...
   'MergeKeys',true,'Type','Left',...
   'RightVariables',{'Group','Early','Mid','Late'});
CID = CID(CID.Alignment=="Grasp",:);
[~,iU] = unique(CID.ChannelID);
CID = CID(iU,:);
figure; gplotmatrix(...
   [CID.X,CID.Y],...
   [CID.Early,CID.Mid,CID.Late],...
   CID.AnimalID,...
   [0.9 0.1 0.1; ... % RC-02
    0.9 0.1 0.1; ... % RC-04
    0.9 0.1 0.1; ... % RC-05
    0.9 0.1 0.1; ... % RC-08 
    0.1 0.1 0.9; ... % RC-14
    0.9 0.1 0.1; ... % RC-26
    0.9 0.1 0.1; ... % RC-30
    0.1 0.1 0.9],... % RC-43
   'oshpov^s',[],'on','hist',...
   {'AP (mm)','ML (mm)'},...
   {'Early','Mid','Late'});


%% Recover GLME models
% % % % We see that there are a few principal components that explain a
% majority (top-3 explain > 90% of data variance in each epoch % % % %
% Step 2: There are trend "groupings." Are there statistically significant
% differences in the presence of each "grouping" by area?         % % % %

% Reach PC-1: Week-4 involved  ---- >> "Late"
% Reach PC-2: Week-3 involved  ---- >> "Mid"
% Reach PC-3: Weeks-1,2 involved -- >> "Early"

Y.Early = Reach.coeff(:,3);
Y.Mid = Reach.coeff(:,2);
Y.Late = Reach.coeff(:,1);
Y.Properties.RowNames = strcat(string(Y.AnimalID),"::",string(Y.Area),"::",string(Y.ChannelID));

% Fit "Early" (PC-3) component coefficients
fprintf(1,'--------------------------------------------------------------\n');
glme.channelTrends = struct;
glme.channelTrends.early.id = 19;
glme.channelTrends.early.mdl = fitglme(Y,...
   "Early~1+Area*Group+(1|AnimalID)+(1|ICMS)",...
   "Distribution","normal",...
   "Link","identity",...
   "FitMethod","REMPL");
disp(glme.channelTrends.early.mdl);
fprintf(1,'--------------------------------------------------------------\n');
fprintf(1,'Fit: <strong>Early</strong>\n');
disp(glme.channelTrends.early.mdl.Rsquared);
fprintf(1,'--------------------------------------------------------------\n');

% Fit "Mid" (PC-2) component coefficients
fprintf(1,'--------------------------------------------------------------\n');
glme.channelTrends.mid.id = 20;
glme.channelTrends.mid.mdl = fitglme(Y,...
   "Mid~1+Area*Group+(1|AnimalID)+(1|ICMS)",...
   "Distribution","normal",...
   "Link","identity",...
   "FitMethod","REMPL");
disp(glme.channelTrends.mid.mdl);
fprintf(1,'--------------------------------------------------------------\n');
fprintf(1,'Fit: <strong>Mid</strong>\n');
disp(glme.channelTrends.mid.mdl.Rsquared);
fprintf(1,'--------------------------------------------------------------\n');

% Fit "Late" (PC-1) component coefficients
fprintf(1,'--------------------------------------------------------------\n');
glme.channelTrends.late.id = 21;
glme.channelTrends.late.mdl = fitglme(Y,...
   "Late~1+Area*Group+(1|AnimalID)+(1|ICMS)",...
   "Distribution","normal",...
   "Link","identity",...
   "FitMethod","REMPL");
disp(glme.channelTrends.late.mdl);
fprintf(1,'--------------------------------------------------------------\n');
fprintf(1,'Fit: <strong>Early</strong>\n');
disp(glme.channelTrends.late.mdl.Rsquared);
fprintf(1,'--------------------------------------------------------------\n');

%% Save models
clc;
utils.displayModel(glme.channelTrends,0.05); % Display all models
tic; fprintf(1,'Saving Fig [3,S6] models...');
tmp = glme.channelTrends;
save(defaults.files('cross_day_channel_trends_models_matfile'),'-struct','tmp');
clear tmp;
fprintf(1,'complete\n'); 
fprintf(1,'\t->\t%6.2f seconds elapsed\n',toc);
utils.addHelperRepos();
sounds__.play('bell',0.8,-15);

