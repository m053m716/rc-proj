function [Beta,Beta0,Z,o,s] = recover_line(X,Y,varargin)
%RECOVER_LINE Recover coefficients for line through <x,y> pairs
%
%  [Beta,Beta0] = analyze.stat.recover_line(X,Y);
%  [Beta,Beta0,Z,o,s] = analyze.stat.recover_line(X,Y,'Name',value,...);
%
% Inputs
%  X        - Column vector of k x-coordinate values (matching Y)
%  Y        - Column vector of k y-coordinate values (matching X)
%  varargin - (Optional) 'Name' value parameter pairs
%              * 'DistanceFunction' | @(a,b)minus(a,b)
%              * 'ResponseFunction' | @(y)y
%              * 'Method'           | 'median'
%              * 'UseScaling'       | true
%              * 'Weights'          | NaN (otherwise must have k weights)
%
% Output
%  Beta     - Coefficient of best-fit line through X and Y
%  Beta0    - Constant offset for best-fit line through X and Y
%  Z        - Transformed response vector
%  o        - Offset (from scaling)
%  s        - Scale factor (from scaling)

pars = struct;
pars.DistanceFunction = @(a,b)minus(a,b);
pars.WeightsDistanceFunction = @(a,b)plus(a,b);
pars.ResponseFunction = @(y)y;
pars.Method = 'median';
pars.UseScaling = true;
pars.Weights = nan;
fn = fieldnames(pars);

if nargin > 2
   if isstruct(varargin{1})
      pars = varargin{1};
      varargin(1) = [];
   end
end

for iV = 1:2:numel(varargin)
   idx = strcmpi(fn,varargin{iV});
   if sum(idx)==1
      pars.(fn{idx}) = varargin{iV+1};
   end
end

% Apply scaling if requested
if pars.UseScaling
   [yn,o,s] = analyze.stat.scaleResponse(X,Y);
else
   yn = Y; o = 0; s = 1;
end
Z = pars.ResponseFunction(yn);

dZ = pdist(Z,pars.DistanceFunction);
dX = pdist(X,pars.DistanceFunction);
iBad = isinf(dZ) | isinf(dX) | isnan(dZ) | isnan(dX);

if ~any(~iBad)
   Beta  = [];
   Beta0 = [];
   return;
else
   dZ(iBad) = [];
   dX(iBad) = [];
end

switch lower(pars.Method)
   case 'median'
      if ~isnan(pars.Weights(1))
         if any(pars.Weights < 1)
            w = round(pars.Weights * 100);
         else
            w = round(pars.Weights);
         end
         dW = pdist(w,pars.WeightsDistanceFunction);
         dW(iBad) = [];
         dZ = repelem(dZ,dW);
         dX = repelem(dX,dW);

      end
      Beta  = nanmedian(dZ ./ dX);
      z0 = nanmedian(Z);
      x0 = nanmedian(X);
      Beta0 = z0 - Beta*x0;
   case 'mean'
      Beta = (dZ') \ (dX');
      Beta0 = nanmean(z) - Beta*nanmean(X);

   otherwise
      error(['RC:' mfilename ':BadCase'],...
         ['\n\t->\t<strong>[STATS.RECOVER_LINE]:</strong> ' ...
          'Bad "Method" parameter: %s \n' ...
          '\t\t\t(should be one of: ''mean''|''median'' (default))\n'],...
          pars.Method);
end


end