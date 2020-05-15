function S = slice(T,varargin)
%SLICE  Return "sliced" table using filters in `varargin`
%
%  S = analyze.pc.slice(T,varargin);
%
%     ## Example 1: Return only successful rows ##
%     ```(matlab)
%        S = analyze.pc.slice(T,...
%           'Outcome','Successful');
%     ```
%
%     ## Example 2: Return only successful rows for RC-43 ##
%     ```(matlab)
%        S = analyze.pc.slice(T,...
%           'AnimalID','RC-43',...
%           'Outcome','Successful');
%     ```
%
%  In general, it's just <'Name',value> syntax where 'Name' is a variable
%  in the table `T_in` and value is a scalar or subset of values that
%  should be included (excluding all other values of that variable) for 
%  the output table `T_out`

if numel(varargin) < 2
   S = T;
   return;
elseif numel(varargin) >= 2
   T = analyze.pc.slice(T,varargin{1:(end-2)});
   if ismember(varargin{end-1},T.Properties.VariableNames)
      S = T(ismember(T.(varargin{end-1}),varargin{end}),:);
   else
      warning(['RC:' mfilename ':BadFilter'],...
         ['\n\t->\t<strong>[RC:' mfilename ':BadFilter]</strong>\n' ...
         '\t\t''%s'' is not a valid filtering variable.'],varargin{end-1});
      S = T;
   end
   return;
end
end