function T = applyTransform(T)
%APPLYTRANSFORM  Applies rate smoothing if not yet applied
%
%  T = applyTransform(T);

if ~isfield(T.Properties.UserData,'IsTransformed')
   T.Properties.UserData.IsTransformed = false;
end

if T.Properties.UserData.IsTransformed
   return;
end
T.Rate = feval(T.Properties.UserData.Transform,T.Rate);
T.Properties.UserData.IsTransformed = true;

end