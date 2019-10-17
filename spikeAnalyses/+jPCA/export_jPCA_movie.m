function export_jPCA_movie(MV,moviename,varargin)
%% EXPORT_JPCA_MOVIE    Export movie created by PHASEMOVIE
%
%  EXPORT_JPCA_MOVIE(MV)
%
%  --------
%   INPUTS
%  --------
%     MV    :     4d uint8 created by JPCA.PHASEMOVIE
%
%  moviename :    (String) name of movie file.
%
%  varargin  :    (Optional) 'NAME', value input argument pairs.
%
%  --------
%   OUTPUT
%  --------
%  Creates a movie file, whose name is specified by moviename.
%  Otherwise, it defaults to 'jPCA_movie.avi'.
%
% By: Max Murphy  v1.0  03/03/2018

%% DEFAULTS
MOVIENAME = 'jPCA_movie.avi';
FS = 30;

%% PARSE INPUT
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end
jpca_start_stop_times = defaults.jPCA('jpca_start_stop_times');
lpf_fc = defaults.block('lpf_fc');
fc = defaults.jPCA('fc');
if iscell(MV)
   if numel(MV)~=numel(moviename)
      if iscell(moviename)
         disp('Mismatch dim between MV and moviename. Basing name from first element of moviename cell array.');
         moviename = moviename{1};
      end
      [pname,fname,ext] = fileparts(moviename);
      if isempty(ext)
         ext = '.MP4';
      end
      for ii = 1:numel(MV)
         moviename = fullfile(pname,sprintf('%s_jPCA-Plane-%g_%gms_to_%gms_%gHzFcRate_%gHzjPCA%s',...
            fname,ii,jpca_start_stop_times(1),jpca_start_stop_times(2),lpf_fc,fc,ext));
         jPCA.export_jPCA_movie(MV{ii},moviename,'FS',FS);
      end
   else
      for ii = 1:numel(MV)
         [pname,fname,ext]= fileparts(moviename{ii});
         jPCA.export_jPCA_movie(MV{ii},...
            fullfile(pname,sprintf('%s_jPCA-Plane-%g_%gms_to_%gms_%gHzFcRate_%gHzjPCA%s',...
            fname,ii,jpca_start_stop_times(1),...
            jpca_start_stop_times(2),lpf_fc,fc,ext)),'FS',FS);
      end
   end
   
   return;
end

if exist('moviename','var')==0
   moviename = MOVIENAME;
else
   if isempty(moviename)
      moviename = MOVIENAME;
   else
      [pname,fname,ext] = fileparts(moviename);
      
      if ~contains(fname,'_jPCA-Plane-')
         fname = sprintf('%s_jPCA-Plane-1_%gms_to_%gms_%gHzFcRate_%gHzjPCA',...
            fname,jpca_start_stop_times(1),jpca_start_stop_times(2),lpf_fc,fc);
      end
      if isempty(ext)
         moviename = fullfile(pname,[fname '.MP4']);
      else
         moviename = fullfile(pname,[fname ext]);
      end
      if exist(pname,'dir')==0
         mkdir(pname);
      end
   end
end

%% MAKE VIDEOWRITER AND EXPORT VIDEO
v = VideoWriter(moviename);
v.FrameRate = FS;
open(v); % Open movie file for writing
for ii = 1:size(MV,4)
%    writeVideo(v,MV(ii).cdata);
   writeVideo(v,MV(:,:,:,ii));
end
fprintf(1,'Finished writing movie: %s.\n',moviename);
close(v); % Be sure to close it

end