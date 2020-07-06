function [type,T] = check_table_type(T,type_to_compare)
%CHECK_TABLE_TYPE  Return char indicating "type" of data table
%
%  type = utils.check_table_type(T);
%  [type,T] = utils.check_table_type(T);
%
%  flag = utils.check_table_type(T,'type');
%     -> Compare type of T against 'type'
%
%  -- Inputs --
%  T : Data table, such as returned by 
%        * `T = getRateTable(gData);` 
%           or 
%        * `Y = analyze.trials.make_table(T,'Reach','Successful');`
%
%  type_to_compare : If specified, then function returns true if matching
%                    type or false if not (Optional)
%
%  -- Output --
%  type : Char array, depends upon what type of table it is
%           -> For `getRateTable`, returns 'channels' (typical)
%           -> For `trials.make_table`, returns 'trials'
%           
%  type (if 2 inputs) : Flag-- true if matching `type_to_compare` else
%                              false
%
%  T    : (Optional) Same as input table, but with parsed 'Type' added as
%                    UserData field if didn't exist already.

% Make sure that UserData is a struct
if ~isstruct(T.Properties.UserData)
   if isempty(T.Properties.UserData)
      T.Properties.UserData = struct;
      if nargin == 2
         type = false;
         return;
      end
   else
      disp('T.Properties.UserData:');
      disp(T.Properties.UserData);
      error(['RC:' mfilename ':BadUserData'],...
         'Table UserData property is unexpected value.');
   end
end

if isfield(T.Properties.UserData,'Type')
   if nargin == 2
      type = strcmpi(T.Properties.UserData.Type,type_to_compare);
   else
      type = T.Properties.UserData.Type;
   end
   return;
elseif isfield(T.Properties.UserData,'type')
   if nargin == 2
      type = strcmpi(T.Properties.UserData.type,type_to_compare);
   else
      type = T.Properties.UserData.type;
   end
   return;
else
   if nargin == 2
      type = false;
      return;
   else
      type = 'unknown';
   end
end

switch T.Properties.DimensionNames{1}
   case 'Series_ID'
      type = 'channels';
      T.Properties.UserData.Type = type;
      return;
   case 'Trial'
      type = 'trials';
      T.Properties.UserData.Type = type;
      return;
end

end