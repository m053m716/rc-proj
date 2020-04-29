function y = doSmoothNorm(x,idx)
%DOSMOOTHNORM  Applies rate smoothing & normalization
%
% Static function to apply "smoothing" (lowpass filter) and
% normalization (square-root transform & mean-subtraction)

if nargin < 2
   idx = defaults.block('pre_trial_norm_ds');
end

% % This is skipped because lpf_fc == nan % %
filter_order = defaults.block('lpf_order');
fs = defaults.block('fs');
cutoff_freq = defaults.block('lpf_fc');
if ~isnan(cutoff_freq)
   [b,a] = butter(filter_order,cutoff_freq/(fs/2),'low');
end

%          z = sqrt(abs(x)) .* sign(x); % This is removed because already
%          done in the rate estimation step
z = x - mean(x(:,idx,:),2);
if isnan(cutoff_freq)
   y = z;
else
   y = nan(size(z));
   for iZ = 1:size(z,3)
      for iT = 1:size(z,1)
         y(iT,:,iZ) = filtfilt(b,a,z(iT,:,iZ));
      end
   end
end
end