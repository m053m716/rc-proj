function param = dPCA(name)
%% DEFAULTS.DPCA    Return default parameters associated with dPCA export
%
%  param = DEFAULTS.DPCA(name);
%
%           -> 't_start' (start alignment time, ms)
%
%           -> 't_stop' (stop alignment time, ms)
%
% By: Max Murphy  v1.0  2019-10-14  Original version (R2017a)

%%
p = struct;
p.local_repo_loc = 'C:\MyRepos\_import\dPCA\matlab';
p.t_start = -500; % ms
p.t_stop = 500; % ms
p.path = 'P:\Rat\BilateralReach\RC\dPCA\data';
p.fname = '%s_dPCA-FiringRates-Days.mat';

p.combinedParams = {{1, [1 3]}, {2, [2 3]}, {3}, {[1 2], [1 2 3]}};
p.margNames = {'Day', 'Outcome', 'Condition-independent', 'D/O Interaction'};
p.margColours = [23 100 171; 187 20 25; 150 150 150; 180 150 25]/256;

if nargin < 1
   param = p;
   return;
end

if ismember(name,fieldnames(p))
   param = p.(name);
else
   error('%s is not a valid parameter. Check spelling?',name);
end

end