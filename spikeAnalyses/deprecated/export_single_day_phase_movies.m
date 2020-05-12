function export_single_day_phase_movies(J,idx,align,outcome,subset)
%% EXPORT_SINGLE_DAY_PHASE_MOVIES
%
%  EXPORT_SINGLE_DAY_PHASE_MOVIES(J,idx)
%  EXPORT_SINGLE_DAY_PHASE_MOVIES(J,idx,alignment,outcome)
%  EXPORT_SINGLE_DAY_PHASE_MOVIES(J,idx,alignment,outcome,subset)
%
%  --------
%   INPUTS
%  --------
%     J     :     Table from GETPROP method called on GROUP object to get
%                    'Data' property of children BLOCK objects.
%
%    idx    :     Row index to make phase movies for that day.
%                 --> If not specified, loops through all rows of table.
%
%    align  :    (Optional) If not specified, default is 'Grasp'
%                 --> What reach point to align to
%
%   outcome :     (Optional) If not specified, default is 'All'
%
%   subset  :     (Optional) If not specified, uses all subsets ('Full',
%                             'CFA','RFA','Unified')

%% PARSE INPUT
if nargin < 4
   outcome = 'Successful';
end

if nargin < 3
   align = defaults.jPCA('jpca_align');
end

if nargin < 2
   idx = 1:size(J,1);
   for ii = idx
      export_single_day_phase_movies(J,ii,align,outcome);
   end
   return;
elseif isempty(idx)
   idx = 1:size(J,1);
   for ii = idx
      export_single_day_phase_movies(J,ii,align,outcome);
   end
   return;
end

%%
clc;
fprintf(1,'Exporting phase videos for %s...\n',J.Name{idx});
maintic = tic;
out_dir = fullfile(pwd,defaults.jPCA('video_export_base'));

if nargin < 5
   f = fieldnames(J.Data{idx}.(align).(outcome).jPCA);
else
   if ischar(subset)
      f = {subset};
   else
      f = subset;
   end
end
   
for iF = 1:numel(f)
   
   fprintf(1,'-->\t%s channels (%s TRIALS)...\n',f{iF},upper(outcome));
   field_expr = sprintf('Data.%s.%s.analyze.jPCA.%s',align,outcome,f{iF});
   [x,fieldExists] = parseStruct(J.Data{idx},field_expr);
   
   if ~fieldExists
      fprintf(1,'%s: missing %s\n',J.Name{idx},field_expr);
      continue;
   elseif ~isfield(x,'Projection')
      fprintf(1,'%s: invalid field (%s)\n',J.Name{idx},field_expr);
      continue;
   end
   tmp = strsplit(f{iF},'.');
   tmp = strjoin(tmp,filesep);
   vname = sprintf('%s_%s_PostOpDay-%02g',J.Rat{idx},align,J.PostOpDay(idx));
   moviename = fullfile(out_dir,outcome,tmp,J.Group{idx},J.Rat{idx},vname);
   
   movie_params = defaults.jPCA('movie_params',...
      x.Summary.outcomes,...
      J.Score(idx));
   movie_params.moviename = vname;
   
   MV = analyze.jPCA.phaseMovie(...
         x.Projection,...
         x.Summary,...
         movie_params);

   analyze.jPCA.export_jPCA_movie(MV,moviename);

   fprintf(1,'-->\tFinished exporting %s: %s-%s phase video for %s.\n',...
      f{iF},align,outcome,J.Name{idx});
   toc(maintic);
end

end