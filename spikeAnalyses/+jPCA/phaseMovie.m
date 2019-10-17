% For making rosette movies for the paper
% useage:
%
%   phaseMovie(Projection, Summary);    Easiest usage.  Just plot in matlab. Use default params.
%   phaseMovie(Projection, Summary, movieParams);   Can override one or more parameters
%   MV = phaseMovie(Projection, Summary, movieParams);   if you need to save a movie
%
%   To save the movie use: movie2avi(MV, 'movieName', 'FPS', 12, 'compression', 'none');
%
%   'movieParams' can contain the following fields:
%       .plane2plot   Default is 1.  Set to 2 to see the second plane (and so on)
%       .rankType     Default is 'eig': the first plane is that associated with the largest eigenvalue.
%                     Can also be 'varCapt'
%       .times        Default is Projection(1).times.  Note that you can specify a subset of those
%                     times or a superset.  If the latter, only those times that lie within
%                     'allTimes' will be used.
%       .conds2plot   Default is 'all'.  Can also be a scalar (to plot a single cond), or a vector of
%                     conds (e.g., [1 5 12 27];
%       .substRawPCs  Substitute raw PCs.
%       .pixelsToGet  You may wish to customize these, esp. if the defaults don't work well on your
%                     screen.  Co-ordinates are left then bottom, then width then height.
%                     See getframe for more info.
%       .usePads      Default is 0.  If '1', stationary pads will be added to start and end of
%                     movie.  This can be useful in some media players (though not keynote).
%       .arrowGain    Controls how much the arrow grows with speed.  Default is 25;
%       .tail         If specified and not empty, a tail of this length (in ms) will be produced, instead of the whole trajectory.


function MV = phaseMovie(Projection, Summary, movieParams)
%% Set defaults and override if fields are set in 'movieParams'

if nargin < 3
   movieParams = struct;
end

% PLANE
% Plot the first plane (eigenvalue-wise) unless asked to do otherwise
frameParams.planes2plot = 1;
if strcmpi(movieParams.rankType,'varCapt')
   [~,Summary.sortIndices] = sort(Summary.varCaptEachPlane,'descend');
else
   Summary.sortIndices = 1:numel(Summary.varCaptEachPlane);
end

if isfield(movieParams,'plane2plot')
   if numel(movieParams.plane2plot) > 1
      
      MV = cell(numel(movieParams.plane2plot),1);
      for ii = 1:numel(MV)
         mp = movieParams;
         mp.plane2plot = mp.plane2plot(ii);
         MV{ii} = jPCA.phaseMovie(Projection,Summary,mp);
      end
      return;
   else
      frameParams.planes2plot = movieParams.plane2plot;
   end
end

use_orth = false;
if isfield(movieParams,'use_orth')
   use_orth = movieParams.use_orth;
end

% NAME
movieName = '';
if isfield(movieParams,'name')
   movieName = movieParams.name;
end

% FONT
fontSize = 16;
if isfield(movieParams,'fontSize')
   fontSize = movieParams.fontSize;
end

fontWeight = 'bold';
if isfield(movieParams,'fontWeight')
   fontWeight = movieParams.fontWeight;
end

fontName = 'Arial';
if isfield(movieParams,'fontName')
   fontName = movieParams.fontName;
end

% TIMES
times2plot = Projection(1).times;
if isfield(movieParams,'times')
   times2plot = movieParams.times;
   
   if (min(times2plot) < min(Projection(1).times)) || ...
         (max(times2plot) > max(Projection(1).times))
      times2plot = times2plot(ismember(times2plot, Projection(1).allTimes));  % can only plot what we have access to
   else
      X = nan(numel(times2plot),size(Projection(1).proj,2));
      for ii = 1:numel(Projection)
         for ik = 1:size(Projection(ii).proj,2)
            X(:,ik) = interp1(Projection(ii).times,...
               Projection(ii).proj(:,ik),times2plot,'spline');
         end
         Projection(ii).proj = X;
         Projection(ii).times = times2plot;
         Projection(ii).allTimes = times2plot;
         Projection(ii).projAllTimes = X;
      end
   end
end

% START POINT
zeroStarts = false;
if isfield(movieParams,'zeroStarts')
   zeroStarts = movieParams.zeroStarts;
end

% SIZE
pixelSize = [150 150 650 650];
if isfield(movieParams,'pixelSize')
   pixelSize = movieParams.pixelSize;
end

% PIXELS
pixelsToGet = [100 100 500 500];
if isfield(movieParams,'pixelsToGet')
   pixelsToGet = movieParams.pixelsToGet;
end

% Stationary Padding
% Default is we do not add any stationary padding to start or end.  But we will if asked
usePads = false;
if isfield(movieParams,'usePads')
   usePads = movieParams.usePads;
end
% These are used only if the above flag is true
% stationaryPadStart = 18;  % extra frames at the beginning of stationary image.
% stationaryPadEnd = 24;  % extra frames at the end of stationary image.
stationaryPadStart = 4;
stationaryPadEnd = 4;

minAvgDP = 0.5;
if isfield(movieParams,'minAvgDP')
   minAvgDP = movieParams.minAvgDP;
end

% Tail
tail = inf;
if isfield(movieParams,'tail')
   tail = movieParams.tail;
end

lineWidth = 0.5;
if isfield(movieParams,'lineWidth')
   lineWidth = movieParams.lineWidth;
end

arrowSize = 3.3;
if isfield(movieParams,'arrowSize')
   arrowSize = movieParams.arrowSize;
end

planMarkerSize = 0;
if isfield(movieParams,'planMarkerSize')
   if ~isinf(tail)
      planMarkerSize = 0;
   else
      planMarkerSize = movieParams.planMarkerSize;
   end
end

plotPlanEllipse = false;
if isfield(movieParams,'plotPlanEllipse')
   plotPlanEllipse = movieParams.plotPlanEllipse;
end

% These plotting parameters are currently hard coded (can't be changed by movieParams)
% If needed, one can of course
frameParams.arrowSize = arrowSize;  % will likely grow
frameParams.minAvgDP = minAvgDP;
frameParams.planMarkerSize = 0;
frameParams.arrowMinVel = [];
frameParams.arrowGain = 25;  % controls how the arrow grows with speed
frameParams.arrowEdgeColor = 'k';
frameParams.arrowAlpha = 0.275;
frameParams.tailAlpha = 0.35;
frameParams.htmp = [];
frameParams.lineWidth = lineWidth;
frameParams.useAxes = 0;
frameParams.useLabel = 0;
frameParams.plotPlanEllipse = plotPlanEllipse;
frameParams.reusePlot = 0;  % will change to one after first frame
frameParams.rankType = 'eig';  % can also be 'varCapt'
frameParams.arrowEdgeColor = 'k';
frameParams.trials2plot = 'all';
frameParams.substRawPCs = false;
frameParams.crossCondMean = false;
frameParams.conditionLabels = nan;
frameParams.useConditionLabels = false;
frameParams.use_orth = use_orth;

score = nan;
if isfield(movieParams,'score')
   score = movieParams.score;
end

fNames = fieldnames(frameParams);
for ii = 1:numel(fNames)
   if isfield(movieParams,fNames{ii})
      frameParams.(fNames{ii}) = movieParams.(fNames{ii});
   end
end


%% Done handling parameters and defaults
% Print some things out to confirm to the user the choices being made
fprintf('using plane %d (ordered by %s)\n',  frameParams.planes2plot, frameParams.rankType);
fprintf('movie runs from time %dms to %dms\n',  round(times2plot([1,end])));
fprintf('pixels: [%d %d %d %d]\n',  pixelsToGet);


%% Now start plotting stuff

fi = 1;  % frame index

close all force;

if zeroStarts
   Projection = jPCA.zeroCenterPoints(Projection,1); % zero first point
   Summary.crossCondMean = Summary.crossCondMean - ...
      repmat(Summary.crossCondMeanAllTimes(1),size(Summary.crossCondMean,1),1);
   Summary.crossCondMeanAllTimes = Summary.crossCondMeanAllTimes - ...
      repmat(Summary.crossCondMeanAllTimes(1),size(Summary.crossCondMeanAllTimes,1),1);
end


%% start pad
if (nargout > 0)  || (usePads == 1)
   % pad at start if we are making the  movie to export, rather than just view in matlab
   
   for i = 1:stationaryPadStart
      %       frameParams.times = times2plot(1):times2plot(2);
      frameParams.times = [times2plot(1),times2plot(2)];
      
      jPCA.phaseSpace(Projection, Summary, frameParams);
      drawnow;
      set(gcf,'Position',pixelSize);
      set(gcf,'NumberTitle','off');
      set(gcf,'MenuBar','none');
      set(gcf,'ToolBar','none');
      set(gcf,'Color','k');
      set(gcf,'Name',movieName(1:(end-4)));
      set(gca,'Color','k');
      frameParams.reusePlot = 1;  % after the first frame, always reuse
      
      if nargout > 0
         MV(:,:,:,fi) = screencapture(gca); %#ok<*AGROW>
%          MV(:,:,:,fi) = screencapture(gcf,pixelsToGet); %#ok<*AGROW>
%          try
%             MV(fi) = getframe(gca, pixelsToGet);
%          catch
%             MV(fi) = getframe(gcf);
%          end
         fi=fi+1;
      end
   end
end
if use_orth
   vc = Summary.varCaptEachPlane_orth(Summary.sortIndices(frameParams.planes2plot));
else
   vc = Summary.varCaptEachPlane(Summary.sortIndices(frameParams.planes2plot));
end
fontColor = [max(1 - 6*vc,0), max(min(10*vc - 1, 0.75),0), 0.15];

tx_v = sprintf('%02.3g%%',vc*100);
tx_sc = sprintf('%02.3g%%',score*100);

%% ** ACTUAL MOVIE **
dTimes = mode(diff(times2plot));
for ti = 3:length(times2plot)
   tStart = find(times2plot < (times2plot(ti)-tail),1,'last');
   if isempty(tStart)
      tStart = 1;
   end
   frameParams.times = times2plot(tStart:ti);  % only times that match one of these will be used
   
   jPCA.phaseSpace(Projection, Summary, frameParams);
   drawnow;
   set(gca,'Color','k');
   
   frameParams.reusePlot = 1;  % after the first frame, always reuse
   if ti==3
      xl = get(gca,'XLim');
      yl = get(gca,'YLim');
      xTPos = xl(2) - 0.25 *(xl(2) - xl(1));
      yTPos = yl(2) - 0.15 *(yl(2) - yl(1));
      xVPos = xl(2) - 0.95 *(xl(2) - xl(1));
      yVPos = yl(2) - 0.15 *(yl(2) - yl(1));
      xScPos = xl(2) - 0.575 * (xl(2) - xl(1));
      yScPos = yl(2) - 0.15 * (yl(2) - yl(1));
      
      set(gcf,'Position',pixelSize);
      set(gcf,'NumberTitle','off');
      set(gcf,'MenuBar','none');
      set(gcf,'ToolBar','none');
      set(gcf,'Color','k');
      set(gcf,'Name',movieName(1:(end-4)));
   end
   tx_t = sprintf('%g ms',round(times2plot(ti)));
   
   text(gca,xTPos,yTPos, tx_t,...
      'Color','w',...
      'FontSize',fontSize,...
      'FontName',fontName,...
      'FontWeight',fontWeight);
   
   text(gca,xVPos,yVPos, tx_v,...
      'FontSize',fontSize,...
      'FontName',fontName,...
      'FontWeight',fontWeight,...
      'Color',fontColor);
   
   text(gca,xScPos,yScPos, tx_sc,...
      'FontSize',fontSize,...
      'FontName',fontName,...
      'FontWeight',fontWeight,...
      'Color',[0.75 0.75 0.75]);
   
   if nargout > 0
      MV(:,:,:,fi) = screencapture(gca);
%       MV(:,:,:,fi) = screencapture(gcf, pixelsToGet);
%       try
%          MV(fi) = getframe(gca, pixelsToGet);
%       catch
%          MV(fi) = getframe(gcf);
%       end
      fi=fi+1;
   end
end

%% end pad
if nargout > 0  && usePads == 1
   % pad at start if we are making the  movie to export, rather than just view in matlab
   for i = 1:stationaryPadEnd
      frameParams.times = times2plot(1):times2plot(end);
      
      jPCA.phaseSpace(Projection, Summary, frameParams);
      drawnow;
      set(gcf,'Position',pixelSize);
      set(gcf,'NumberTitle','off');
      set(gcf,'MenuBar','none');
      set(gcf,'ToolBar','none');
      set(gcf,'Color','k');
      set(gcf,'Name',movieName(1:(end-4)));
      set(gca,'Color','k');
      frameParams.reusePlot = 1;  % after the first frame, always reuse
      
      if nargout > 0
         MV(:,:,:,fi) = screencapture(gca);
%          MV(:,:,:,fi) = screencapture(gcf,pixelsToGet);
%          try
%             MV(fi) = getframe(gca, pixelsToGet);
%          catch
%             MV(fi) = getframe(gcf);
%          end
         fi=fi+1;
      end
   end
end


if ~exist('MV', 'var')  % if we were not asked to make the movie structure
   MV = [];
end

delete(gcf); % Remove figure once movie is done.

