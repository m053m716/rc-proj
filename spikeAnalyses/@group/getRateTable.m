function T = getRateTable(obj,align,includeStruct,area,autoSave,doSmooth)
%GETRATETABLE  Returns table of per-trial rate trajectories
%
%  T = getRateTable(obj);
%  * Note: Default behavior is to construct FULL table of
%     alignments. Specify optional arguments in case you want to
%     save space or speed up pulling a subset of the table.
%
%  T = getRateTable(obj,align,includeStruct,area,autoSave,doSmooth);
%  -> `align`, `includeStruct`, or `area` can be set as an empty double []
%        in order to skip that argument and use defaults, while still
%        specifying one of the later arguments.
%
%  -- Inputs --
%  obj : `rat` class object
%
%  align :  'Reach','Grasp','Complete','Support' or cell
%           combination of some of those options
%  -> Default is {'Reach','Grasp'}
%
%  includeStruct: see: `utils.makeIncludeStruct`
%  -> Default (if not specified) is
%     {utils.makeIncludeStruct({'Reach','Grasp','Complete','Outcome'},[]);
%      utils.makeIncludeStruct({'Reach','Grasp','Complete'},{'Outcome'})}
%
%  area : 'RFA', 'CFA', or {'RFA','CFA'} (which areas to pull)
%  -> Default is {'RFA','CFA'} (pulls channels from both areas)
%
%  autoSave : Default is false. Specify as true to automatically
%              save the aggregated data table to a matfile prior
%              to returning the table to calling workspace.
%
%  doSmooth : Default is false. Specify as true to force return
%              smoothed dataset.

utils.addHelperRepos(); % Make sure "Utility" repo is present
if nargin < 6
   doSmooth = false;
end

if nargin < 5
   autoSave = false;
end

if nargin < 4
   area = {'RFA','CFA'};
elseif islogical(area) && (nargin < 5)
   autoSave = area;
   area = {'RFA','CFA'};
elseif islogical(area) && (nargin >= 5)
   tmpSave = area;
   if ischar(autoSave)
      area = {autoSave};
   elseif iscell(autoSave)
      area = autoSave;
   else
      error(['RC:' mfilename ':BadInputType'],...
         ['\n\t->\t<strong>[GROUP.GETRATETABLE]:</strong> ' ...
         'Unexpected input class: %s; check inputs\n'...
         '\t\t\t(Could be problem with `area` input)\n'],...
         class(autoSave));
   end
   autoSave = tmpSave;
elseif isempty(area)
   area = {'RFA','CFA'};
elseif ~iscell(area)
   area = {area};
end

if nargin < 3
   includeStruct = defaults.experiment('rate_table_includes');
elseif isempty(includeStruct)
   includeStruct = defaults.experiment('rate_table_includes');
elseif ~iscell(includeStruct)
   includeStruct = {includeStruct};
end

if nargin < 2
   align = defaults.experiment('event_opts');
elseif isempty(align)
   align = defaults.experiment('event_opts');
elseif ~iscell(align)
   align = {align};
end

if numel(obj) > 1
   T = table.empty;
   for i = 1:numel(obj)
      T = [T; getRateTable(obj(i),align,includeStruct,area,autoSave,doSmooth)]; %#ok<*AGROW>
   end
   
   fprintf(1,'\n--\t--\t--\n');
   fprintf(1,'<strong>Table aggregation complete</strong>');
   fprintf(1,'\n--\t--\t--\n');
   
   T.ChannelID = categorical(T.ChannelID);
   T.ProbeID = categorical(T.ProbeID);
   T.BlockID = categorical(T.BlockID);
   [f_rows,f_tab,f_def] = defaults.files('table_rows_file',...
      'rate_tableau_table_matfile','default_rowmeta_matfile');
   
   if (exist(f_rows,'file')~=0)
      if autoSave
         fprintf(1,'\t->\tFound RowNames file: ');
         fprintf(1,'<strong>%s</strong>...overwriting...\n',f_rows);
         group.save_table_row_names(T.Properties.RowNames,f_rows);

         fprintf(1,'\t->\tAuto-saving Table: ');
         fprintf(1,'<strong>%s</strong>...overwriting...',f_tab);
         save(f_tab,'T','-v7.3');
         fprintf(1,'complete\n');
         
         fprintf(1,'Auto-saving "RowMeta" table...');
         metaVars = defaults.experiment('meta_vars');
         RowMeta = T(:,metaVars);
         save(f_def,'RowMeta','-v7.3');
		 fprintf(1,'complete\n');
      else
         fprintf(1,'\t->\tFound RowNames file: ');
         fprintf(1,'<strong>%s</strong>...loading...',f_rows);
         in = load(f_rows,'RowNames');
         fprintf(1,'complete\n');
         if size(in.RowNames,1)==size(T,1)
            T.Properties.RowNames = in.RowNames;
         else
            fprintf(1,...
               '\t\t->\t<strong>Size mismatch (keeping new names)</strong>\n');
         end
      end
   else
      if autoSave
         group.save_table_row_names(T.Properties.RowNames,f_rows);
         fprintf(1,'\t->\tAuto-saving Table: ');
         fprintf(1,'<strong>%s</strong>...overwriting...',f_tab);
         save(f_tab,'T','-v7.3');
         fprintf(1,'complete\n');
         fprintf(1,'Auto-saving "RowMeta" table...');
         metaVars = defaults.experiment('meta_vars');
         RowMeta = T(:,metaVars);
         save(f_def,'RowMeta','-v7.3');
		 fprintf(1,'complete\n');
      end
   end
   sounds__.play('bell',1.25);
   return;
end

T = getRateTable(obj.Children,align,includeStruct,area);
% T = T(any(T.Rate,2),:); % Remove rows where rate is "zero"
Group = repmat(...
   categorical({obj.Name},defaults.experiment('group_names')),...
   size(T,1),1);
T = [table(Group), T];

% Set "binary" categorical to labels so they're clear on sheet
T.PelletPresent = categorical(T.PelletPresent,...
   [0,1],{'Missing','Present'});
T.Outcome = categorical(T.Outcome,...
   [0,1],{'Successful','Unsuccessful'});

% Update description and names of rows
T.Properties.Description = ...
   'Table of normalized rate time-series for each trial';
utils.mtb(T);
T.Properties.RowNames = tag__.makeKey(size(T,1),'unique','ROWID_');

% Associate properties for Transformed rate etc. on UserData
[rate_smooth_fcn,pca_exclusion_fcn,group_var_indices] = ...
   defaults.experiment(...
   'rate_smoothing_fcn',...
   'pca_exclusion_fcn',...
   'pca_group_var_indices');
T.Properties.UserData.IsTransformed = false;
T.Properties.UserData.Transform = rate_smooth_fcn;
if doSmooth
   T = applyTransform(T);
end

% Save RowNames as variable, as well
T.RowID = T.Properties.RowNames;
T = T(:,[end, 1:(end-1)]);

% Save other extraction metadata as UserData
T.Properties.UserData.GroupVarIndices = group_var_indices;
T.Properties.UserData.PCA_Exclude_Fcn = pca_exclusion_fcn;

end