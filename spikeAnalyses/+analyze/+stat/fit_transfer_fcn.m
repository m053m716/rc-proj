function [tau,sigma,omega,a,b,w] = fit_transfer_fcn(Rate,t,param_grid)
%FIT_TRANSFER_FCN Get transfer function parameters and observation weights
%
%  [tau,sigma,omega,a,b,w] = analyze.stat.fit_transfer_fcn(Rate,t);
%  [tau,sigma,omega,a,b,w] = analyze.stat.fit_transfer_fcn(Rate,t,param_grid);
%
%  -- Motivation -- 
%
%  We wish to reduce the data in data matrix `Rate`, for which element 
%  <i,j> (Rate_ij) represents the spike rate at time-index i during the 
%  j-th trial (row, in reference to the main data table).
%
%  To describe each row more compactly, we can represent the transient
%  "oscillations" that are typically present during event-modulation on or 
%  near the event of interest using a combination of two functions: a 
%  "Gaussian envelope" f(t) and an oscillation g(t). 
%
%  The envelope f(t), is defined as
%
%                          exp(-((t-tau_i)/sigma_i)^2/pi) 
%    f(t|tau_i,sigma_i) = --------------------------------        (1)
%                                sigma_i*sqrt(2*pi)
%
%  represents the gaussian equation with mean parameter `tau` and standard
%  deviation parameter `sigma`, as well as an oscillation function g(t),
%  where
%
%     g(t|omega_i,phi_i) = cos(omega_i*t)                         (2)
%
%  Note: Equation 2 could contain a phase offset component but to reduce
%        number of parameters estimated during the optimization process, it
%        is not estimated and instead incorporated into `tau` parameter,
%        which is combined into part the gauspuls algorithm.
%
%  Then analyze.stat.fit_transfer_fcn recovers the "transfer function"
%  parameters which characterize the Gaussian-modulated oscillator
%  reprsented as h(t), where
%
%     h(t) = conv(g(t),f(t));                                     (3)
%
%  Rate(t) ~ f(t) * g(t);
%
% Inputs
%  Rate - Spike rate for a given trial or multiple trials (rows); columns
%         are rate samples (time)
%  t    - Times (ms) corresponding to columns or Rate. Should only be a 
%         [1 x k] row vector for k columns (time-samples) of Rate
%  param_grid - See defaults.stat for default values; this is a struct with
%               fields to recover initial grid for `tau`, `sigma`, and
%               `omega` parameters.
%
% Output
%  tau   - Time-delay for "envelope" center on damping of oscillation
%  sigma - Width of "envelope" for damping of oscillation
%  omega - Frequency of oscillation
%  a     - Linear time-dependent slope of trial, in the form of:
%           rate = a*time + b
%  b     - Linear offset constant, in this case, the trial-median rate.
%  w     - Weight, where a larger weight corresponds to larger error,
%           indicating that the model term should contribute less to the
%           statistical model cost function
%
% See also: analyze.stat, analyze.stat.get_fitted_table,
%           analyze.stat.fit_gaus_puls, analyze.stat.reconstruct_gauspuls

if nargin < 3
   [param_grid,A,B,Aeq,Beq,nonlcon,nIteration,dispStyle] = defaults.stat(...
      'param_grid','gaus_A','gaus_b','gaus_Aeq','gaus_beq',...
      'gaus_nonlcon','gaus_niter','gaus_dispstyle');
else
   [A,B,Aeq,Beq,nonlcon,nIteration,dispStyle] = defaults.stat(...
      'gaus_A','gaus_b','gaus_Aeq','gaus_beq','gaus_nonlcon',...
      'gaus_niter','gaus_dispstyle');
end

% Iterate for each row of Rate matrix %
nTrial = size(Rate,1);
if nTrial > 1
   % Initialize all variables
   [tau,sigma,omega,a,b,w] = initOutputs(nTrial);
   pct = 0;
   warning('off');
   fprintf(1,'Fitting %d ODE Systems...%03d%%\n',nTrial,pct);
   for iTrial = 1:nTrial
      [tau(iTrial),sigma(iTrial),omega(iTrial),a(iTrial),b(iTrial),w(iTrial)] = ...
         analyze.stat.fit_transfer_fcn(Rate(iTrial,:),t,param_grid);
      newPct = round(iTrial/nTrial * 100);
      if (newPct - pct) > 0
         pct = newPct;
         fprintf(1,'\b\b\b\b\b%03d%%\n',pct);
      end
   end
   warning('on');
   return;   
end

