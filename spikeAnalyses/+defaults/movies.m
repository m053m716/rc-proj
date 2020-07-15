function varargout = movies(varargin)
%MOVIES Return parameters associated with movie exports
%
%  varargout = defaults.movies(varargin);
%
%  Examples:
%  par = defaults.movies('par_name');
%  [par_1,...,par_k] = defaults.movies('name_p1',...,'name_pk'); 
%
%  # Parameters (`name` values) #
%  -> 'batch_skull'  - Struct containing parameters for batch skull movie export
%  -> 'single_skull' - Struct containing parameters for single skull movie export
%
% See also: batch.exportMovies, make.exportSkullPlotMovie

% % % Create struct with default parameters % % %
p = struct;
pname = local.defaults('LocalDataTank');
all_movie_files_loc = fullfile(pname,'Spatial-Movie-Exports');

% % See: batch.exportMovies % %
p.batch_skull = struct;
p.batch_skull.max_plane = 3;
p.batch_skull.mute_sounds = false;
p.batch_skull.pname = fullfile(all_movie_files_loc,'Grouped');
p.batch_skull.sub_folder = '';
p.batch_skull.ProjectFcn = ...
   @(D)analyze.jPCA.recover_channel_weights(D,'groupings','Area');
p.batch_skull.SizeMethod = 'square';
p.batch_skull.tag = '';


% % See: make.exportSkullPlotMovie % %
p.single_skull = struct;
p.single_skull.plane = nan;
p.single_skull.trial = nan;
p.single_skull.subtract_xc_mean = true;
p.single_skull.pname = all_movie_files_loc;
p.single_skull.sub_folder = '';
p.single_skull.expr = '%s_Plane-%02d_%s%s';
p.single_skull.tag = '';
p.single_skull.profile = 'MPEG-4'; % 'Motion JPEG AVI' (default) | 'MPEG-4' | 'Grayscale AVI'

p.single_skull.ColorMap = 'cool';
p.single_skull.EventPauseDuration = 1.5; % (seconds); how long to "pause" on events
p.single_skull.FontParams = ...
   {'FontName','Arial','FontWeight','bold','Color','w'};
p.single_skull.FrameRate = 60;
p.single_skull.GroupColors = ...
   [             ...
    1.0 0.0 0.0; ... % index 1 (positive value): blue
    0.0 0.0 1.0; ... % index 2 (negative value): red
    0.4 0.4 0.4  ... % index 3 (rectified magnitude): grey
    ];    
p.single_skull.InitSize = 30;
p.single_skull.Position = [0.2 0.2 0.3 0.5];
p.single_skull.ProjType = 'jPC'; % 
p.single_skull.ProjField = 'proj';
p.single_skull.SizeMethod = 'square';
p.single_skull.SortBy = 'eig'; % 'eig' | 'varcapt'
p.single_skull.TimeFontSize = 24;
p.single_skull.TimeTextUpdateIncrement = 10; % (ms)
p.single_skull.TrajParams = defaults.jPCA('movie_params');
p.single_skull.TrajParams.min_trials = 0;
p.single_skull.TrajParams.tail = 100; % (ms)
p.single_skull.Units = 'Normalized';

% % % Display defaults (if no input or output supplied) % % %
if (nargin == 0) && (nargout == 0)
   disp(p);
   return;
end

% % % Parse output % % %
if nargin < 1
   varargout = {p};   
else
   F = fieldnames(p);   
   if (nargout == 1) && (numel(varargin) > 1)
      varargout{1} = struct;
      for iV = 1:numel(varargin)
         idx = strcmpi(F,varargin{iV});
         if sum(idx)==1
            varargout{1}.(F{idx}) = p.(F{idx});
         end
      end
   elseif nargout > 0
      varargout = cell(1,nargout);
      for iV = 1:nargout
         idx = strcmpi(F,varargin{iV});
         if sum(idx)==1
            varargout{iV} = p.(F{idx});
         end
      end
   else
      for iV = 1:nargin
         idx = strcmpi(F,varargin{iV});
         if sum(idx) == 1
            fprintf('<strong>%s</strong>:',F{idx});
            disp(p.(F{idx}));
         end
      end
   end
end
end