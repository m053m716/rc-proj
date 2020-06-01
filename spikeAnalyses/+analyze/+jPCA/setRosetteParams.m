function p = setRosetteParams(varargin)
%SETROSETTEPARAMS Allows custom setting of `rosette` parameters struct
%
% p = analyze.jPCA.setRosetteParams('Field1',val1,...);
%
% Inputs
%  <'Name', value> Input pairs to modify the struct returned by
%     `p = defaults.jPCA('rosette_params');`
%     Which has default parameters for rosette plots
%
% Output
%  p - Struct with parameters for rosette plots, updated to include
%        optional <'Name', value> pair changes

if nargin > 0
   if isstruct(varargin{1})
      p = varargin{1};
      varargin(1) = [];
   else
      p = defaults.jPCA('rosette_params');
   end
else
   p = defaults.jPCA('rosette_params');
   return;
end

fn = fieldnames(p);
for iV = 1:2:numel(varargin)
   idx = ismember(lower(fn),lower(varargin{iV}));
   if sum(idx)==1
      p.(fn{idx}) = varargin{iV+1};
   elseif sum(idx)>1
      error(['JPCA:' mfilename ':BadParameterField'],...
         ['\n\t->\t<strong>[ROSETTE]:</strong> ' ...
          'Parameter field %s is ambiguous due to case!\n'],...
          fn{idx});
   end
end

end