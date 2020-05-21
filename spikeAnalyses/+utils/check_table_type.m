function [type,T] = check_table_type(T)
%CHECK_TABLE_TYPE  Return char indicating "type" of data table
%
%  type = utils.check_table_type(T);
%  [type,T] = utils.check_table_type(T);
%
%  -- Inputs --
%  T : Data table, such as returned by 
%        * `T = getRateTable(gData);` 
%           or 
%        * `Y = analyze.trials.make_table(T,'Reach','Successful');`
%
%  -- Output --
%  type : Char array, depends upon what type of table it is
%           -> For `getRateTable`, returns 'channels' (typical)
%           -> For `trials.make_table`, returns 'trials'
%
%  T    : (Optional) Same as input table, but with parsed 'Type' added as
%                    UserData field if didn't exist already.

% Make sure that UserData is a struct
if ~isstruct(T.Properties.UserData)
   if isempty(T.Properties.UserData)
      T.Properties.UserData = struct;
   else
      disp('T.Properties.UserData:');
      disp(T.Properties.UserData);
      error(['RC:' mfilename ':BadUserData'],...
         'Table UserData property is unexpected value.');
   end
end

if isfield(T.Properties.UserData,'Type')
   type = T.Properties.UserData.Type;
   return;
else
   type = 'unknown';
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