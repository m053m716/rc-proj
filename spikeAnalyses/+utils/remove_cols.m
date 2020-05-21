function T = remove_cols(T,varargin)
%REMOVE_COLS  Simple function checks for a variable column & removes it
%
%  T = utils.remove_cols(T,'col_name_1','col_name_2',...,'col_name_k');
%
%  Note: the main thing is that if the variable doesn't exist, this won't
%        remove it (in case a particular processing step has not yet added
%        that variable to a table from one pipeline, which would otherwise
%        be an unwanted variable for some other pipeline, for example).

if numel(varargin) > 1
   for iV = 1:numel(varargin)
      T = utils.remove_cols(T,varargin{iV});
   end
   return;
elseif isempty(varargin)
   return;
end
v = varargin{:};
if ismember(v,T.Properties.VariableNames)
   T.(v) = [];
end

end