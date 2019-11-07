function [rate,t] = getSetIncludeStruct(obj,align,includeStruct,rate,t)
%% GETSETINCLUDESTRUCT  Get or Set struct fields based on includeStruct format
%
%  obj.GETSETINCLUDESTRUCT(align,includeStruct,rate,t);
%
%  or
%
%  [rate,t] = obj.GETSETINCLUDESTRUCT(align,includeStruct);
%
% By: Max Murphy  v1.0  2019-10-20  Original version (R2017a)

%% CHECK INPUT & OUTPUT
if (nargout > 0) && (nargin > 3)
   error('Number of inputs suggests a SET call, but number of outputs suggests a GET call.');
end

if (nargout < 1) && (nargin < 4)
   error('Number of inputs suggests a GET call, but number of outputs suggests a SET call.');
end

%% HANDLE MULTIPLE INPUT OBJECTS
if numel(obj) > 1
   rate = cell(numel(obj),1);
   for ii = 1:numel(obj)
      if nargout > 1
         [rate{ii},t] = getSetIncludeStruct(obj(ii),align,includeStruct);
      else
         if ~iscell(rate)
            error('For setting multiple input objects at once, specify rate as a cell with one cell per RAT object');
         end
         getSetIncludeStruct(obj(ii),align,includeStruct,rate{ii},t);
      end
   end
   return;
end

% Get the field expression
field_expr = parseIncludeFieldExpr(align,includeStruct);
fe_t = [field_expr '.t'];
fe_rate = [field_expr '.rate'];
emptyStruct = struct;


if nargout < 1 % Set
   obj.XCMean = setStructField(obj.XCMean,{field_expr,fe_t,fe_rate},{emptyStruct,t,rate});
   
else % Get
   [rate,field_exists_flag,field_isempty_flag] = parseStruct(obj.XCMean,fe_rate);
   if (field_exists_flag) && (~field_isempty_flag)
      t = parseStruct(obj.XCMean,fe_t);
   else
      rate = [];
      t = [];
   end
   
end

%% SUPPRESS OUTPUT IF USING SET CALL
if nargout < 1
   rate = [];
   t = [];
end

   function field_expr = parseIncludeFieldExpr(align,includeStruct)
      xc_fields = defaults.group('xc_fields');
      field_expr = ['XCMean.' align];  
      
      for iX = 1:numel(xc_fields)
         field_expr = addToIncludeString(field_expr,includeStruct,xc_fields{iX});
      end     
   end

   function str_out = addToIncludeString(str_in,includeStruct,varName)
      if ismember(varName,includeStruct.Include)
         str_out = [str_in '.Include'];
      elseif ismember(varName,includeStruct.Exclude)
         str_out = [str_in '.Exclude'];
      else
         str_out = [str_in '.All'];
      end
   end


end