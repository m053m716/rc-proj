function varargout = conditionResponseCorrelations(varargin)
%CONDITIONRESPONSECORRELATIONS Return parameters for condition-response correlation analyses
%
%  p = defaults.conditionResponseCorrelations();
%  [var1,var2,...] = defaults.conditionResponseCorrelations('var1Name','var2Name',...);
%

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
[p,p_out,p.fname_r,fname_c] = defaults.files('tank',...
   'condition_response_corr_loc','fname_corr','fname_coh');
p.save_path = fullfile(p,p_out);
coh_range = sprintf('%gHz-%gHz',p.f_lb,p.f_ub);
p.fname_c = [fname_c coh_range];

% Parse output
if nargin < 1
   varargout = {p};   
else
   F = fieldnames(p);   
   if (nargout == 1) && (numel(varargin) > 1)
      varargout{1} = struct;
      for iV = 1:numel(varargin)
         idx = strcmpi(F,varargin{iV});
         if sum(idx)==1
            varargout{1}.(F{idx}) = p.(F{idx});
         end
      end
   elseif nargout > 0
      varargout = cell(1,nargout);
      for iV = 1:nargout
         idx = strcmpi(F,varargin{iV});
         if sum(idx)==1
            varargout{iV} = p.(F{idx});
         end
      end
   else
      for iV = 1:nargin
         idx = strcmpi(F,varargin{iV});
         if sum(idx) == 1
            fprintf('<strong>%s</strong>:',F{idx});
            disp(p.(F{idx}));
         end
      end
   end
end

end