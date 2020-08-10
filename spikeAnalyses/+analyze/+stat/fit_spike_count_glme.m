function glme = fit_spike_count_glme(R,align,outcome,t_epoc,varargin)
%FIT_SPIKE_COUNT_GLME Fit Generalized Linear Mixed-Effects model for spike counts
%
%  glme = analyze.stat.fit_spike_count_glme(R,align,outcome,t_epoc);
%  glme = analyze.stat.fit_spike_count_glme(__,'Name',value,...);
%
%  Iterates on any cell array inputs of `align`, `outcome`, or `t_epoc`, 
%  so that if any are provided as a cell then output `glme` is an array
%  corresponding to a combination each selected level.
%
% Inputs
%  R        - Raw rates table [in defaults.files('raw_rates_table_file')]
%
%  align    - 'Reach' | 'Grasp' | 'Support' | 'Complete'
%              -> Or, a cell array with multiple members from that list
%
%  outcome  - 'Successful' | 'Unsuccessful'
%              -> Or, cell array with both
%
%  t_epoc   - [tStart (ms), tStop (ms)] or cell array of relative
%                 time-ranges, e.g. {[-600 -300]; [-300 300]};
%
%  varargin - (Optional) <'Name',value> input argument pairs.
%
% Output
%  glme     - Scalar GeneralizedLinearMixedModel object; or,
%              if any of `align`, `outcome`, or `t_epoc` is a cell, 
%              then this is a cell array with number of elements 
%              corresponding to the unique combinations of those three 
%              input levels.
%
% See also: analyze.stat, group, group.getRateTable,
%           analyze.stat.fit_full_spike_count_glme,
%           analyze.stat.surf_partial_dependence

% % Parse input parameters % %
pars = struct;
pars.DataVars = {...
   'Group','AnimalID','BlockID','Trial_ID',...
   'PostOpDay','Area','ICMS',...
   'ProbeID','ChannelID','Duration' ...
   };
pars.DispersionFlag = true;
pars.Distribution = "Poisson";
pars.DummyVarCoding = "effects";
pars.FitMethod = "Laplace";
pars.Link = "log";
[pars.MinDuration,pars.MaxDuration] = defaults.complete_analyses('min_duration','max_duration');
pars.MaxRate = 300; % Spikes/sec
pars.MinRate = 2.5; % Spikes/sec
pars.Model = "Spikes~Group*Area+(1|ChannelID:Day)+(1+Duration|AnimalID)+(1|SupportLimbMovement)+(1|Trial_ID)+(1|ICMS)";
pars.PelletPresent = "Present";
pars.Verbose = true;
pars.WeightVariable = '';
pars.Weights = [];

fn = fieldnames(pars);
if numel(varargin) > 0
   if isstruct(varargin{1})
      pars = varargin{1};
      varargin(1) = [];
   end
end

for iV = 1:2:numel(varargin)
   idx = strcmpi(fn,varargin{iV});
   if sum(idx)==1
      pars.(fn{idx}) = varargin{iV+1};
   end
end
% % End parsing input parameters % %

% % Parse input cell array for "selector" arguments % %
% Iterate on alignments
if iscell(align)
   nA = numel(align);
   if iscell(outcome)
      nO = numel(outcome);
      
   else
      nO = 1;
      assignCell = false;
   end
   if iscell(t_epoc)
      nT = numel(t_epoc);
      assignCell = true;
   else
      nT = 1;
   end
   glme = cell(nA*nT*nO,1);
   if assignCell
      vec = 1:(nT*nO);
      for iA = 1:nA
         glme(vec,1) = analyze.stat.fit_spike_count_glme(...
            R,align{iA},outcome,t_epoc,pars);
         vec = vec + (nT*nO);
      end 
   else
      for iA = 1:nA
         glme{iA} = analyze.stat.fit_spike_count_glme(...
            R,align{iA},outcome,t_epoc,pars);
      end 
   end
   return;
end

% Iterate on outcomes
if iscell(outcome)
   nO = numel(outcome);
   if iscell(t_epoc)
      nT = numel(t_epoc);
      assignCell = true;
   else
      nT = 1;
      assignCell = false;
   end
   glme = cell(nO*nT,1);
   if assignCell
      vec = 1:nT;
      for iO = 1:nO
         glme(vec,1) = analyze.stat.fit_spike_count_glme(...
            R,align,outcome{iO},t_epoc,pars);
         vec = vec + nT;
      end
   else
      for iO = 1:nO
         glme{iO,1} = analyze.stat.fit_spike_count_glme(...
            R,align,outcome{iO},t_epoc,pars);
      end
   end
   return;
