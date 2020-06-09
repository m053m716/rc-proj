function phaseMovie(Projection,Summary,varargin)
%PHASEMOVIE Create movie of animated jPC rotatory trajectories through time
%
% analyze.jPCA.phaseMovie(D);       -> Iterate on all rows of table D
%  -> `D = analyze.jPCA.multi_jPCA(S);`
% analyze.jPCA.phaseMovie(D,index); -> Select row(s) from D
% analyze.jPCA.phaseMovie(Projection,Summary);
% analyze.jPCA.phaseMovie(Projection,Summary,movieParams);
% analyze.jPCA.phaseMovie(Projection,Summary,'parName',parVal,...);
% analyze.jPCA.phaseMovie(__,movieParams,'parName',parVal,...);
%
%  (OLD) To save the movie use:
%  movie2avi(MV, 'movieName', 'FPS', 12, 'compression', 'none');
%  -> Note: `movie2avi` is deprecated as of Matlab R2016b
%  --> Use `analyze.jPCA.export_jPCA_movie(MV,movieName);` instead
%        (uses `VideoWriter` to create video)
%
% Inputs
%  Projection  - Struct array of projections and metadata
%                 -> Returned by `analyze.jPCA.jPCA`
%  Summary     - Summary struct returned
%                 -> Returned by `analyze.jPCA.jPCA`
%  movieParams - Parameters struct with following fields
%       .plane2plot
%        -> Default is 1.  Set to 2 to see the second plane (and so on)
%       .rankType
%        -> Default is 'eig': the first plane is that associated with the
%           largest eigenvalue. Can also be 'varCapt'
%       .times
%        -> Default is Projection(1).times.  Note that you can specify a
%           subset of those times as well.
%       .conds2plot
%        -> Default is 'all'.  Can also be a scalar (to plot a single
%           cond), or a vector of conds (e.g., [1 5 12 27];
%       .substRawPCs
%        -> Substitute raw PCs.
%       .pixelsToGet
%        -> You may wish to customize these, esp. if the defaults don't
%           work well on your screen.  Co-ordinates are left then bottom,
%           then width then height. See getframe for more info.
%       .usePads
%        -> Default is 0.  If '1', stationary pads will be added to start
%           and end of movie.  This can be useful in some media players
%           (though not keynote).
%       .arrowGain
%        -> Controls how much the arrow grows with speed.  Default is 25.
%       .tail
%        -> If specified and not empty, a tail of this length (in ms) will
%           be produced, instead of the whole trajectory.
%
% Output
%  With default parameters, it plays a movie for a plane or a sequence of
%  movies for a sequence of planes, then deletes the figure. If
%  `movieParams.export` is set to true, then as the movie is produced it
%  will sequentially write the movie to disk using Matlab built-in
%  `VideoWriter` object in combination with the `movieParams.filename`
%  parameter (for getting the filename), or else uses default metadata for
%  generating the video name (Rat, Alignment, Day, and which plane it is).
%
%  See Also:   analyze.jPCA.jPCA, analyze.jPCA.multi_jPCA

if isa(Projection,'table')
   if nargin > 1
      if isempty(Summary)
         index = 1:size(Projection,1);
      elseif isstruct(Summary)
         index = 1:size(Projection,1);
         varargin = [Summary, varargin];
      elseif ischar(Summary)
         index = 1:size(Projection,1);
         varargin = [Summary, varargin];
      else
         index = Summary;
      end
   else
      index = 1:size(Projection,1);
   end
   
   if numel(index) > 1
      for ii = 1:numel(index)
         analyze.jPCA.phaseMovie(Projection,index(ii),varargin{:});
      end
      return;
   end
   Summary = Projection.Summary{index};
   Projection = Projection.Projection{index};
end

% Check input arguments
if nargin < 3
   movieParams = defaults.jPCA('movie_params');
else
   if isstruct(varargin{1})
      movieParams = varargin{1};
      varargin(1) = [];
   else
      movieParams = defaults.jPCA('movie_params');
   end
end

% Parse 'Name',value pairs
fn = fieldnames(movieParams);
for iV = 1:2:numel(varargin)
   iField = ismember(lower(fn),lower(varargin{iV}));
   if sum(iField)==1
      movieParams.(fn{iField}) = varargin{iV+1};
   end
end

if numel(movieParams.plane2plot) > 1
   for ii = 1:numel(movieParams.plane2plot)
      mp = movieParams;
      mp.plane2plot = mp.plane2plot(ii);
      analyze.jPCA.phaseMovie(Projection,Summary,mp);
   end
   return;
end

% % % Get metadata specific to this movie % % %
movieParams.Animal = Projection(1).AnimalID;
movieParams.Alignment = Projection(1).Alignment;
movieParams.Day = Projection(1).PostOpDay;

% % Parse which times to plot & interpolate if needed % %
tt = Projection(1).times;
if isempty(movieParams.times)
   times2plot = tt;
else
   times2plot = movieParams.times;
end
% Make sure times are in range of Projection values
times2plot = times2plot((times2plot >= tt(1)) & ...
   (times2plot <= tt(end)));
% If any times still not member of Projection times vector, interpolate
if any(~ismember(times2plot,tt))
   for ii = 1:numel(Projection)
      Projection(ii).proj = interp1(...
         tt,Projection(ii).proj,times2plot,'spline');
      Projection(ii).times = times2plot;
   end
end
% % % % % End time-parsing & interpolation % % % % %

% % If required to remove some offset, do so here % %
if movieParams.zeroStarts
   Projection = analyze.jPCA.zeroCenterPoints(Projection,1); % zero first point
   Summary.crossCondMean = Summary.crossCondMean - ...
      repmat(Summary.crossCondMeanAllTimes(1),...
      size(Summary.crossCondMean,1),1);
   Summary.crossCondMeanAllTimes = Summary.crossCondMeanAllTimes - ...
      repmat(Summary.crossCondMeanAllTimes(1),...
      size(Summary.crossCondMeanAllTimes,1),1);
end

% Print some things out to confirm to the user the choices being made
fprintf('\n<strong>[%s::%s::Day-%02d]</strong>\n',...
   movieParams.Animal,movieParams.Alignment, movieParams.Day);
fprintf(1,'\t->\tPlane-%02d (ordered by %s)\n',  ...
   movieParams.plane2plot, movieParams.rankType);
fprintf(1,...
   '\t\t->\t(Runs from <strong>%dms</strong> to <strong>%dms</strong>)\n',...
   round(times2plot([1,end])));
fprintf(1,'\t\t->\t(Pixels to capture: <strong>[%d %d %d %d]</strong>)\n',...
   movieParams.pixelsToGet);

% % % Begin plotting trajectories % % %
close all force;
movieTag = sprintf('%s - %s - Day-%02d - Plane-%02d',...
   movieParams.Animal,movieParams.Alignment,...
   movieParams.Day,movieParams.plane2plot);

% If we want to export movie, then need to initialize filename & video
% writer object for actually writing the frames to disk file:
if movieParams.export
   % % Set `movieName` (filename) % %
   if isempty(movieParams.filename)
      movieParams.filename = movieTag;
   end
   [p,movie_f,~] = fileparts(movieParams.filename);
   if isempty(p)
      [figDir,movies_folder] = defaults.files(...
         'jpca_fig_folder','jpca_movies_folder');
      p = fullfile(figDir,movies_folder);
   end
   if exist(p,'dir')==0
      mkdir(p);
   end
   movieName = fullfile(p,[movie_f '.avi']);
   
   % % VideoWriter object writes video frames to file % %
   v = VideoWriter(movieName);
   v.FrameRate = movieParams.fs;
   open(v); % Open movie file for writing
end

% Create Figure and Axes %
xl = movieParams.axLim(1:2);
yl = movieParams.axLim(3:4);
xTPos = xl(2) - 0.25 *(xl(2) - xl(1));
yTPos = yl(2) - 0.15 *(yl(2) - yl(1));
xVPos = xl(2) - 0.95 *(xl(2) - xl(1));
yVPos = yl(2) - 0.15 *(yl(2) - yl(1));
xScPos = xl(2) - 0.575 * (xl(2) - xl(1));
yScPos = yl(2) - 0.15 * (yl(2) - yl(1));

if isempty(movieParams.Figure)
   if isempty(movieParams.Axes)
      [movieParams.Figure,movieParams.Axes] = ...
         analyze.jPCA.blankFigure(movieParams.axLim,...
         'Units','Pixels',...
         'Position',movieParams.pixelSize,...
         'Color','k',...
         'Name',movieTag);
   else
      movieParams.Figure = get(movieParams.Axes,'Parent');
   end
end
set(movieParams.Axes,'Color','none');

% start pad (optional) %
if (nargout > 0)  && (movieParams.usePads == 1)
   % pad at start if we are making the  movie to export, rather than just view in matlab
   for i = 1:movieParams.stationaryPadStart
      movieParams.times = [times2plot(1),times2plot(2)];
      movieParams = analyze.jPCA.phaseSpace(...
         Projection,Summary,movieParams);
      drawnow;
      if movieParams.export
         MV = utils.screencapture(movieParams.Figure,...
            movieParams.pixelsToGet);
         writeVideo(v,MV);
      end
   end
end

vc = Summary.varCaptEachPlane(Summary.sortIndices(movieParams.plane2plot));
fontColor = [max(1 - 6*vc,0), max(min(10*vc - 1, 0.75),0), 0.15];
tx_v = sprintf('%02.3g%%',vc*100);
score = sum([Projection.Outcome]==2)/numel(Projection);
tx_sc = sprintf('%02.3g%%',score*100);

% ** ACTUAL MOVIE **
for ti = 3:numel(times2plot)
   tStart = find(times2plot >= (times2plot(ti)-movieParams.tail),1,'first');
   % only times that match one of these will be used
   movieParams.times = times2plot(tStart:ti);
   movieParams = analyze.jPCA.phaseSpace(...
      Projection,Summary,movieParams);
   tx_t = sprintf('%3.2f ms',times2plot(ti));
   if isempty(movieParams.timeIndicator)
      movieParams.timeIndicator = text(...
         movieParams.Axes,xTPos,yTPos, tx_t,...
         'Color','w',...
         'FontSize',movieParams.fontSize,...
         'FontName',movieParams.fontName,...
         'FontWeight',movieParams.fontWeight);
   else
      movieParams.timeIndicator.String = tx_t;
   end
   if isempty(movieParams.titleText_var)
      movieParams.titleText_var = text(...
         movieParams.Axes,xVPos,yVPos, tx_v,...
         'FontSize',movieParams.fontSize,...
         'FontName',movieParams.fontName,...
         'FontWeight',movieParams.fontWeight,...
         'Color',fontColor);
   end
   if isempty(movieParams.titleText_score)
      movieParams.titleText_score = text(...
         movieParams.Axes,xScPos,yScPos, tx_sc,...
         'FontSize',movieParams.fontSize,...
         'FontName',movieParams.fontName,...
         'FontWeight',movieParams.fontWeight,...
         'Color',[0.75 0.75 0.75]);
   end
   drawnow;
   if movieParams.export
      MV = utils.screencapture(movieParams.Figure,...
            movieParams.pixelsToGet);
      writeVideo(v,MV);
   end
end
% end pad
if nargout > 0  && movieParams.usePads == 1
   % pad at start if we are making the  movie to export, rather than just view in matlab
   for i = 1:movieParams.stationaryPadEnd
      movieParams.times = times2plot(1):times2plot(end);
      movieParams = analyze.jPCA.phaseSpace(...
         Projection,Summary,movieParams);
      drawnow;
      if movieParams.export
         MV = utils.screencapture(movieParams.Figure,...
            movieParams.pixelsToGet);
         writeVideo(v,MV);
      end
   end
end

delete(movieParams.Figure); % Remove figure once movie is done.
if movieParams.export
   close(v); % Be sure to close VideoWriter object
   % Notify user that video is finished with Command Window message & sound
   fprintf(1,'Finished writing movie: <strong>%s</strong>\n',movie_f);
   fprintf(1,'\t->\t(<a href="matlab:winopen(''%s'');">Link</a>)\n',movieName);
   utils.addHelperRepos();
   sounds__.play('bell',1.25,-15);
end

end
