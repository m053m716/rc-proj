function fig = quick_plotRateAverages(blockFolder,alignType)
%% QUICK_PLOTRATEAVERAGES  Generate a quick plot of rate average for given alignment type
%
%  QUICK_PLOTRATEAVERAGES(blockFolder);
%  fig = QUICK_PLOTRATEAVERAGES(blockFolder,alignType);
%
%  --------
%   INPUTS
%  --------
%  blockFolder    :     Full folder (char array) to recording block.
%
%  alignType      :     'Grasp' or 'Reach' [def] currently.
%
%  --------
%   OUTPUT
%  --------
%     fig         :     Array of figure handles output by function.
%
% By: Max Murphy  v1.0  2019-07-18  Original version (R2017a)

%% CONSTANTS (FOR EASIER MODIFYING LATER)
SMOOTH_W = '030ms';
DEF_ALIGN = 'Reach';

if nargin < 2
   alignType = DEF_ALIGN;
end


block = strsplit(blockFolder,filesep);
block = block{end};

% Get channel information
in = load(fullfile(blockFolder,[block '_ChannelInfo.mat']));

% Load and plot successful reaches (ET-1, EARLY)
x = load(fullfile(blockFolder,...
   [block '_SpikeAnalyses'],...
   [block '_SpikeRate' SMOOTH_W '_' alignType '_Successful.mat']),'data');
nX = size(x.data,1);
X = squeeze(mean(abs(x.data),1));
fig(1,1) = figure('Name',sprintf('%s: Successful %s Average Rate',block,alignType),...
   'Color','w',...
   'Units','Normalized',...
   'Position',[0.1 0.25 0.2 0.4]); 
idx = contains({in.info.area}.','RFA');
rObj = plot(-1999.5:999.5,X(:,idx),'Color','b','LineWidth',1.5);
hold on;
idx = contains({in.info.area}.','CFA');
cObj = plot(-1999.5:999.5,X(:,idx),'Color','r','LineWidth',1.5);
ylim([0 20]);
xlim([-1500 750]); % remove edge effects of filtering
legend([rObj(1),cObj(1)],{'RFA','CFA'},'location','northwest');
title(alignString('Successful',alignType,nX),...
   'FontName','Arial','FontSize',16,'Color','k');
xlabel('Time (msec)','FontName','Arial','FontSize',14,'Color','k');
ylabel('Spike Rate (Instantaneous Z-Score)','FontName','Arial','FontSize',14,'Color','k');

% Load and plot unsuccessful reaches (ET-1, EARLY)
x = load(fullfile(blockFolder,...
   [block '_SpikeAnalyses'],...
   [block '_SpikeRate' SMOOTH_W '_' alignType '_Unsuccessful.mat']),'data');
nY = size(x.data,1);
Y = squeeze(mean(abs(x.data),1));
fig(2,1) = figure('Name',sprintf('%s: Unsuccessful %s Average Rate',block,alignType),...
   'Color','w',...
   'Units','Normalized',...
   'Position',[0.35 0.25 0.2 0.4]);
idx = contains({in.info.area}.','RFA');
rObj = plot(-1999.5:999.5,Y(:,idx),'Color','b','LineWidth',1.5);
hold on;
idx = contains({in.info.area}.','CFA');
cObj = plot(-1999.5:999.5,Y(:,idx),'Color','r','LineWidth',1.5);
ylim([0 20]);
xlim([-1500 750]); % remove edge effects of filtering
legend([rObj(1),cObj(1)],{'RFA','CFA'},'location','northwest');
title(alignString('Unsuccessful',alignType,nY),...
   'FontName','Arial','FontSize',16,'Color','k');
xlabel('Time (msec)','FontName','Arial','FontSize',14,'Color','k');
ylabel('Spike Rate (Instantaneous Z-Score)','FontName','Arial','FontSize',14,'Color','k');

   function str = alignString(outcome,alignment,n)
      if strcmpi(alignment,'Reach')
         str = sprintf('%s Reaches (%g)',outcome,n);
      else
         str = sprintf('%s %ss (%g)',outcome,alignment,n);
      end
   end

end