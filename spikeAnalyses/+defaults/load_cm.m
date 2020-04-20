function [cm,nColorOpts] = load_cm(name)
%DEFAULTS.LOAD_CM  Loads a colormap
%
%  cm = DEFAULTS.LOAD_CM; % Load 'hotcold' default colormap
%  cm = DEFAULTS.LODA_CM('test'); % Load contents of 'testmap.mat' if it
%                                      exists, otherwise 'hotcold'

[cmap_path_local,cmap_path_remote] = defaults.files('local_tank','tank');

if nargin < 1
   in = load(fullfile(cmap_path_local,'hotcoldmap.mat'),'cm');
else
   [p,f,e] = fileparts(name);
   if ~isempty(p)
      if isempty(e)
         if contains(f,'map')
            e = '.mat';
         else
            e = 'map.mat';
         end
      end
      fname = fullfile(p,[f e]);
      if exist(fname,'file')==0
         fname = fullfile(cmap_path_local,[f e]);
         if exist(fname,'file')==0
            fname = fullfile(cmap_path_remote,[f e]);
            if exist(fname,'file')==0
               error('Bad filename: %s\n',fullfile(p,[f e]));
            else
               in = load(fname);
            end
         else
            in = load(fname);
         end
      end
   else
      if isempty(e)
         if contains(f,'map')
            e = '.mat';
         else
            e = 'map.mat';
         end
      end
      fname = fullfile(cmap_path_local,[f e]);
      if exist(fname,'file')==0
         fname = fullfile(cmap_path_remote,[f e]);
         if exist(fname,'file') == 0
            error('Bad filename: %s',name);
         end
         in = load(fname);
      else 
         in = load(fname);
      end
   end
end

if ~isfield(in,'cm')
   varFields = fieldnames(in);
   if numel(varFields) == 1
      cm = in.(varFields{1});
   else
      error('Ambiguous file: multiple variables and none named `cm`');
   end
else
   cm = in.cm;
end

nColorOpts = 31; % Set this to be at least as large as max. post-op day in any rat

end