function export_jPCA_movie(MV,movieName,varargin)
%EXPORT_JPCA_MOVIE  Save movie created by analyze.jPCA.phaseMovie to disk
%
%  (deprecated) -- functionality offloaded to `analyze.jPCA.phaseMovie`
%
% analyze.jPCA.export_jPCA_movie(MV);
% analyze.jPCA.export_jPCA_movie(MV,movieName);
% analyze.jPCA.export_jPCA_movie(MV,movieName,);
%
% Inputs
%  MV        -     4d uint8 created by analyze.jPCA.phaseMovie
%  movieName -    (String) name of movie file
%                    -> If not supplied (or given as empty vector), default
%                       is `jPCA_movie.avi`
%  varargin  -    (Optional) <'paramName',value> input argument pairs
%                    -> First `varargin` can also be struct of movieParams
%                       as returned by `defaults.jPCA('movie_params');`
% Output
%  Creates a movie file, whose name is specified by `moviename` input arg
%  Otherwise, it defaults to 'jPCA_movie.avi'

% Check input arguments
if nargin < 3
   if nargin == 2
      if isstruct(movieName)
         movieParams = movieName;
         movieName = movieParams.defaultName;
      else
         movieParams = defaults.jPCA('movie_params');
      end
   else
      movieParams = defaults.jPCA('movie_params');
   end
end

if nargin < 2
   movieName = movieParams.defaultName;
end

% Parse 'Name',value pairs
fn = fieldnames(movieParams);
for iV = 1:2:numel(varargin)
   iField = ismember(lower(fn),lower(varargin{iV}));
   if sum(iField)==1
      movieParams.(fn{iField}) = varargin{iV+1};
   end
end

% DEFAULTS
if iscell(MV)
   if numel(MV)~=numel(movieName)
      [pname,fname,ext] = fileparts(movieName);
      if isempty(ext)
         ext = '.MP4';
      end
      for ii = 1:numel(MV)
         movieName = fullfile(pname,...
            sprintf('%s_jPCA-Plane-%02d%s',fname,ii,ext));
         analyze.jPCA.export_jPCA_movie(MV{ii},movieName,'FS',FS);
      end
   else
      for ii = 1:numel(MV)
         [pname,fname,ext]= fileparts(movieName{ii});
         analyze.jPCA.export_jPCA_movie(MV{ii},...
            fullfile(pname,sprintf('%s_jPCA-Plane-%02d%s',fname,ii,ext)));
      end
   end
   return;
end

% % Do actual video export % %
v = VideoWriter(movieName);
v.FrameRate = FS;
open(v); % Open movie file for writing
for ii = 1:size(MV,4)
   writeVideo(v,MV(:,:,:,ii));
end
close(v); % Be sure to close it

% Notify user that video is finished with Command Window message & sound
fprintf(1,'Finished writing movie: %s.\n',movieName);
utils.addHelperRepos();
sounds__.play('bell',1.25,-15);

end