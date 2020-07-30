function glme = fit_full_spike_count_glme(R,varargin)
%FIT_FULL_SPIKE_COUNT_GLME Fit "full" (fixed) Generalized Linear Mixed-Effects model for spike counts, incorporating all alignments of interest
%
%  glme = analyze.stat.fit_full_spike_count_glme(R);
%  glme = analyze.stat.fit_full_spike_count_glme(R,'Name',value,...);
%
%  Iterates on any cell array inputs of `align`, `outcome`, or `t_epoc`, 
%  so that if any are provided as a cell then output `glme` is an array
%  corresponding to a combination each selected level.
%
% Inputs
%  R        - Raw rates table [in defaults.files('raw_rates_table_file')]
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
%           analyze.stat.fit_spike_count_glme,
%           analyze.stat.surf_partial_dependence

% % Parse input parameters % %
pars = struct;
pars.BehaviorEpoch = [-450 150];
pars.DataVars = {...
   'Group','AnimalID','BlockID','Alignment',...
   'PostOpDay','Area','ProbeID','ChannelID',...
   'Duration' ...
   };
pars.DispersionFlag = true;
pars.Distribution = "Poisson";
pars.DummyVarCoding = "effects";
pars.FitMethod = "Laplace";
pars.Link = "log";
[pars.MinDuration,pars.MaxDuration] = defaults.complete_analyses('min_duration','max_duration');
pars.MaxRate = 300; % Spikes/sec
pars.MinRate = 2.5; % Spikes/sec
pars.Model = "Spikes~Group*Area*Alignment+(1+SupportLimbMovement|ChannelID:Day)+(1+Duration|AnimalID)";
pars.PelletPresent = "Present";
pars.PreEpoch = [-1350 -750];
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

% Reduce to only trials with the pellet
r = analyze.slice(R,...
   'PelletPresent',pars.PelletPresent,...
   'Outcome','Successful');

% Get relative sample times for each rate bin
t = r.Properties.UserData.t;
iEpoch = (t >= pars.BehaviorEpoch(1)) & (t <= pars.BehaviorEpoch(2));
iPreEpoch = (t >= pars.PreEpoch(1)) & (t <= pars.PreEpoch(2));
tt = t(iEpoch);
dt = (range(tt)+mode(diff(t)))*1e-3; % Each time is the bin center; account for "widths"

% Create new variables to add: Spikes (response); N (weights; total spikes)
Spikes = sum(r.Rate(:,iEpoch),2);
PreMovementSpikes = sum(r.Rate(:,iPreEpoch),2);
N = sum(r.Rate,2);
Day = ordinal(r.PostOpDay);
SupportLimbMovement = categorical(~isnan(r.Support)+1,[1 2],{'Absent','Present'});

% Create data table for statistics
newVars = table(Day,SupportLimbMovement,Spikes,PreMovementSpikes,N);
newVars.Properties.VariableUnits = ...
   {'days','','count','count','total count'};
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

% Fit generalized linear mixed effects model for Poisson distributed
% response variable with a log-link function
if pars.Verbose
   fprintf(1,'\n\t==============================================\n');
   fprintf(1,...
      'GLME: <strong>All</strong> (successful) motor events\n');
   fprintf(1,...
      ['\t->\tFor spikes occurring <strong>%5.1f-ms</strong>' ...
      ' to <strong>%5.1f-ms</strong> relative to given event...'],...
      pars.BehaviorEpoch(1),pars.BehaviorEpoch(2));
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