end

% Iterate on relative times
if iscell(t_epoc)
   nT = numel(t_epoc);
   glme = cell(nT,1);
   for iT = 1:nT
      glme{iT,1} = analyze.stat.fit_spike_count_glme(...
         R,align,outcome,t_epoc{iT},pars);
   end
   return;
end
% % End iterations % %

% Screen to a reduced subset of trials
if strcmpi(outcome,'All')
   r = analyze.slice(R,...
      'Alignment',align,...
      'PelletPresent',pars.PelletPresent);
else
   r = analyze.slice(R,...
      'Alignment',align,...
      'Outcome',outcome,...
      'PelletPresent',pars.PelletPresent);
end

% Get relative sample times for each rate bin
t = r.Properties.UserData.t;
iEpoch = (t >= t_epoc(1)) & (t <= t_epoc(2));
tt = t(iEpoch);
dt = (range(tt)+mode(diff(t)))*1e-3; % Each time is the bin center; account for "widths"

% Create new variables to add: Spikes (response); N (weights; total spikes)
Spikes = sum(r.Rate(:,iEpoch),2);
N = sum(r.Rate,2);
Day = ordinal(r.PostOpDay);
SupportLimbMovement = categorical(~(isnan(r.Support)|isinf(r.Support))+1,...
   [1 2],{'Absent','Present'});
Extension = r.Grasp - r.Reach;
Retraction = r.Complete - r.Grasp;

% Create data table for statistics
newVars = table(Day,SupportLimbMovement,Spikes,N,Extension,Retraction);
newVars.Properties.VariableUnits = ...
   {'days','','count','total count','sec','sec'};
rThis = r(:,pars.DataVars);

S = [rThis,  newVars];

% Make exclusions based on spike levels
excluded = struct;
excluded.Duration = (S.Duration < pars.MinDuration) | ...
                    (S.Duration > pars.MaxDuration);
excluded.FixedRateThresholds = ((S.Spikes./dt) < pars.MinRate) |  ...
                               ((S.Spikes./dt) > pars.MaxRate);
excluded.All = excluded.Duration | excluded.FixedRateThresholds;
                            
% Get weights
if isempty(pars.Weights)
   if ismember(pars.WeightVariable,S.Properties.VariableNames)
      pars.Weights = S.(pars.WeightVariable);
   else
      pars.Weights = ones(size(S,1),1);
   end
else
   if ~isColumn(pars.Weights)
      pars.Weights = pars.Weights';
   end
   if numel(pars.Weights) ~= size(S,1)
      error(...
         ['Pre-specified Weights (%d elements) must contain ' ...
          'same number of elements as rows of S (%d rows)'],...
         numel(pars.Weights),size(S,1));
   end
end
pars.Weights(pars.Weights==0) = 1; % Due to weird parsing in glme model; this is for rows that are excluded anyhow

S.Properties.UserData.ModelParams = struct;
S.Properties.UserData.ModelParams.pars = pars;
S.Properties.UserData.ModelParams.excluded = excluded;
S.Properties.UserData.ModelParams.tt = tt;
S.Properties.UserData.ModelParams.t_epoc = t_epoc;
S.Properties.UserData.ModelParams.align = align;
S.Properties.UserData.ModelParams.outcome = outcome;

% Fit generalized linear mixed effects model for Poisson distributed
% response variable with a log-link function
if pars.Verbose
   fprintf(1,'\n\t==============================================\n');
   fprintf(1,...
      'GLME: <strong>%s</strong> trials <strong>(%s)</strong>\n', ...
      align,outcome);
   fprintf(1,...
      ['\t->\tFor spikes occurring <strong>%5.1f-ms</strong>' ...
      ' to <strong>%5.1f-ms</strong> relative to %s...'],...
      t_epoc(1),t_epoc(2),align);
end

glme = fitglme(...
   S,pars.Model,...
   'FitMethod',pars.FitMethod,...
   'Distribution',pars.Distribution,...
   'Link',pars.Link,...
   'DummyVarCoding',pars.DummyVarCoding,...
   'DispersionFlag',pars.DispersionFlag,...
   'Exclude',excluded.All,...
   'Weights',pars.Weights);

if pars.Verbose
   fprintf(1,'complete\n\n');
   disp(glme);
   fprintf(1,'\n<strong>R-squared:</strong>\n');
   disp(glme.Rsquared);
   fprintf(1,'\n\t==============================================\n');
end

end