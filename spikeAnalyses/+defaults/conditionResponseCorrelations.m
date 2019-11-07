function param = conditionResponseCorrelations(name)
%% CONDITIONRESPONSECORRELATIONS   param = defaults.conditionResponseCorrelations('paramName');

%%
p = struct;
p.t_start = -1000; % ms
p.t_stop = 750; % ms
p.debug = true; % enables debug conditionals
p.conf_bounds = [0.05, 0.95]; % [lower, upper] confidence bounds
p.f_lb = 1.5; % Hz, lower-bound for estimating coherence
p.f_ub = 4;   % Hz, upper-bound for estimating coherence
p.f = logspace(-2,0,40) * (p.f_ub-p.f_lb) + p.f_lb;

p.f_coh = linspace(0.1,12,128);

p.ch_by_day_legopts_c = struct('yLim',[-2 3.75],... % for plotting "legend" axes
                          'scoreScale',2,...
                          'scoreOffset',1.5,...
                          'barScale',0.5,...
                          'textOffset',[0.75,-0.85],...
                          'minTrials',10,...
                          'cfaTextY',0.5,...
                          'rfaTextY',-0.5,...
                          'axYLabel','Coherence Frequency',...
                          'scatterMarkerSize',30); 
                       
p.ch_by_day_legopts_r = struct('yLim',[-2 3.75],... % for plotting "legend" axes
                          'scoreScale',2,...
                          'scoreOffset',1.5,...
                          'barScale',0.5,...
                          'textOffset',[0.75,-0.85],...
                          'minTrials',10,...
                          'cfaTextY',0.5,...
                          'rfaTextY',-0.5,...
                          'axYLabel','Coherence Frequency',...
                          'scatterMarkerSize',30); 
                       
p.save_path = fullfile(defaults.experiment('tank'),'cross-day-correlations');
p.fname_r = '%s-%s__%s__corr';
coh_range = sprintf('%gHz-%gHz',p.f_lb,p.f_ub);
p.fname_c = ['%s_%s__%s__coherence_' coh_range];

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