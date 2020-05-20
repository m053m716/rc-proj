function [S,rate] = sliceRate(T,varargin)
%SLICERATE  Return "sliced" table & rate using filters in `varargin`
%
%  [S,rate] = analyze.sliceRate(T,varargin);
%
%     ## Example 1: Return only successful rows ##
%     ```(matlab)
%        [S,rate] = analyze.slice(T,...
%           'Outcome','Successful');
%     ```
%
%     ## Example 2: Return only successful rows for RC-43 ##
%     ```(matlab)
%        [S,rate] = analyze.slice(T,...
%           'AnimalID','RC-43',...
%           'Outcome','Successful');
%     ```
%
%  Same as `analyze.slice` but "chunks out" rate for convenience.

if numel(varargin) < 2
   rate = T.Rate;
   S = T(:,setdiff(T.Properties.VariableNames,'Rate'));
   return;
elseif numel(varargin) >= 2
   T = analyze.slice(T,varargin{1:(end-2)});
   if ismember(varargin{end-1},T.Properties.VariableNames)
      S = T(ismember(T.(varargin{end-1}),varargin{end}),:);
   else
      warning(['RC:' mfilename ':BadFilter'],...
         ['\n\t->\t<strong>[RC:' mfilename ':BadFilter]</strong>\n' ...
         '\t\t''%s'' is not a valid filtering variable.'],varargin{end-1});
      S = T;
   end
   rate = S.Rate;
   S = S(:,setdiff(T.Properties.VariableNames,'Rate'));
   return;
end
end