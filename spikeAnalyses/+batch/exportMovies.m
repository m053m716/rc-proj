function exportMovies(Pa,block_indices,varargin)
%EXPORTMOVIES Batch export movies of rotatory projections and area weights
%
%  batch.exportMovies(Pa);
%  batch.exportMovies(Pa,block_indices);
%  batch.exportMovies(Pa,block_indices,'name',value,...);
%
% Inputs
%  Pa - Projection cell array by area, with 'Weights' field added
%     -> obtained from `analyze.jPCA.recover_channel_weights`
%  block_indices - (Optional) if not specified, exports all blocks.
%                    Otherwise, specify as a vector of block indices
%                    (indices of cell array elements of Pa to export)
%  varargin - (Optional) 'name',value pairs for setting fields of `pars`
%                 parameters struct
%
% Output
%  -- none -- Check in pars parameters struct for the output location of
%              the exported movie files.
%
% See also: make.exportSkullPlotMovie, defaults.ratskull_plot,
%           ratskull_plot

% Parse inputs %
if nargin < 2
   block_indices = 1:numel(Pa);
else
   block_indices = reshape(block_indices,1,numel(block_indices)); % make row
end

% Defaults for `pars` parameters struct %
pars = struct;
pars.pname = 'D:\MATLAB\Data\RC\Spatial-Movie-Exports\Grouped\Ischemia-Exemplars';
pars.max_plane = 3;
pars.mute_sounds = false;
pars.SizeMethod = 'square';

fn = fieldnames(pars);
for iV = 1:2:numel(varargin)
   iField = strcmpi(fn,varargin{iV});
   if sum(iField)==1
      pars.(fn{iField}) = varargin{iV+1};
   end
end

if ~pars.mute_sounds
   utils.addHelperRepos();
end

for iBlock = block_indices
   for iTrial = 1:numel(Pa{iBlock})
      for iPlane = 1:pars.max_plane
         make.exportSkullPlotMovie(Pa{iBlock},...
            'plane',iPlane,'trial',iTrial,...
            'pname',pars.pname,...
            'SizeMethod',pars.SizeMethod);
         if ~pars.mute_sounds
            sounds__.play('pop',1.25,-25);
         end
      end
      if ~pars.mute_sounds
         sounds__.play('pop',1.0,-20);
      end
   end
   if ~pars.mute_sounds
      sounds__.play('pop',0.75,-17);
   end
end
if ~pars.mute_sounds
   sounds__.play('bell',1.0,-15);
end
end