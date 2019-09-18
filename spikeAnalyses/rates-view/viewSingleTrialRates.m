function fig = viewSingleTrialRates(rate,behaviorData,iCh,varargin)
%% VIEWSINGLETRIALRATES	 View single trial rates for a given recording
%
%	fig = VIEWSINGLETRIALRATES(rate,behaviorData,iCh);
%	fig = VIEWSINGLETRIALRATES(rate,behaviorData,iCh,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%    rate         :     Rate struct, which is an individual cell array
%                          element from the array produced by
%                          PLOTRATEBYDAY.
%
%  behaviorData   :     Resulting table from SCOREVIDEO.
%
%     iCh         :     Index of the channel desired to plot.
%
%  varargin       :     (Optional) 'NAME', value input argument pairs.
%
%  --------
%   OUTPUT
%  --------
%    fig          :     Handle to figure where all successful/unsuccessful
%                          individual trials are plotted and coded by
%                          color.
%
%
% By: Max Murphy  v1.0  12/28/2018  Original Version (R2017a)

%% DEFAULTS
TITLE_STR = '%s %s %s: Ch-%03g - %s';
FIG_POS = [0.1 0.1 0.8 0.8];

YLIM = [-20 20];
XLIM = nan;

N_LINES_TO_DISPLAY = 3;
LINE_W = [0.5 2.5];

PAUSE_DURATION = 1; % Seconds
MOV_NAME = nan;

% All these should have same number elements
VARS = {'Reach','Grasp','Support'};
LS = {'--',':','-.'};
COL = {[0.8 0.8 0.8],[0 0 1],[0 0.6 0]};

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% PARSE NAMING
nameStr = sprintf(TITLE_STR,...
   rate.pars.name,...
   rate.pars.group,...
   rate.info(iCh).area,...
   rate.info(iCh).channel,...
   rate.pars.alignmentEvent);

fig = figure('Name',nameStr,...
   'Color','w',...
   'Units','Normalized',...
   'Position',FIG_POS);

%% PARSE LINE THICKNESSES
lw = linspace(LINE_W(1),LINE_W(2),N_LINES_TO_DISPLAY);
lw = fliplr(lw); % First element should be largest

%% IF MOVIE IS DESIRED, MAKE SURE FILE NAME IS APPROPRIATE AND EXISTS
if ~isnan(MOV_NAME)
   [p,f,e] = fileparts(MOV_NAME);
   if exist(p,'dir')==0
      mkdir(p)
   end
   
   if isempty(e)
      e = '.avi';
   end
   
   mov_idx = 0;
   mov_name = fullfile(p,[f '_' num2str(mov_idx,'%03g') e]);
   while exist(mov_name,'file')~=0
      mov_idx = mov_idx + 1;
      mov_name = fullfile(p,[f '_' num2str(mov_idx,'%03g') e]);
   end
   
   v = VideoWriter(mov_name);
   v.FrameRate = 1/PAUSE_DURATION;
   
   open(v);
end

%% SET UP AXES
if isnan(XLIM(1))
   XLIM = ([min(rate.pars.t) max(rate.pars.t)]);
end


ax = axes(fig,'XColor','k','YColor','k',...
   'XLim',XLIM,'YLim',YLIM,...
   'NextPlot','add');

title(nameStr,'FontName','Arial','Color','k','FontSize',16);
xlabel('Time (sec)','FontName','Arial','Color','k','FontSize',14);
ylabel('Normalized IFR','FontName','Arial','Color','k','FontSize',14);

%% GO THROUGH EACH TRIAL AND PLOT IT SEQUENTIALLY
l = struct;
lh = [];
for iV = 1:numel(VARS)
   l.(VARS{iV}) = line(ax,[nan nan],YLIM,...
      'Color',COL{iV},...
      'LineWidth',2,...
      'LineStyle',LS{iV});
   lh = [lh; l.(VARS{iV})]; %#ok<AGROW>
end

for ii = 1:size(behaviorData,1)
   % Get corresponding trial data from BEHAVIORDATA
   [c,l] = parseBehaviorDataTrial(l,...
                                  behaviorData,...
                                  rate.pars.alignmentEvent,...
                                  ii);
   
   % Plot by color
   plot(ax,rate.pars.t,rate.data(ii,:,iCh),'Color',c);
   
   %% CHANGE CHILD LINE THICKNESS AND REMOVE "OLD" LINES
   h = get(gca,'Children');
   keepVec = true(size(h));
   for iChild = 1:numel(h)
      if isa(h(iChild),'matlab.graphics.primitive.Line')
         keepVec(iChild) = false;
      end
   end
   h = h(keepVec);
   
   if numel(h) > N_LINES_TO_DISPLAY
      delete(h(end));
      h(end) = [];
   end
   
   for iChild = 1:numel(h)
      set(h(iChild),'LineWidth',lw(iChild));
   end
   
   legend(lh,VARS,'Location','north','Orientation','horizontal');
   
   %% UPDATE MOVIE IF DESIRED
   if ~isnan(MOV_NAME)
      I = getframe(gcf);
      writeVideo(v,I);
   elseif nargout==0 % only pause if no movie buffering & no output arg
      pause(PAUSE_DURATION);
   end
end
%% CLOSE MOVIE IF IT EXISTS
if ~isnan(MOV_NAME)
   close(v);
end

%% DELETE FIGURE IF NO OUTPUT ARGUMENTS
if nargout==0
   delete(fig);
end

   % Function to parse color and additional lines from behaviorData
   function [c,l_out] = parseBehaviorDataTrial(l_in,b,a,iTrial)
      c = [b.PelletPresent(iTrial),0,b.Outcome(iTrial)];
      
      k = fieldnames(l_in);
      l_out = l_in;
      for ik = 1:numel(k)
         if ~isinf(b.(k{ik})(iTrial))
            x = b.(k{ik})(iTrial) - b.(a)(iTrial);
            l_out.(k{ik}).XData = [x,x];
         else
            l_out.(k{ik}).XData = [nan,nan];            
         end
      end
      
   end

end