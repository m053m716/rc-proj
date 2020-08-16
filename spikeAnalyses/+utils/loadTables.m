function varargout = loadTables(dataset)
%LOADTABLES    Load tables for a given dataset
%
%  varargout = utils.loadTables(dataset);
%
% Examples
%  R = utils.loadTables(); 
%     -> By default, loads "Raw spike counts" table (depends on setting in
%        defaults.files('default_tables_to_load');
%  
%  R = utils.loadTables('counts');
%     -> Raw spike counts (60-ms bins)
%
%  E = utils.loadTables('dynamics');
%     -> Only attempts to load `E` table (not both; faster)
%
%  [E,D] = utils.loadTables('dynamics');
%     -> Tables related to population dynamics statistics
%
%  D = utils.loadTables('multi_jpca');
%     -> Only loads export from multi-jPCA (see script rates_to_jPCA)
%
%  r = utils.loadTables('rate');
%     -> Subset of `R` that is relevant to channel rate statistics.
%
%  [r,glme_pre,glme_grasp,glme_reach,glme_retract]
%     utils.loadTables('rate');
%     -> Loads associated generalized linear mixed effects models.
%
% Inputs
%  dataset - 'counts' (default) | 'dynamics' | 'rate'
%
% See also: defaults.files

if nargout < 1
   varargout = {};
   fprintf(1,'No outputs specified; <strong>no data loaded</strong>.\n');
   return;
end

if nargin < 1
   dataset = defaults.files('default_tables_to_load');
end

varargout = cell(1,nargout);
thisTic = tic;

if contains(lower(dataset),'count')   
   fprintf(1,'Loading binned 60-ms raw spike counts...');
   varargout{1} = getfield(load(defaults.files('raw_rates_table_file'),'R'),'R');
elseif contains(lower(dataset),'multi')
   fprintf(1,'Loading multi-jPCA table...');
   varargout{1} = getfield(load(defaults.files('multi_jpca_long_timescale_matfile'),'D'),'D');
elseif contains(lower(dataset),'dynamic')
   fprintf(1,'Loading table of exported dynamics fits by day and plane...');
   varargout{1} = getfield(load(defaults.files('exported_jpca_matfile'),'E'),'E');
   if nargout > 1
      thisToc = toc(thisTic);
      n_minutes = floor(thisToc/60);
      n_seconds = thisToc - (n_minutes*60);
      fprintf(1,'<strong>complete</strong> (%5.2f minutes, %4.1f sec)\n',...
         n_minutes,n_seconds);
      thisTic = tic;
      fprintf(1,'Loading multi-jPCA table...');
      varargout{2} = getfield(load(defaults.files('multi_jpca_long_timescale_matfile'),'D'),'D');
   end
elseif contains(lower(dataset),'rate')
   fprintf(1,'Loading table of included spike count subset trials...');
   if nargout == 1
      varargout{1} = getfield(load(defaults.files('learning_rates_table_file'),'r'),'r');
   else
      in = load(defaults.files('learning_rates_table_file'));
      ord = {'r','glme_pre','glme_grasp','glme_reach','glme_retract'};
      for iOut = 1:nargout
         varargout{iOut} = in.(ord{iOut});
      end
   end
else
   error('Unrecognized dataset: <strong>%s</strong>\n',dataset);
end
thisToc = toc(thisTic);
n_minutes = floor(thisToc/60);
n_seconds = thisToc - (n_minutes*60);
fprintf(1,'<strong>complete</strong> (%5.2f minutes, %4.1f sec)\n',...
   n_minutes,n_seconds);

end