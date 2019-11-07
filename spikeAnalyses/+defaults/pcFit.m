function param = pcFit(name,varargin)
%% PCFIT   param = defaults.pcFit('paramName');

%%
p = struct;
o = optimoptions('fmincon');
% o.Algorithm = 'trust-region-reflective';
% o.CheckGradients = true;
o.CheckGradients = false;
o.ConstraintTolerance = 1e-4;
o.Display = 'notify';
% o.Display = 'final';
o.FiniteDifferenceType = 'central';
o.MaxFunctionEvaluations = 500000;
o.MaxIterations = 100000;
o.ObjectiveLimit = -1e20;
o.OptimalityTolerance = 1e-4;
o.SpecifyObjectiveGradient = true;
o.StepTolerance = 1e-15;
if nargin > 1
   for iV = 1:2:numel(varargin)
      o.(varargin{iV}) = varargin{iV+1};
   end
end
p.optim_opts = o;

p.threshold_explained = defaults.xPCA('latent_threshold')*100;

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