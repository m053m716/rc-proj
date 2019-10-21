function param = xPCA(name)
%% XPCA   param = defaults.xPCA('paramName');

%%
p = struct;
p.t_start = -1000; % ms
p.t_stop = 750; % ms
p.debug = true; % enables debug conditionals

%%
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