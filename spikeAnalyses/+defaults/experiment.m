function param = experiment(name)
%% DEFAULTS.EXPERIMENT    Return default parameters associated with experiment
%
%  param = DEFAULTS.EXPERIMENT(name);
%
%           -> 't'
%
% By: Max Murphy  v1.0  2019-06-06  Original version (R2017a)

%%
p = struct;
p.t = linspace(-1.9995,0.9995,3000); % Times (sec) for recording bins
p.tank = 'P:\Rat\BilateralReach\RC';

if ismember(lower(name),fieldnames(p))
   param = p.(lower(name));
else
   error('%s is not a valid parameter. Check spelling?',lower(name));
end

end