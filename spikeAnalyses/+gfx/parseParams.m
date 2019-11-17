function p = parseParams(cfg_key,arg_pairs)
%% PARSEPARAMS    p = gfx.parseParams(cfg_key,arg_pairs);
%
%  cfg_key : Leading char array for desired config prop 
%              (e.g. 'ShadedError_' or 'SignificanceLine_')
%
%  arg_pairs : 'Name', value, input argument pairs (varargin from main
%                 function).
%
%  p : Struct of appropriate output parameters

%% 
p = gfx.cfg;
nKey = numel(cfg_key);
if isempty(arg_pairs)
   return;
end

for i = 1:2:numel(arg_pairs)
   if ~ischar(arg_pairs{i})
      warning('Bad varargin ''name'', value syntax. Check inputs.');
      continue;
   end
   
   if numel(arg_pairs{i}) >= nKey
      if ~strcmpi(arg_pairs{i}(1:nKey),cfg_key)
         arg_pairs{i} = [cfg_key arg_pairs{i}];
      end
   else
      arg_pairs{i} = [cfg_key arg_pairs{i}];
   end
   
   p = gfx.setParamField(p,arg_pairs{i},arg_pairs{i+1});
end

end