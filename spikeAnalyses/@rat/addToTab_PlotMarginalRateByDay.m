function p = addToTab_PlotMarginalRateByDay(obj,p,align,includeStructPlot,includeStructMarg)
%% ADDTOPANEL_PLOTMARGINALRATEBYDAY   Plot marginal (normalized) rate by day
%
%  p = ADDTOPANEL_PLOTMARGINALRATEBYDAY(obj,p,align);
%  p = ADDTOPANEL_PLOTMARGINALRATEBYDAY(obj,___,includeStructPlot);
%  p = ADDTOPANEL_PLOTMARGINALRATEBYDAY(obj,___,includeStructMarg);
%
%  --------
%   INPUTS
%  --------
%     obj      :     RAT class object.
%
%     p        :     uiPanel container object that will hold the plots
%
%  includeStructPlot, includeStructMarg : Structs that determine via
%           'Include' and 'Exclude' field cell arrays of char vectors what
%           marginalizations will occur
%           (e.g. struct.Include = {'Reach','Outcome'} would use only
%           trials with a Reach identified and would only take Successful
%           trials)

%% PARSE INPUT
if ~isa(obj,'rat')
   error('First input argument must be RAT class object.');
end

if ~isa(p,'matlab.ui.container.Tab')
   error('Second input argument must be a uitab');
end

if nargin < 3
   align = defaults.block('alignment');
end

if nargin < 4
   includeStructPlot = defaults.rat('includeStructPlot');
end

if nargin < 5
   includeStructPlot = defaults.rat('includeStructMarg');
end

%% HANDLE OBJECT ARRAYS
if numel(obj) > 1
   if numel(p) ~= numel(obj)
      error('If passing an array of RAT objects, must specify a uipanel array as well.');
   end
   for ii = 1:numel(obj)
      p(ii) = addToTab_PlotMarginalRateByDay(obj(ii),p(ii),align,includeStructPlot,includeStructMarg);
   end
   return;
end

%%
nAxes = numel(obj.ChannelInfo);
nDays = numel(obj.Children);
total_rate_avg_subplots = defaults.rat('total_rate_avg_subplots');
legPlot = defaults.rat('rate_avg_leg_subplot');

ax = uiPanelizeAxes(p,total_rate_avg_subplots);

% Assumption is that there is a maximum of 32 channels to plot
% Assume that legend subplot goes on the last axes
for iCh = (nAxes+1):(total_rate_avg_subplots-1)
   delete(ax(iCh));
end

% Parse parameters for coloring lines, smoothing plots
[cm,nColorOpts] = defaults.load_cm;
idx = round(linspace(1,size(cm,1),nColorOpts));

% Make a separate axes for each channel
for iCh = 1:nAxes
   ax(iCh) = obj.createRateAxes(obj.ChannelMask(iCh),...
      obj.ChannelInfo(iCh),ax(iCh));
end

% Shift legend axes over a little bit and make it wider while
% squishing it slightly in the vertical direction:
pos = ax(legPlot).Position;
ax(legPlot).Position = pos + [-2.75 * pos(3),  0.33 * pos(4),...
   2.5 * pos(3), -0.33 * pos(4)];

obj.chMod = zeros(nDays,1);

for ii = 1:nDays
   % Superimpose marginalized rate traces
   [tmp,t,~,flag] = getMeanMargRate(obj.Children(ii),...
         align,includeStructPlot,includeStructMarg,'Full',true);
   
   if ~flag
      continue;
   end
   
   poDay = obj.Children(ii).PostOpDay;
   rate = nan(numel(t),numel(obj.ChannelInfo));
   chh = find(obj.Children(ii).ChannelMask);
   rate(:,chh) = tmp; %#ok<*FNDSB>

   for iCh = 1:nAxes
      ch = obj.Children(ii).matchChannel(iCh);
      if isempty(ch)
         continue;
      end
      if obj.Children(ii).nTrialRecent.rate < 10   
         plot(ax(iCh),t,rate(:,ch),...
            'Color',cm(idx(poDay),:),...  % color by day
            'LineStyle',':',...
            'LineWidth',0.75,...
            'UserData',[iCh,ii]);
      else
         plot(ax(iCh),t,rate(:,ch),...
            'Color',cm(idx(poDay),:),...  % color by day
            'LineWidth',2.25-(poDay/numel(idx)),...
            'UserData',[iCh,ii]);
      end
   end
end

% Tally the total number of trials used for the cross-day marginalization
totalMargTrials = 0;
for ii = 1:nDays
   if ~isempty(obj.Children(ii).nTrialRecent)
      totalMargTrials = totalMargTrials + obj.Children(ii).nTrialRecent.marg;
   end
end
p.Title = [obj.Name sprintf(' [%g]',totalMargTrials)];

% Make "score by day" plot
obj.addToAx_PlotScoreByDay(ax(legPlot));

end