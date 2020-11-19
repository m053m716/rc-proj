function [E,D,fig] = RsquaredTrends(D,varargin)
%RSQUAREDTRENDS Export figure for trends in R-squared MLS (or Skew)
%
%  [E,D,fig] = make.fig.RsquaredTrends();
%  E = make.fig.RsquaredTrends(D);
%  E = make.fig.RsquaredTrends(D,'Name',value,...);
%
% Inputs
%  D - (Optional) Table exported in `rates_to_jPCA` script
%  varargin - (Optional) 'Name', value input argument pairs, fields of
%                 `pars` (see code below)
%
% Output
%  E - Exported table in association with Rsquared trends.
%  D - If `D` is not given as input, this is first output returned
%  fig - (Optional) If this output is requested, then the figure will not
%        be automatically saved and deleted upon function evaluation.
%
% See also: Contents, rates_to_jPCA

pars = struct;
pars.FigureFile = 'Rsquared-Trends';
pars.File = defaults.files('multi_jpca_long_timescale_matfile');

if nargin > 0
   if ischar(D) || isstring(D)
      varargin = [D, varargin];
      tabInput = false;
   else
      tabInput = true;
   end
else
   tabInput = false;
end

fn = fieldnames(pars);
for iV = 1:2:numel(varargin)
   idx = strcmpi(fn,varargin{iV});
   if sum(idx)==1
      pars.(fn{idx}) = varargin{iV+1};
   end
end

if ~tabInput
   tic;
   fprintf(1,'Please wait, loading <strong>%s</strong>...',pars.File);
   D = getfield(load(pars.File,'D'),'D');
   fprintf(1,'complete (%5.2f sec)\n\n',toc);
end

tic;
fprintf(1,'Formatting table <strong>`E`</strong>...');
[E,fig] = analyze.jPCA.export_table(D,true);
delete(fig(1));
fig = fig(2);
fprintf(1,'complete (%5.2f sec)\n\n',toc);

if nargout > 2
   return;
end

if exist(fullfile(pwd,'figures'),'dir')==0
   mkdir(fullfile(pwd,'figures'));
end

tic;
fprintf(1,'Saving AI file...');
utils.expAI(fig,fullfile(pwd,'figures',[pars.FigureFile '.ai']));
fprintf(1,'figure file...');
savefig(fig,fullfile(pwd,'figures',[pars.FigureFile '.fig']));
fprintf(1,'png file...');
saveas(fig,fullfile(pwd,'figures',[pars.FigureFile '.png']));
fprintf(1,'complete (%5.2f sec)\n\n',toc);
delete(fig);

end