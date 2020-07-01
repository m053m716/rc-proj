function [mu,w] = fit_vdp_ode(Rate,t)
%FIT_VDP_ODE Returns `mu` for Van der Pol oscillator & weight for GOF
%
%  [mu,w] = analyze.stat.fit_vdp_ode(Rate,t);
%
% Inputs
%  Rate - Spike rate for a given trial or multiple trials (rows); columns
%         are rate samples (time)
%  t    - Times (ms) corresponding to columns or Rate. Should only be a 
%         [1 x k] row vector for k columns (time-samples) of Rate
% Output
%  mu   - From VDP oscillator ODE: [x''(t) - mu(1-x^2)x'(t) + x = 0]
%  w    - Weight, where a larger weight corresponds to larger error,
%           indicating that the model term should contribute less to the
%           statistical model cost function

nTrial = size(Rate,1);
if nTrial > 1
   mu = nan(nTrial,1);
   w = nan(nTrial,1);
   pct = 0;
   fprintf(1,'Fitting %d ODE Systems...%03d%%\n',nTrial,pct);
   for iTrial = 1:nTrial
      [mu,w] = analyze.stat.fit_vdp_ode(Rate(iTrial,:),t);
      newPct = round(iTrial/nTrial * 100);
      if (newPct - pct) > 0
         pct = newPct;
         fprintf(1,'\b\b\b\b\b%03d%%\n',pct);
      end
   end
   return;   
end

% % Define ODE system, `M` % % 
M = @(t,Y,mu)... % function that will be used in solver/optimization
   [...                           % Note: no derivative in RHS
   Y(2);                        ... x'(t) = y(t)
   mu*(1 - Y(1)^2)*Y(2) - Y(1)  ... y'(t) = mu*(1-x^2)*y - x
   ];  
SS = sum(Rate(:).^2); % Define initial "Cost" as Rate SS

% % Ultimately, we wish to recover mu from best-fit system % %


   % Local "helper" function: run ODE solver
   function [f,g,h] =vdp_ode(mu,m,rate,t)
      %VDP_ODE Helper function to run ODE solver in fmincon
      %
      %  [f,g,h] = vdp_ode(mu,m,rate,tspan);
      %
      %  Example:
      %  >> fun = @(mu)vdp_ode(mu,M,Rate,t); % [Rate,t] from main inputs
      %  >> mu = fmincon(@fun,mu_0,A,b); % For initial guess mu_0
      %
      % Inputs
      %  mu    - Damping coefficient in the Van der Pol (VDP) oscillator
      %  m     - Function handle describing system of equations
      %  rate  - Trial spike rates
      %  tspan - Times corresponding to columns of rate
      %
      % Output
      %  f     - scalar cost function
      %  g     - derivative of `f` with respect to `mu`
      %  h     - second-derivative of `f` with respect to `mu`
      
      tspan = [t(1),t(end)];
      y0 = [0,rate(1)];
      vdpSys = @(t,Y)m(t,Y,mu); % Incorporate `mu` to system
      sol = ode45(@vdpSys,tspan,y0);
      rate_hat = deval(sol,t); % Return rate estimate using recovered mu
      f = sum((rate_hat - rate).^2); % Minimize this error
      
   end

end