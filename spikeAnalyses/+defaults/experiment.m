function varargout = experiment(varargin)
%EXPERIMENT Return default parameters associated with experiment
%
%  param = defaults.experiment(name);
%
%  # Parameters (`name` values) #
%  -> 't'               : Times (sec) for trial-aligned recording bins
%  -> 't_ms'            : (Parsed from `t`): Times (milliseconds)
%  -> 'skip_save'       : Set true to skip saving on constructor function
%  -> 'poday_min'       : Minimum value for post-op day
%  -> 'poday_max'       : Maximum value for post-op day

p = struct;
% Initialization parameters
p.skip_save = false;

% Experiment parameters
p.poday_min = 1;
p.poday_max = 31;
p.rat_id = [2;4;5;8;14;18;21;26;30;43];
p.rat = {     ...
   'RC-02';'RC-04';'RC-05';'RC-08';'RC-14';'RC-18'; ... 
   'RC-21';'RC-26';'RC-30';'RC-43'  ... 
   };
p.icms_opts = ...
   {'DF',...      % Distal Forelimb (only)
    'PF',...      % Proximal Forelimb (only)
    'DF-PF',...   % Distal Forelimb + Proximal Forelimb (border-ish)
    'PF-DF',...   % Proximal Forelimb + Distal Forelimb (same as above)
    'O',...       % "Other" representation (e.g. trunk or face etc.)
    'NR'};        % Non-responsive (nothing elicited at 80 uA, 13 pulses)
p.area_opts = {'RFA','CFA'};
p.event_opts = {'Reach','Grasp','Support','Complete'};
p.ml_opts = {'M','L'};
p.group_names = {'Ischemia','Intact'}; % 2 experimental groups
p.group_assignments = {[1:4,8:9], ...  % (Rat indices): 'Ischemia'
                       [5:7,10]};      % (Rat indices): 'Intact'

% Analysis parameters
% (Old)
% p.t = linspace(-1.9995,0.9995,3000); % Times (sec) for recording bin centers
% p.start_stop_bin = [-2000 1000]; % ms
% p.spike_bin_w = 1; % ms
% p.spike_smoother_w = 30; % ms
% p.pre_trial_norm_epoch = [-2000 -1500];
% p.pre_trial_norm = 1:500; % sample indices [deprecated; now parsed from
%                           % pre_trial_norm_epoch parameter]

% (New) - Apr-2020
p.t = linspace(-1.470,870,40);   % Times (sec) for bin centers
p.start_stop_bin = [-1500 900];  % ms
p.t_start_stop_reduced = [-1000 650]; % ms (restricted)
p.n_ds_bin_edges = local.defaults('N_DS_EDGES');
p.spike_bin_w = 60; % ms
p.spike_smoother_w = 240; % ms
p.pre_trial_norm_epoch = [-1500 -1000];

% Default subset of trials to look at
p.alignment = 'Grasp';     % 'Grasp' or 'Reach' alignment
p.area = 'Full';           % Recording unit area ('CFA','RFA','Full')
p.outcome = 'Successful';  % 'Successful' or 'Unsuccessful' or 'All'

% Options for behavioral scoring output are: 
%  * 'BehaviorScore'    (from Andrea video scoring; original) 
%  * 'NeurophysScore'   (based on tagged metadata; updated)
%  * 'TrueScore'        (based on only trials WITH pellets; revised)
p.output_score = 'TrueScore';

% Marker for each rat name
p.marker = struct(...
      'RC02','o',...
      'RC04','x',...
      'RC05','s',...
      'RC08','p',...
      'RC26','h',...
      'RC30','d',...
      'RC14','>',...
      'RC18','<',...
      'RC21','v',...
      'RC43','^');

% "Includes": includeStruct determines what alignments are used based on
% tagged video metadata
p.rate_table_includes = ...
   {utils.makeIncludeStruct({'Reach','Grasp','Complete','Outcome'},[]); ...
    utils.makeIncludeStruct({'Reach','Grasp','Complete'},{'Outcome'})};

% For output Tableau tables, "metadata" variables and "event" variables go
% into different files
p.meta_vars = {'RowID','Trial_ID','Group','AnimalID','BlockID',...
   'PostOpDay','Alignment','ML',...
   'ICMS','Area','ProbeID','Probe','ChannelID','Channel',...
   'PelletPresent','Outcome'};
p.event_vars = {'Reach','Grasp','Support','Complete'};
 
% Default "rate-smoothing" function (only applied to `getRateTable`
% extracted rates, not anything in .mat files)
p.rate_smoothing_fcn = @(rate)sgolayfilt(rate,3,17,ones(1,17),2);
p.pca_exclusion_fcn = @(T)T(T.PelletPresent=={'Present'},:);

% Default colors (for figures, etc.)
p.event_color = {[0.1 0.1 0.7], ... 'reach'
                 [0.0 0.0 0.0], ... 'grasp'
                 [0.8 0.1 0.8], ... 'support'
                 [0.7 0.8 0.1]}; %  'complete'
p.area_color = {[0.4 0.4 1.0],... 'RFA'
                [1.0 0.4 0.4]}; % 'CFA'
p.rat_color = struct(...
   'All',[...
      0.65  0.00  0.00;    % RC-02
      0.70  0.05  0.05;    % RC-04
      0.75  0.10  0.10;    % RC-05
      0.80  0.15  0.15;    % RC-08
      0.00  0.00  0.65;    % RC-14
      0.05  0.05  0.70;    % RC-18
      0.10  0.10  0.75;    % RC-21
      0.85  0.20  0.20;    % RC-26
      0.90  0.25  0.25;    % RC-30
      0.15  0.15  0.80],...% RC-43
   'Ischemia',[...
      0.45  0.00  0.00;    % RC-02
      0.50  0.05  0.05;    % RC-04
      0.60  0.10  0.10;    % RC-05
      0.70  0.15  0.15;    % RC-08
      0.85  0.20  0.20;    % RC-26
      0.90  0.35  0.35],...% RC-30
   'Intact',[...
      0.00  0.00  0.65;    % RC-14
      0.05  0.05  0.70;    % RC-18
      0.10  0.10  0.75;    % RC-21
      0.15  0.15  0.80]);  % RC-43
p.rat_marker = {'o','*','square','x','v','hexagram'};

% % For PCA stuff (2020) % %
p.pca_n = 5;
p.pca_opts = statset('Display','off');
p.pca_group_var_indices = [3 5 6 9 20];
p.pca_marg_vars = {'AnimalID','PostOpDay','Area','Outcome'};
p.pca_iterate_on = 'Alignment';

% % % Parameters that are parsed from other parameters % % %
p.t_ms = p.t*1e3;
p.t_ds = linspace(p.start_stop_bin(1),p.start_stop_bin(2),p.n_ds_bin_edges);
p.r_ds = round((p.start_stop_bin(2) - p.start_stop_bin(1))/p.spike_bin_w/p.n_ds_bin_edges); 
p.pre_trial_norm = find(...
   (p.t_ms >= p.pre_trial_norm_epoch(1)) & ...
   (p.t_ms <= p.pre_trial_norm_epoch(2)));
p.pre_trial_norm_ds = p.pre_trial_norm(1):round(p.pre_trial_norm(end)/p.r_ds);
p.rat_cats = categorical(p.rat_id,p.rat_id,p.rat);
p.icms_cats = categorical(p.icms_opts);
p.area_cats = categorical(p.area_opts);
p.group_cats = categorical(p.group_names);
p.ml_cats = categorical(p.ml_opts);
p.event_cats = categorical(p.event_opts);
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