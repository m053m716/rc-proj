function varargout = getPredictionMask(tCheck,times,n)
%GETPREDICTIONMASK Return mask for matched samples for fitting prediction
%
%  [T0,...,T_N] = analyze.dynamics.getPredictionMask(iTimes,n);
%
%  [T0,...,T_N] = analyze.dynamics.getPredictionMask(tCheck,times,n);
%
% Inputs
%  iTimes - Logical vector of times to include (per trial; i.e. for a 
%              single trial)
%  n      - Number of trials total
%
%  -- Or --
%
%  tCheck - Times to check (i.e. vector of relative times for each sample 
%              of data in a single trial)
%  times  - Times to include in analyses (If not given, uses all of tCheck)
%  n      - Number of trials (i.e. number of times to replicate output
%              mask)
%
% Output
%  varargout - Masks for up to N lagged samples
%
% See also: kal, analyze.dynamics, analyze.jPCA, kal.kInit

if nargin < 2
   times = tCheck;
end

if nargin < 3
   if isscalar(times)
      n = times;
      iTimes = tCheck;
   else
      n = 1;
      iTimes = ismember(tCheck,times);
   end
else
   iTimes = ismember(tCheck,times);
end

N = nargout;
varargout = cell(1,N);
iArgout = cell(1,N);

iArgout{1} = find(iTimes,N-1,'last');
iArgout{N} = find(iTimes,N-1,'first');

for iArg = 2:(N-1)
   iArgout{iArg} = [find(iTimes,iArg-1,'first'); ...
                    find(iTimes,N-iArg,'last')];
end

for iArg = 1:N
   varargout{iArg} = iTimes;
   varargout{iArg}(iArgout{iArg}) = false;
   varargout{iArg} = repmat(varargout{iArg},n,1);
end


end