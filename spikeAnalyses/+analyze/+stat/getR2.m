function [R2,RSS,TSS] = getR2(g,x,y,w)
%GETR2 Return R2 for observations & model
%
%  [R2,RSS,TSS] = analyze.stat.getR2(g,x,y);
%  [R2,RSS,TSS] = analyze.stat.getR2(y,yhat);
%
% Inputs
%  g - Function handle (model)
%  x - Independent variable vector (days)
%  y - Matched dependent variable vector (should match model g)
%
%  or
%
%  y    - Dependent variable vector
%  yhat - Model predictions matched to elements of `y`
%
% Output
%  R2  - Coefficient of determination based on model
%  RSS - Residual sum of squares
%  TSS - Total sum of squares (data variance, essentially)

if isnumeric(g)
   y_hat = x;
   if nargin > 2
      w = y;
   else
      w = nan;
   end
   y = g;
   
else
   y_hat = g(x);
   if nargin < 3
      w = nan;      
   end
end
   
mu = nanmedian(y);
mu_hat = nanmedian(y_hat);
if isnan(w(1))
   w = ones(size(mu));
elseif numel(w)==numel(y)
   if isrow(y)
      if ~isrow(w)
         w = w.';
      end
   else
      if ~iscolumn(w)
         w = w.';
      end
   end
else
   error(['RC:' mfilename ':BadInputSize'],...
      ['\n\t->\t<strong>[STAT.GETR2]:</strong> ' ...
       'Number of elements of `w` (%d) should match `y` (%d)\n'],...
       numel(w),numel(y));
end
TSS = nansum(((y - mu).^2).*w);
RSS = nansum((((y_hat - mu_hat) - (y - mu)).^2).*w);
% Since we used medians, RSS could be greater than TSS; for example, if
% there is a large outlier or something like that, the square of that
% outlier will not be captured as well by the model we've fit, so that will
% cause RSS to be higher than TSS. In this instance, our estimate of R2 is
% typically supposed to be an underestimate of the actual model accuracy
% (we are using medians to be conservative with outlier data). To make it
% look "less-weird" we are setting a bound on RSS here to be no larger than
% TSS, with the understanding that a negative value of R2 would basically
% just indicate the model is being fit poorly in the same sense as R2 = 0.
R2 = 1 - (min(RSS,TSS)/TSS);

end