% % First, check validity of data: if no spikes, then indicate that % %
% If there were no spikes on this trial, return all parameters as nan %
if ~any(abs(Rate) > eps)
   [tau,sigma,omega,a,b,w] = initOutputs(1);
   return;
else
   % Compute linear bias and subtract it
   b = median(Rate);
   a = (Rate - b)/t;
   Detrended_Rate = Rate - (a.*t + b);
   [~,iMax] = max(abs(Detrended_Rate));
   Scaled_Detrended_Rate = Detrended_Rate ./ Detrended_Rate(iMax);
end

% For valid trials, first step is to generate mesh on parameter space %
nTauGrid = numel(param_grid.tau);
nSigmaGrid = numel(param_grid.sigma);
nOmegaGrid = numel(param_grid.omega);
F = nan(nTauGrid,nSigmaGrid,nOmegaGrid); % Parameter-space tensor
for iTau = 1:nTauGrid
   for iSigma = 1:nSigmaGrid
      for iOmega = 1:nOmegaGrid
         p = [param_grid.tau(iTau),...
              param_grid.sigma(iSigma),...
              param_grid.omega(iOmega)];
         F(iTau,iSigma,iOmega) = analyze.stat.fit_gauspuls(...
            Scaled_Detrended_Rate,t,p);
      end
   end
end

% % Make use of those in the optimization procedure % %
% First, initialize the parameters array that is to be optimized %
p0 = get_initial_params(F,param_grid);

% % Run the optimization % %
lb = [min(param_grid.tau), min(param_grid.sigma), min(param_grid.omega)];
ub = [max(param_grid.tau), max(param_grid.sigma), max(param_grid.omega)];
% fun = @(p)analyze.stat.fit_gauspuls(Rate,t,p,G);
fun = @(p)analyze.stat.fit_gauspuls(Scaled_Detrended_Rate,t,p);
options = optimoptions('fmincon',...
   'Display',dispStyle,...
   'SpecifyObjectiveGradient',false);

P  = nan(nIteration,3);
fval = nan(nIteration,1);
for iIter = 1:nIteration % Jitters each iteration starting point a bit
   [p,fval(iIter)] = fmincon(fun,p0,A,B,Aeq,Beq,lb,ub,nonlcon,options);
   P(iIter,:) = p; % Store recovered parameters
   % Jitter the next initial guess based on recovered parameters
   p0 = [p(1) + param_grid.noise.tau*randn(1),...
         p(2) + param_grid.noise.sigma*randn(1),...
         p(3) + param_grid.noise.omega*randn(1)];
end
[~,iBest] = min(fval);
p = P(iBest,:); % Assign best iteration version

% % Return the optimized output % %
tau   = p(1);
sigma = p(2);
omega = p(3);

% % Return the observation weight % %
[~,w] = analyze.stat.reconstruct_gauspuls(Rate,t,p,true);
   
   % Helper function to initialize optimizer
   function p0 = get_initial_params(F,param_grid)
      %GET_INITIAL_PARAMS Return initial parameters guess for fmincon
      %
      %  p0 = get_initial_params(F,param_grid);
      %
      % Inputs
      %  F          - Tensor of values from parameter grid test
      %  param_grid - Struct with fields for `tau`, `sigma` and `omega`
      %
      % Output
      %  p0         - Initial parameter guess
      
      [F_red,iOmegaStart] = min(F,[],3);
      [F_red,iSigmaStart] = min(F_red,[],2);
      sz = size(iOmegaStart);
      iOmegaStart = iOmegaStart(sub2ind(sz,(1:sz(1))',iSigmaStart));
      [~,iTauStart] = min(F_red,[],1);
      iSigmaStart = iSigmaStart(iTauStart);
      iOmegaStart = iOmegaStart(iTauStart);
      p0 = [param_grid.tau(iTauStart),...
           param_grid.sigma(iSigmaStart),...
           param_grid.omega(iOmegaStart)];
   end

   % Helper function to initialize outputs
   function varargout = initOutputs(nTrial)
      %INITOUTPUTS Initialize the requested # of outputs as NaN
      %
      %  [out1,...,outk] = initOutputs(nTrial);
      %
      % Inputs
      %  nTrial - Number of trials (rows of table)
      %
      % Output
      %  As many output variables as requested, as [nTrial x 1] column
      %  vectors of NaN values
      
      % Iterate for each requested output returning same size vector:
      varargout = cell(1,nargout);
      for iV = 1:numel(varargout)
         varargout{iV} = nan(nTrial,1);
      end
   end   
end