function fig = plot_rate(T,align,outcome,doSave)
%PLOT_RATE  Plot rate profiles for individual trials as subplots
%
%  fig = analyze.rec.plot_rate(T,align,outcome,doSave);
%
%  -- Inputs --
%  T : Any table that has .Rate variable and .t UserData property, as well
%        as .Alignment, .BlockID, and .Outcome
%  align : Char array of alignment to plot trial for
%  outcome : Char array or cell array of outcome to include
%  doSave : Default -- false; if true, saves and deletes fig handles
%
%  -- Output --
%  fig : Figure handle

if nargin < 4
   doSave = false;
end

if nargin < 3
   outcome = {'Successful','Unsuccessful'};
end

if nargin < 2
   align = 'Reach';
end

if numel(unique(T.BlockID)) > 1
   fcn = @analyze.rec.plot_rate;
   fig = analyze.rec.iterate(fcn,T,align,outcome,doSave);
   if doSave
      if nargout < 1
         clear fig;
      end
   end
   return;
end

poDay = T.PostOpDay(1);
rat = sprintf('RC-%02g',T.Rat(1));
t = T.Properties.UserData.t;
str = sprintf('%s - PO-%02g - %s',rat,poDay,align);

fig = figure(...
   'Name',sprintf('Spike Rates: %s',str),...
   'NumberTitle','off',...
   'Color','w',...
   'Units','Normalized',...
   'Position',[0.1 0.1 0.8 0.8]);

tsub = T(ismember(T.Outcome,outcome) & T.Alignment==align,:);
[xtick,ytick,y_lim,rate_colors] = defaults.rec_analyses(...
   'rate_xtick','rate_ytick','rate_ylim','rate_colors');

% % Plot CFA on top rows % %
c = tsub(tsub.Area=='CFA',:);
col = rate_colors.CFA;
for iCh = 1:16
   x = c(c.Channel==iCh,:);
   if isempty(x)
      continue;
   end
   ax = subplot(4,8,iCh);
   ax.NextPlot = 'add';
   ax.XColor = 'k';
   ax.YColor = 'k';
   ax.LineWidth = 1.5;
   plot(ax,t,x.Rate,'Color',col(iCh+1,:),'LineWidth',1);
   title(char(x.ICMS(1)));
   xlim(ax,[t(1) t(end)]);
   ylim(ax,y_lim);
   ax.XTick = xtick;
   ax.YTick = ytick;
end

c = tsub(tsub.Area=='RFA',:);
col = rate_colors.RFA;
for iCh = 1:16
   x = c(c.Channel==iCh,:);
   if isempty(x)
      continue;
   end
   ax = subplot(4,8,iCh+16);
   ax.NextPlot = 'add';
   ax.XColor = 'k';
   ax.YColor = 'k';
   ax.LineWidth = 1.5;
   plot(ax,t,x.Rate,'Color',col(iCh+1,:),'LineWidth',1);
   title(char(x.ICMS(1)));
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
   savefig(fig,fullfile(p,[str ' - ' outStr '.fig']));
   saveas(fig,fullfile(p,[str ' - ' outStr '.png']));
   delete(fig);
end

end