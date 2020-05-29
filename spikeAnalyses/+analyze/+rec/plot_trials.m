function [fig,Tsub] = plot_trials(T,align,outcome,doSave,iSubset)
%PLOT_TRIALS  Plot rate profiles for all channels on individual subplots
%
%  fig = analyze.rec.plot_trials(T,align,outcome,doSave,iSubset);
%  [fig,Tsub] = analyze.rec.plot_trials(T,align,outcome,doSave,iSubset);
%
% Inputs
%  T        - Any table that has .Rate variable and .t UserData property, 
%             as well as .Alignment, .BlockID, and .Outcome
%  align    - Char array of alignment to plot trial for
%  outcome  - Char array or cell array of outcome to include
%  doSave   - Default -- false; if true, saves and deletes fig handles
%  iSubset  - Default -- `inf`; if specified as non-inf **scalar** integer,
%              then instead of iterating on all possible combinations it
%              only does a random subset of `iSubset` iterations
%
% Output
%  fig      - Figure handle
%  Tsub     - (Optional) Subset used if `iSubset` was used

if nargin < 5
   iSubset = inf;
end

if nargin < 4
   doSave = false;
end

if nargin < 3
   outcome = {'Successful','Unsuccessful'};
end

if nargin < 2
   align = 'Reach';
end

uBlock = unique(T.BlockID);
nBlock = numel(uBlock);
if nBlock > 1
   fcn = @analyze.rec.plot_trials;
   if isinf(iSubset)
      fig = analyze.rec.iterate(fcn,T,align,outcome,doSave,iSubset);
      if nargout > 1
         Tsub = T;
      end
   else
      Tsub = T(ismember(T.BlockID,uBlock(randperm(nBlock,iSubset))),:);
      fig = analyze.rec.iterate(fcn,Tsub,align,outcome,doSave,inf);
   end
   if doSave
      if nargout < 1
         clear fig;
      end
   end

   return;
else
   Tsub = [];
end

poDay = T.PostOpDay(1);
rat = sprintf('RC-%02g',T.Rat(1));
t = T.Properties.UserData.t;
str = sprintf('%s - PO-%02g - %s',rat,poDay,align);
fig = figure(...
   'Name',sprintf('Trial Spike Rates: %s',str),...
   'NumberTitle','off',...
   'Color','w',...
   'Units','Normalized',...
   'Position',[0.1 0.1 0.8 0.8]);

tsub = T(ismember(T.Outcome,outcome) & T.Alignment==align,:);
[xtick,ytick,y_lim,rate_colors,n_trial_max] = defaults.rec_analyses(...
   'rate_xtick','rate_ytick','rate_ylim','rate_colors','n_trial_max');

[uTrialID,iID] = unique(tsub.Trial_ID);
nTotal = numel(uTrialID);
nTrial = nTotal;

nThis = min(n_trial_max,nTotal);
if nThis < n_trial_max
   nRow = floor(sqrt(nThis));
   nCol = ceil(nThis/nRow);
else
   nRow = 4;
   nCol = 8;
end

for iTrial = 1:nThis
   iThis = randi(nTrial,1);
   nTrial = nTrial - 1;
   thisTrial = uTrialID{iThis};
   thisID = iID(iThis);
   uTrialID(iThis) = [];
   iID(iThis) = [];
   x = tsub(strcmp(tsub.Trial_ID,thisTrial),:);
   if isempty(x)
      continue;
   end
   ax = subplot(nRow,nCol,iTrial);
   ax.NextPlot = 'add';
   ax.XColor = 'k';
   ax.YColor = 'k';
   ax.LineWidth = 1.5;
   x_cfa = x(x.Area=='CFA',:);
   x_rfa = x(x.Area=='RFA',:);
   for iCh = 1:size(x_cfa,1)
      ch = x_cfa.Channel(iCh);
      c = rate_colors.CFA(ch+1,:);
      plot(ax,t,x_cfa.Rate(iCh,:),...
         'Color',c,'LineWidth',1,...
         'DisplayName',sprintf('CFA-%02g',ch));
   end
   for iCh = 1:size(x_rfa,1)
      ch = x_rfa.Channel(iCh);
      c = rate_colors.RFA(ch+1,:);
      plot(ax,t,x_rfa.Rate(iCh,:),...
         'Color',c,'LineWidth',2,...
         'DisplayName',sprintf('RFA-%02g',ch));
   end
   trialInfo = strsplit(thisTrial,'_');
   trialTitle = sprintf('%s-%s',char(tsub.Outcome(thisID)),trialInfo{end});
   title(trialTitle,'FontName','Arial','Color','k');
   xlim(ax,[t(1) t(end)]);
   ylim(ax,y_lim);
   ax.XTick = xtick;
   ax.YTick = ytick;
end
suptitle(str);
if doSave
   p = defaults.files('rec_analyses_fig_dir');
   if iscell(outcome)
      outStr = strjoin(outcome,'-');
   else
      outStr = outcome;
   end
   if exist(fullfile(p,outStr),'dir')==0
      mkdir(fullfile(p,outStr));
   end
   savefig(fig,fullfile(p,outStr,['Trials - ' str '.fig']));
   saveas(fig,fullfile(p,outStr,['Trials - ' str '.png']));
   delete(fig);
end

end