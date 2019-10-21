function updated_struct = setStructField(struct_to_set,field_expr,field_data) 
%% SETSTRUCTFIELD    Sets a field of a struct based on input expression
%
%  updated_struct = SETSTRUCTFIELD(struct_to_set,field_expr,field_data);
%
%  e.g. 
%
%  structVar = ...
%     setStructField(structVar,'arbitrary.fieldA.fieldB',fieldB_val);
%     --> This would set structVar.fieldA.fieldB = fieldB_val
%  

%% CHECK INPUT
if ~isstruct(struct_to_set)
   struct_to_set = struct;
end

if nargin < 3
   field_data = {[]};
   if ~iscell(field_expr)
      field_expr = {field_expr};
   end
else
   if iscell(field_expr)
      if ~iscell(field_data)
         error('If passing cell array of input field expressions, field_data must be a cell array with matching elements.');
      elseif numel(field_data) ~= numel(field_expr)
         error('Number of elements of field_data cell array (%g) must equal number of elements of field_expr cell array (%g).',numel(field_data),numel(field_expr));
      end
   else
      field_expr = {field_expr};
   end
end

%%
for ii = 1:numel(field_expr)
   str = strsplit(field_expr{ii},'.');
   output_expr = strjoin([{'struct_to_set'},str(2:end)],'.');
   eval_expr = [output_expr ' = field_data{ii};'];
   eval(eval_expr);
end

%% Assign output
updated_struct = struct_to_set;

end