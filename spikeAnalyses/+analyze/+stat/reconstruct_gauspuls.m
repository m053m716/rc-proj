function [r_hat,err] = reconstruct_gauspuls(rate,t,p,doOffsetAndScaling)
%RECONSTRUCT_GAUSPULS Returns reconstructed Gaussian pulse modulated oscillation
%
%  r_hat = analyze.stat.reconstruct_gauspuls(r,t,p,doOffsetAndScaling);
%  [r_hat,err] = analyze.stat.reconstruct_gauspuls(r,t,p,doOffsetAndScaling);
%
% Inputs
%  rate - Rate for a single trial
%  t    - Times corresponding to columns of `r` (sec)
%  p    - Parameters array ['tau','sigma','omega']
%  doOffsetAndScaling - True: uses `r` to compute average (bias) offset and
%                             scaling to maximum deviation; 
%                       False: does not fit bias or scale
%
% Output
%  r_hat - Reconstructed Gaussian pulse modulated oscillation 
%  err   - Sum of squared error terms for reconstructed trajectory
%
% See also: analyze.stat.fit_gauspuls, analyze.stat.get_fitted_table,
%           gauspuls

if doOffsetAndScaling
   b = median(rate);
   a = (rate - b)/t;
   detrended_rate = rate - (a.*t + b);
   [~,iMax] = max(abs(detrended_rate));
   r_hat = gpuls(t - p(1),p(3),p(2))*(detrended_rate(iMax)) + (a.*t + b);
   err = sum((rate - r_hat).^2);
else
   r_hat = gpuls(t - p(1),p(3),p(2));
   err = nan;
end

   % Helper function based on `gauspuls` built-in with less error checks
   function yc = gpuls(t,fc,bw)
      %GPULS Local function based on `gauspuls` with less error-checks
      %
      %  yc = gpuls(t,fc,bw);
      %
      % Inputs
      %  t  - Time vector
      %  fc - Center frequency for oscillation
      %  bw - Bandwidth multiplier for Gaussian enevelope
      %
      % Output
      %  yc - "Gaussian-modulated" oscillatory pulse amplitudes for each
      %        `t` value
      
      % Static default (-6 dB from peak to define pulse bandwidth)
      bwr = -6;
      
      % Compute reference level (fraction of max peak)
      r = 10.^(bwr/20);      
      
      % Compute fv (variance; note that mean is fc)
      fv = -bw*bw*fc*fc/(8*log(r)); 
      
      % Determine corresponding time-domain parameters:
      tv = 1/(4*pi*pi*fv);  % variance is tv, mean is 0
      
      % Compute time-domain pulse envelope, normalized by sqrt(2*pi*tv):
      ye = exp(-t.*t/(2*tv));    
      
      % Modulate envelope to form in-phase and quadrature components:
      yc = ye .* cospi(2*fc*t);    % In-phase
   end
end