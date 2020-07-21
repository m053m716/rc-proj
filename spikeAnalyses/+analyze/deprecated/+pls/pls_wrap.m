function [XL,YL,XS,YS,BETA,PCTVAR,MSE,stats] = pls_wrap(X,y,n)
%PLS_WRAP Wrapper for function plsregress
%
%  [XL,YL,XS,YS,BETA,PCTVAR,MSE,stats] = analyze.pls.pls_wrap(X,y,n);
%
% Inputs
%  X - Rows are trials, columns are time-samples
%  y - Labels to regress onto (e.g. PostOpDay)
%  n - # PLS components
%
% Output
%  

[XL,YL,XS,YS,BETA,PCTVAR,MSE,stats] = ...
   plsregress(X,y,n);
XL = {XL};
YL = {YL};
XS = {XS};
YS = {YS};
BETA = {BETA};
PCTVAR = {PCTVAR};
MSE = {MSE};
stats = {stats};
end