function pca_table(P,factorNames,purpose)
%PCA_TABLE  Write PCA table for Tableau or JMP export
%
%  write.pc.pca_table(P);
%  write.pc.pca_table(P,factorNames,purpose);
%
%  -- Inputs --
%  P : Output from `[P,C] = analyze.pc.pca_table(T);`
%
%  factorNames : (Optional) Names of each factor. Should be given as cell
%                    array if supplied; must have same number of cell
%                    elements as columns of `P.PC_Score`
%
%  purpose : (Optional) If not specified, default is 'full', which is for
%                          the Tableau export.
%                       Options:
%                       -> {'full','tableau'}
%                       -> {'means','mean','average','averages','jmp'} - all same

if nargin < 3
   purpose = 'full';
end

if nargin < 2
   factorNames = defaults.pca_analyses('factor_names');
   fprintf(1,'\n\tUsing default factors:\n');
   disp(factorNames);
elseif isempty(factorNames)
   factorNames = defaults.pca_analyses('factor_names');
   fprintf(1,'\n\tUsing default factors:\n');
   disp(factorNames);
else % % Otherwise do error-checking on `factorNames` input % %
   if ~iscell(factorNames)
      error('`factorNames` should be supplied as a cell');
   end
   if numel(factorNames) ~= size(P.PC_Score,2)
      error('`factorNames` must have same number of elements as columns of `N.NNMF`');
   end
end

% % Remove unwanted variables % %
utils.addHelperRepos();
switch lower(purpose)
   case {'full','tableau'}
      if isempty(factorNames)
         P = splitvars(P,'PC_Score');
      else
         P = splitvars(P,'PC_Score','NewVariableNames',factorNames);
      end

      [tab_path,tab_file] = defaults.files('pca_dir','pca_tableau');

      writetable(P,fullfile(tab_path,tab_file),...
         'FileType','spreadsheet',...
         'WriteVariableNames',true,...
         'WriteRowNames',false,...
         'Sheet','Loadings');
   case {'means','mean','average','averages','jmp'}

      [tab_path,tab_file] = defaults.files('pca_dir','pca_jmp');

      [G,TID] = findgroups(P(:,{'Group','AnimalID','Alignment','PostOpDay','Outcome','Area','Channel'}));
      Duration = splitapply(@(c,r)mean(c-r,1),P.Complete,P.Reach,G);
      X = splitapply(@mean,P.X,G);
      Y = splitapply(@mean,P.Y,G);
      PC_Score = splitapply(@(X)mean(X,1),P.PC_Score,G);
      N_Observations = splitapply(@numel,P.X,G);
      T = [TID, table(Duration,X,Y,N_Observations,PC_Score)];
      if isempty(factorNames)
         T = splitvars(T,'PC_Score');
      else
         T = splitvars(T,'PC_Score','NewVariableNames',factorNames);
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