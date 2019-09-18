function rate = getLinearRates(data,varargin)
%% GETLINEARRATES  Use linear method to get smooth instant rate
%
%  rate = GETLINEARRATES(data);
%  rate = GETLINEARRATES(data,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%   data       :     Tensor matrix for spike data of a given recording
%                    block. Dimensions are: nTrials x nTimebins x nChannels 
%
%  varargin    :     (Optional) 'NAME', value input argument pairs.
%
%  --------
%   OUTPUT
%  --------
%    rate      :     Tensor with same dimensions as data, but with data
%                    smoothed to represent normalized firing rate.
%
% By: Max Murphy  v1.0  07/30/2018  Original version (R2017b)

%% DEFAULTS
KERNEL_W = 0.020; % desired smoothing kernel width (seconds)
BIN = 0.001;   % histogram bin width (seconds)
TYPE = 'tri';

T = nan;
NORM = nan;

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% PRE-ALLOCATE AND DO MINOR CALCULATIONS
bw = round(KERNEL_W / BIN);
% Check whether to do normalization
if isnan(T(1)) || isnan(NORM(1)) % must both be non-NaN to do normalization
   doNorm = false;
else
   doNorm = true;
   normVec = find(T <= (-NORM));
   normVec = normVec(bw:end); % remove the "edge-affected" parts
end
rate = nan(size(data));

%% LOOP THROUGH EACH CHANNEL AND SMOOTH ROWS (TRIALS)
for ii = 1:size(data,3)
   rate(:,:,ii) = fastsmooth(data(:,:,ii),bw,TYPE,1,1);
   if doNorm % Normalizing assumes stationarity over period prior to "N_PRE"
      sq = sqrt(abs(rate(:,:,ii)));
      mu = mean(sq(:,normVec),1);
      sd = std(mu);
      
      rate(:,:,ii) = (sq - mean(mu))/sd;
   end
end


end