function r = addCountVariables(r,varargin)
%ADDCOUNTVARIABLES Adds count variables to data table in `r`
%
%  r = analyze.trials.addCountVariables(r,'Name',value,...);
%
% Inputs
%  r - Table of corrected behavior spike counts (see
%        analyze.behavior.fixBehaviorData)
%  varargin - (Optional) 'Name',value parameter pairs
%
% Output
%  r - Same as input but with variables:
%     'N_Total', 'N_Pre_Grasp', 'N_Grasp', 'N_Reach', 'N_Retract'
%
% These are used to conduct single-channel GLME statistical tests.
% See also: analyze.stat, analyze.behavior, unit_learning_stats

pars = struct;
pars.Pre_Epoch_Duration = [-1350 -750]; % ms
pars.Grasp_Epoch_Duration = [-150 150]; % ms
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

ts = r.Properties.UserData.t;
tsec = ts.*1e-3;

% Compute "baseline" or "pre-grasp" ("pre-behavior") spike counts
r.N_Pre_Grasp = arrayfun(...
   @(x)analyze.trials.countSpikes(x{1},...
      ts,pars.Pre_Epoch_Duration(1),pars.Pre_Epoch_Duration(2)),...
   mat2cell(r.Rate,ones(1,size(r,1)),numel(ts)));
% Compute number of spikes during Reach epoch.
[r.N_Reach,r.Reach_Epoch_Duration] = arrayfun(...
   @(x,tReach,tGrasp)analyze.trials.countSpikes(x{1},tsec,tReach-tGrasp,0),...
      mat2cell(r.Rate,ones(1,size(r,1)),numel(ts)), ...
   r.Reach,r.Grasp);
% Compute number of spikes during Grasp epoch.
r.N_Grasp = arrayfun(...
   @(x)analyze.trials.countSpikes(x{1},...
      ts,pars.Grasp_Epoch_Duration(1),pars.Grasp_Epoch_Duration(2)),...
   mat2cell(r.Rate,ones(1,size(r,1)),numel(ts)));
% Compute number of spikes during Retract epoch.
[r.N_Retract,r.Retract_Epoch_Duration] = arrayfun(...
   @(x,tGrasp,tComplete)analyze.trials.countSpikes(x{1},tsec,0,tComplete-tGrasp),...
      mat2cell(r.Rate,ones(1,size(r,1)),numel(ts)), ...
   r.Grasp,r.Complete);

% Compute total number of spikes in trials.
r.N_Total = nansum(r.Rate,2);

% Associate two fixed-duration epoch lengths for rate calculations
r.Properties.UserData.Pre_Epoch_Duration = pars.Pre_Epoch_Duration;
r.Properties.UserData.Grasp_Epoch_Duration = pars.Grasp_Epoch_Duration;
r.Properties.UserData.Type = 'SpikeCounts';

end