function cb = getCB95(x,uniformOutput)
%GETCB95 Return 95% confidence bounds
%
%  cb = analyze.stat.getCB95(x);
%  cb = analyze.stat.getCB95(x,uniformOutput);
%
% Inputs
%  x  - Data vector
%  uniformOutput - Default: false; set true to return an array instead of
%                    cell
%
% Output
%  cb - Cell containing [lb, ub] based on sorted values of x.
%        -> Removes nan values
%        -> Removes inf values
%
% See also: analyze.stat, splitapply, findgroups

if nargin < 2
   uniformOutput = false;
end

x = x(~isnan(x) & ~isinf(x));
x = sort(x,'ascend');
n = numel(x);
if n == 0
   cb = {[nan nan]};
   return;
elseif n == 1
   cb = {[x x]};
   return;   
end

i_lb = max(round(0.025 * n),1);
i_ub = round(0.975 * n);

if uniformOutput
   cb = [x(i_lb) x(i_ub)];
else
   cb = {[x(i_lb) x(i_ub)]};
end

end