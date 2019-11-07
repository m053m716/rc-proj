function param = xPCA(name)
%% XPCA   param = defaults.xPCA('paramName');

%%
p = struct;
p.t_start = -1000; % ms
% p.t_start = -600; % ms
p.t_stop = 750; % ms
% p.t_stop = 400; % ms
p.areas = categorical({'CFA','RFA'});
p.groups = categorical({'Intact','Ischemia'});
p.latent_threshold = 0.95; % percent-explained threshold
p.varcapt_threshold = 0.75; % threshold for removing an Intact channel (reconstruction)
p.debug = false; % enables debug conditionals

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