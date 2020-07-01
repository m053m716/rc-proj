function [R2,RSS,TSS] = getR2(g,x,y)
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
   y = g;
else
   y_hat = g(x);
end
   
mu = nanmean(y);
mu_hat = nanmean(y_hat);
TSS = nansum((y - mu).^2);
RSS = nansum(((y_hat - mu_hat) - (y - mu)).^2);
ESS = nansum((y_hat - mu).^2);
R2 = ESS/TSS;
end