function T = applyTransform(T)
%APPLYTRANSFORM  Applies rate smoothing if not yet applied
%
%  T = applyTransform(T);
%  -> Applies to table returned from `T = getRateTable(gData);`
%
%  Simply checks the UserData.IsTransformed property of the Rates table T.
%  If the transformation has not yet been applied, it does so.

if ~isfield(T.Properties.UserData,'IsTransformed')
   T.Properties.UserData.IsTransformed = false;
end

if T.Properties.UserData.IsTransformed
   return;
end
transform = T.Properties.UserData.Transform;
if iscell(T.Rate)
   T.Rate = cellfun(@(C)feval(transform,C),T.Rate,'UniformOutput',false);
else
   T.Rate = feval(transform,T.Rate);
end
T.Properties.UserData.IsTransformed = true;
T.Properties.Description = ...
   'Table of normalized and smoothed rate time-series for each trial';
end