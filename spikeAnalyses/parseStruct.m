function [field_out,field_exists_flag,field_isempty_flag] = parseStruct(struct_in,field_expr)
%% PARSESTRUCT    Parse struct based on expression in field_expr (e.g. 'structname.field1.field2')
%
%  [field_out,field_exists_flag,field_isempty_flag] = PARSESTRUCT(struct_in,field_expr);
%
%  --------
%   INPUTS
%  --------
%  struct_in      :     Full struct to parse fields
%
%  field_expr     :     Char array in format ('structname.field1.field2')
%
%  --------
%   OUTPUT
%  --------
%  field_out      :     Output field that is the last '.' delimited element
%                          of field_expr input. If it can't parse the whole
%                          thing, the struct is returned up to the furthest
%                          field that it contains.
%
%  field_exists_flag :  Optional output flag that returns true if the whole
%                          thing gets parsed correctly.
%
%  field_isempty_flag:  Optional output flag that returns true if the field
%                          exists but is empty.
%
% By: Max Murphy  v1.0  2019-06-20  Original version (R2017a)

%%

field_exists_flag = true;
field_isempty_flag = false;
if ~ischar(field_expr)
   fprintf(1,'field_expr must be a char vector (e.g. ''struct.field1.field2'')\n');
   field_exists_flag = false;
   field_out = [];
   return;
end

fName = strsplit(field_expr,'.');
field_out = struct_in;
for ii = 2:numel(fName)
   if isfield(field_out,fName{ii})
      field_out = field_out.(fName{ii});
   else
      field_exists_flag = false;
      fprintf(1,'%s: missing %s field.\n',strjoin(fName(1:(ii-1)),'.'),fName{ii});
      return;
   end
end
field_isempty_flag = isempty(field_out);
end