function fig = durations(T)
%DURATIONS Make figure(s) of durations by Animal using Rate Table
%
%  fig = analyze.behavior.durations(T);
%
%  -- Inputs --
%  T : 'trials' type Rate Table
%
%  -- Output --
%  fig : Figure handle

close all force;

uAlign = unique(T.Alignment);
event = uAlign(1);
T = analyze.slice(T,'Alignment',event);
type = utils.check_table_type(T);
if strcmp(type,'channels')
   T = analyze.trials.make_table(T,event);
end

[name,rat_color] = defaults.experiment('rat','rat_color');

fig = figure(...
      'Name','Trial Duration by Day',...
      'Units','Normalized',...
      'Color','w',...
      'Position',[0.1 0.1 0.8 0.8]...
      );

iThis = 1;
for i = 1:numel(name)
   
   
   tsub = T(T.AnimalID==name{i} & T.Outcome=='Successful',:);
   G = findgroups(tsub(:,'PostOpDay'));
   ax = subplot(10,2,iThis);
   ax.NextPlot = 'add';
   ax.YLim = [0 1.5];
   ax.XLim = [2 30];
   ax.XTick = 7:7:28;
   iThis = iThis + 1;
   splitapply(@(poDay,duration)plot_by_day(ax,rat_color.All(i,:),poDay,duration),...
      tsub.PostOpDay,tsub.Duration,G);
   title(ax,sprintf('%s: Successful',name{i}));
   
   tsub = T(T.AnimalID==name{i} & T.Outcome=='Unsuccessful',:);
   G = findgroups(tsub(:,'PostOpDay'));
   ax = subplot(10,2,iThis);
   ax.NextPlot = 'add';
   ax.YLim = [0 1.5];
   ax.XLim = [2 30];
   ax.XTick = 7:7:28;
   iThis = iThis + 1;
   splitapply(@(poDay,duration)plot_by_day(ax,rat_color.All(i,:),poDay,duration),...
      tsub.PostOpDay,tsub.Duration,G);
   title(ax,sprintf('%s: Unsuccessful',name{i}));
   
end
   function plot_by_day(ax,col,poDay,duration)
      %PLOT_BY_DAY  Add bars to an axis by day
      %
      %  plot_by_day(ax,col,poDay,duration);
      poDay = poDay(1);
      duration = mean(duration);
      bar(ax,poDay,duration,'FaceColor',col,'EdgeColor','none');
      
   end
end