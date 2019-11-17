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
p.f = linspace(0,4,2^14); % Frequencies (Hz) to use for periodograms
p.f_slow_compare = 0.5; % (Hz) Shouldn't actually be used; freq comparison for coherence
p.debug = false; % enables debug conditionals

% Bootstrap params
p.n_remove = 4;
p.n_reps = 100;
p.min_n_to_run = 8;

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