function SS = getSS(y,yhat)
%GETSS Return sum of squares struct for data and predictions
%
%  SS = analyze.stat.getSS(y,yhat);
%
% Inputs
%  y    - Observed data
%  yhat - Predicted data
%
% Output
%  SS   - Struct with fields for 'mu' (ybar), mean of observed; TSS total
%           sum of squares; ESS (explained sum of squares or sum-of-squares
%           regression); RSS (residual sum-of-squares or sum-of-squares 
%           error); Total (field with summary terms 'Rsquared', 'df_e',
%           'df_t', and 'Rsquared_adj' which normalizes 'Rsquared' using
%           'df_e' and 'df_t' ratio).
%
% See also: analyze.stat, kal.getChannelRegression



SS = struct;
SS.y = y;
SS.yhat = yhat;
SS.mu = nanmean(SS.y,1); % ybar; the mean of observed variables
ts = (SS.y - SS.mu).^2; % Total squares
SS.TSS = sum(ts,1);         % Total sum-of-squares = Observed - mean(observed)
es = (SS.yhat - SS.mu).^2;  % Explained squares
SS.ESS = sum(es,1);     % Explained sum-of-squares = Predicted - mean(observed)
rs = (SS.yhat - SS.y).^2; % Residual squares
SS.RSS = sum(rs,1);  % Residual sum-of-squares = Observed - Predicted (element-wise)

ess = nansum(es(:));
tss = nansum(ts(:));
SS.Total.Rsquared = ess/tss;
n = size(SS.y,1);
p = size(SS.y,2);
SS.Total.df_e = n - p - 1;
SS.Total.df_t = n - 1;
SS.Total.Rsquared_adj = 1 - (1 - SS.Total.Rsquared)*(n - 1)/(n - p - 1);

end