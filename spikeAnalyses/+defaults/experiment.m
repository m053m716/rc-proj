function varargout = experiment(varargin)
%DEFAULTS.EXPERIMENT    Return default parameters associated with experiment
%
%  param = defaults.experiment(name);
%
%  # Parameters (`name` values) #
%  -> 't'               : Times (sec) for trial-aligned recording bins
%  -> 'poday_min'       : Minimum value for post-op day
%  -> 'poday_max'       : Maximum value for post-op day

p = struct;
p.poday_min = 1;
p.poday_max = 31;
p.rat = {     ...
   'RC-02'; ... 
   'RC-04'; ... 
   'RC-05'; ... 
   'RC-08'; ... 
   'RC-14'; ... 
   'RC-18'; ... 
   'RC-21'; ... 
   'RC-26'; ... 
   'RC-30'; ... 
   'RC-43'  ... 
   };
p.group_names = {'Ischemia','Intact'};
p.group_assignments = {[1:4,8:9],[5:7,10]};
p.skip_save = false;

% Analysis parameters
% (Old)
% p.t = linspace(-1.9995,0.9995,3000); % Times (sec) for recording bin centers
% p.start_stop_bin = [-2000 1000]; % ms
% p.spike_bin_w = 1; % ms
% p.spike_smoother_w = 30; % ms
% p.pre_trial_norm = 1:500; % sample indices [deprecated; now parsed from
%                           % pre_trial_norm_epoch parameter]

% (New) - Apr-2020
p.t = linspace(-1.470,870,40);   % Times (sec) for bin centers
p.start_stop_bin = [-1500 900];  % ms
p.n_ds_bin_edges = local.defaults('N_DS_EDGES');
p.t_ms = p.t*1e3;
p.spike_bin_w = 60; % ms
p.spike_smoother_w = 240; % ms
p.pre_trial_norm_epoch = [-1500 -1000];

% Default subset of trials to look at
p.alignment = 'Grasp';     % 'Grasp' or 'Reach' alignment
p.area = 'Full';           % Recording unit area ('CFA','RFA','Full')
p.outcome = 'Successful';  % 'Successful' or 'Unsuccessful' or 'All'

% Parsed parameters
p.t_ds = linspace(p.start_stop_bin(1),p.start_stop_bin(2),p.n_ds_bin_edges);
p.r_ds = round((p.start_stop_bin(2) - p.start_stop_bin(1))/p.spike_bin_w/p.n_ds_bin_edges); 
p.pre_trial_norm = find(...
   (p.t_ms >= p.pre_trial_norm_epoch(1)) & ...
   (p.t_ms <= p.pre_trial_norm_epoch(2)));
p.pre_trial_norm_ds = p.pre_trial_norm(1):round(p.pre_trial_norm(end)/p.r_ds);

% % % Display defaults (if no input or output supplied) % % %
if (nargin == 0) && (nargout == 0)
   disp(p);
   return;
end

% % % Parse output % % %
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