function nnmf_table(N,factorNames,purpose,blocked)
%NNMF_TABLE  Write NNMF table for Tableau export
%
%  write.nnm.nnmf_table(N);
%  write.nnm.nnmf_table(N,factorNames,purpose);
%
%  -- Inputs --
%  N : Output from `[N,C] = analyze.nnm.nnmf_table(T);`
%           -> First analysis uses `analyze.nnm.apply_exclusions(N,C)`; see
%              `exclusions.mat` file for info about number of exclusions,
%              as well as thresholds.
%           -> See figures in `scratchwork/NNMF` regarding summary of NNMF
%              exclusion thresholds and how fit looked etc.
%
%  factorNames : (Optional) Names of each factor. Should be given as cell
%                    array if supplied; must have same number of cell
%                    elements as columns of `N.NNMF`
%
%  purpose : (Optional) If not specified, default is 'full', which is for
%                          the Tableau export.
%                       Options:
%                       -> 'full'
%                       -> {'means','mean','average','averages'} - all same

if nargin < 4
   blocked = true;
end

if nargin < 3
   purpose = 'full';
end

if nargin < 2
   factorNames = defaults.nnmf_analyses('factor_names');
   fprintf(1,'\n\tUsing default factors:\n');
   disp(factorNames);
elseif isempty(factorNames)
   factorNames = defaults.nnmf_analyses('factor_names');
   fprintf(1,'\n\tUsing default factors:\n');
   disp(factorNames);
else % % Otherwise do error-checking on `factorNames` input % %
   if ~iscell(factorNames)
      error('`factorNames` should be supplied as a cell');
   end
   if numel(factorNames) ~= size(N.NNMF,2)
      error('`factorNames` must have same number of elements as columns of `N.NNMF`');
   end
end

% % Remove unwanted variables % %
N.Rate = [];
N.Xc = []; N.Yc = [];
utils.addHelperRepos();

N = movevars(N,'RowID','Before','Group');
N = movevars(N,'NNMF_Key','Before','Group');

switch lower(purpose)
   case 'full'
      if isempty(factorNames)
         N = splitvars(N,'NNMF');
      else
         N = splitvars(N,'NNMF','NewVariableNames',factorNames);
      end
      if blocked
         [tab_path,tab_file] = defaults.files('nnmf_dir','nnmf_tableau_blocked');
      else
         [tab_path,tab_file] = defaults.files('nnmf_dir','nnmf_tableau');
      end
      writetable(N,fullfile(tab_path,tab_file),...
         'FileType','spreadsheet',...
         'WriteVariableNames',true,...
         'WriteRowNames',false,...
         'Sheet','Loadings');
   case {'means','mean','average','averages'}
      if blocked
         [tab_path,tab_file] = defaults.files('nnmf_dir','nnmf_jmp_blocked');
      else
         [tab_path,tab_file] = defaults.files('nnmf_dir','nnmf_jmp');
      end
      [G,TID] = findgroups(N(:,{'Group','AnimalID','Alignment','PostOpDay','Outcome','Area','Channel'}));
      Duration = splitapply(@(c,r)mean(c-r,1),N.Complete,N.Reach,G);
      X = splitapply(@mean,N.X,G);
      Y = splitapply(@mean,N.Y,G);
      NNMF = splitapply(@(X)mean(X,1),N.NNMF,G);
      N_Observations = splitapply(@numel,N.X,G);
      T = [TID, table(Duration,X,Y,N_Observations,NNMF)];
      if isempty(factorNames)
         T = splitvars(T,'NNMF');
      else
         T = splitvars(T,'NNMF','NewVariableNames',factorNames);
      end
      writetable(T,fullfile(tab_path,tab_file),...
         'FileType','spreadsheet',...
         'WriteVariableNames',true,...
         'WriteRowNames',false,...
         'Sheet','Loadings');
   otherwise
      error('\n\t->\t<strong>Unexpected `purpose`</strong>: ''%s''\n');
end
sounds__.play('pop');
end