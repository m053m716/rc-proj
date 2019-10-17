function [cm,nColorOpts] = load_cm(name)
%% DEFAULTS.LOAD_CM  Loads a colormap
%
%  cm = DEFAULTS.LOAD_CM; % Load 'hotcold' default colormap
%  cm = DEFAULTS.LODA_CM('test'); % Load contents of 'testmap.mat' if it
%                                      exists, otherwise 'hotcold'
%
% By: Max Murphy  v1.0  2019-06-06  Original version (R2017a)

%%
if nargin < 1
   name = 'hotcold';
else
   fname = sprintf('%smap.mat',name);
   if exist(fname,'file')==0
      fprintf(1,'%s does not exist. Loading hotcoldmap.mat instead.\n',fname);
      name = 'hotcold';
   end
end

fname = sprintf('%smap.mat',name);
in = load(fname);
if ~isfield(in,'cm')
   error('No ''cm'' variable in %s. Is it a valid colormap file?',fname);
else
   cm = in.cm;
end

nColorOpts = 31; % Set this to be at least as large as max. post-op day in any rat

end