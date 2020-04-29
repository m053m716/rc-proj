function y = doSmoothOnly(x,fs)
%DOSMOOTHONLY  Static function to apply "smoothing" (lowpass filter)
%
%  y = block.doSmoothOnly(x,fs);
%
%  x  -- Data to smooth
%  fs -- Sample rate of `x`
%
%  y  -- Smoothed output data
%
%  Uses `defaults.block('lpf_order','lpf_fc')`

[filter_order,cutoff_freq] = defaults.block('lpf_order','lpf_fc');
if nargin < 2
   fs = defaults.block('fs');
end
if ~isnan(cutoff_freq)
   [b,a] = butter(filter_order,cutoff_freq/(fs/2),'low');
end

mu = mean(x,1).';

if isnan(cutoff_freq)
   y = mu.';
else
   y = filtfilt(b,a,mu).';
end
end