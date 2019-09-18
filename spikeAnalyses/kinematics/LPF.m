function out = LPF(in,fc,fs,state_in)
%% LPF  Software estimate of hardware single-pole state low-pass filter
%
%  out = LPF(in);
%  out = LPF(in,fc);
%  out = LPF(in,fc,fs);
%
%  Example: If neural data sampled at 30 kSamples/sec, with desired cutoff
%           frequency of 300 Hz:
%
%           out = HPF(in,300,30000);
%
%  --------
%   INPUTS
%  --------
%     in    :     Input (raw) sample data.
%
%     fc    :     Desired cutoff frequency (Hz)
%
%     fs    :     Sampling frequency (Hz)
%
%  state_in :     Use this if filtering "chunks" - for a LPF, this should
%                 be the last element of "out." (If calling this filter on
%                 sequential chunks of data).
%
%  --------
%   OUTPUT
%  --------
%    out    :     Low-pass filtered sample data. The filter is essentially
%                 a single-pole butterworth high-pass filter realized using
%                 a hidden "state" variable. 
%
% By: Intan Technologies
% Modified by Max Murphy   07/24/2018 (Matlab R2017b)

%% DEFAULTS
FS = 200; % Default sample rate is 30 kSamples/sec
FC = 20;  % Default cutoff frequency

%% PARSE INPUT
switch nargin
   case 1
%       warning('No cutoff frequency given. Using default FC (%d Hz).',FC);
      fc = FC;
%       warning('No sample rate specified. Using default FS (%d Hz).',FS);
      fs = FS;
      outLPF = zeros(size(in));
      outLPF(1) = in(1);  
   case 2
%       warning('No sample rate specified. Using default FS (%d Hz).',FS);
      fs = FS;
      outLPF = zeros(size(in));
      outLPF(1) = in(1);  
   case 3
      outLPF = zeros(size(in));
      outLPF(1) = in(1);  
   case 4
      outLPF = zeros(size(in));
      outLPF(1) = state_in;
   otherwise
      error('Too many inputs. Check syntax.');
end

%% COMPUTE IIR FILTER COEFFICIENTS
A = exp(-(2*pi*fc)/fs);
B = 1 - A;

%% USE LOOP TO RUN STATE FILTER
if isnan(outLPF(1))
   outLPF(1) = 0;
end

k = 0;

for i = 2:length(in)
   if ~isnan(B*in(i-1))
      k = B*in(i-1);
   end
   outLPF(i) = (k + A*outLPF(i-1));
end

%% RETURN FILTERED OUTPUT AND FINAL STATE
% out = in - outLPF; % HPF
out = outLPF;

end
