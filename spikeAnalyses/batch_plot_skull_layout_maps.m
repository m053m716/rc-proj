%% BATCH_PLOT_SKULL_LAYOUT_MAPS  Script to run figure exports for top-down views of channel activations

%% Load data
if exist('gData','var')==0
   group.loadGroupData;
end

%% Aggregate low-frequency ("LFO") coherence plot
% NOTE: (Not the same as LFO from Ramanthan 2018 paper, since that is
%   spike-field coherence or LFP power in 1.5-5 Hz field; this is just to
%   reference that the 1.5-5Hz frequency range is used)
% Based on all successful grasps that also have a reach (not multi-flail
% attempts). Coherence is the mean sum of coherences within the frequency 
% range of 1.5- to 5-Hz between each within-day spike rate average for that
% alignment to the cross-day spike rate average.

[fig,tstr] = plotSkullLayout(gData,'coh');
savefig(fig,fullfile(group.getPathTo('skullmaps'),...
   sprintf('Skull-Plot_Coherence-Weighted_%s.fig',tstr)));
saveas(fig,fullfile(group.getPathTo('skullmaps'),...
   sprintf('Skull-Plot_Coherence-Weighted_%s.png',tstr)));
delete(fig);

%% "LFO" coherence plots parsed by conditions
% Use different values from defaults to get the coherence ranges 
% (and day ranges). Generic format is:
%
% fig = plotSkullLayout(gData,'coh',f_min_max,poday_min_max);
%
%                       -- or --
%
% mSizeData = getMeanBandCoherence(gData,f_lb,f_ub,poday_lb,poday_ub);
% fig = plotSkullLayout(gData,mSizeData,f_min_max,poday_min_max);
%

LFO = [1.5 5];% (Hz)
HFO = [7 12]; % (Hz) "High-frequency" oscillations just to contrast "Low"
PO1 = [4 10]; % days (PO-0 to PO-3 unstable and too few trials)
PO2 = [11 17];% days
PO3 = [18 24];% days

% LFO-Week-1 
[fig,tstr] = plotSkullLayout(gData,'coh',LFO,PO1);
savefig(fig,fullfile(group.getPathTo('skullmaps'),...
   sprintf('Skull-Plot_Coherence-Weighted_%s.fig',tstr)));
saveas(fig,fullfile(group.getPathTo('skullmaps'),...
   sprintf('Skull-Plot_Coherence-Weighted_%s.png',tstr)));
delete(fig);

% LFO-Week-2
[fig,tstr] = plotSkullLayout(gData,'coh',LFO,PO2);
savefig(fig,fullfile(group.getPathTo('skullmaps'),...
   sprintf('Skull-Plot_Coherence-Weighted_%s.fig',tstr)));
saveas(fig,fullfile(group.getPathTo('skullmaps'),...
   sprintf('Skull-Plot_Coherence-Weighted_%s.png',tstr)));
delete(fig);

% LFO-Week-3
[fig,tstr] = plotSkullLayout(gData,'coh',LFO,PO3);
savefig(fig,fullfile(group.getPathTo('skullmaps'),...
   sprintf('Skull-Plot_Coherence-Weighted_%s.fig',tstr)));
saveas(fig,fullfile(group.getPathTo('skullmaps'),...
   sprintf('Skull-Plot_Coherence-Weighted_%s.png',tstr)));
delete(fig);

% HFO-Week-1
[fig,tstr] = plotSkullLayout(gData,'coh',HFO,PO1);
savefig(fig,fullfile(group.getPathTo('skullmaps'),...
   sprintf('Skull-Plot_Coherence-Weighted_%s.fig',tstr)));
saveas(fig,fullfile(group.getPathTo('skullmaps'),...
   sprintf('Skull-Plot_Coherence-Weighted_%s.png',tstr)));
delete(fig);

% HFO-Week-2
[fig,tstr] = plotSkullLayout(gData,'coh',HFO,PO2);
savefig(fig,fullfile(group.getPathTo('skullmaps'),...
   sprintf('Skull-Plot_Coherence-Weighted_%s.fig',tstr)));
saveas(fig,fullfile(group.getPathTo('skullmaps'),...
   sprintf('Skull-Plot_Coherence-Weighted_%s.png',tstr)));
delete(fig);

% HFO-Week-3
[fig,tstr] = plotSkullLayout(gData,'coh',HFO,PO3);
savefig(fig,fullfile(group.getPathTo('skullmaps'),...
   sprintf('Skull-Plot_Coherence-Weighted_%s.fig',tstr)));
saveas(fig,fullfile(group.getPathTo('skullmaps'),...
   sprintf('Skull-Plot_Coherence-Weighted_%s.png',tstr)));
delete(fig);