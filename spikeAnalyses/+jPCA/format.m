function Data = format(X,times,b,a,jpca_decimation_factor,jpca_start_stop_times,do_pre_trial_norm)
%% JPCA.FORMAT Convert data to jPCA format (and default parameters struct)
%
%  Data = format(X,times,b,a,jpca_decimation_factor,jpca_start_stop_times)
%
%  --------
%   INPUTS
%  --------
%     X        :     nTrials x nSamples x nChannels matrix of spike rates.
%
%   times      :     Times vector corresponding to samples of X (ms)
%
%     b        :     Numerator coefficients for low pass filter (NaN for no
%                       filter).
%
%     a        :     Denominator coefficients for low pass filter (NaN for
%                       no filter).
%
%  jpca_decimation_factor     :     (Scalar int) decimation factor to
%                                      downsample nSamples of X for
%                                      performing jPCA analyses. This
%                                      speeds things up, typical value is
%                                      10 (to go from 1ms to 10ms sample
%                                            period).
%
%  jpca_start_stop_times      :     Start and stop times to use for
%                                      subsequent recovery of jPCA
%                                      coefficients. Probably good to set
%                                      these somewhat shorter than the
%                                      start and stop samples of the full
%                                      trial period, particularly if
%                                      applying low pass filter, to avoid
%                                      edge effects from the filter.
%
%  --------
%   OUTPUT
%  --------
%    Data         :     Array struct that is dimensions 1 x nTrials. Each
%                          element corresponds to a trial (condition).
%                          Contains the fields 'A' which is a matrix in
%                          which columns correspond to channels and rows
%                          correspond to samples, and 't', which is a
%                          vector corresponding to times for rows of 'A'
%  
% By: Max Murphy  v1.0  2019-06-13  Original version (R2017a)


%% PARSE INPUT
if nargin < 7
   do_pre_trial_norm = false;
end

if nargin < 6
   jpca_start_stop_times = nan;
end

if nargin < 5
   jpca_decimation_factor = nan;
end

if nargin < 4
   a = defaults.jPCA('a');
end

if nargin < 3
   b = defaults.jPCA('b');
end

%% OPTIONALLY APPLY FILTERING
if do_pre_trial_norm
   pre_trial_norm = defaults.block('pre_trial_norm');
   X = sqrt(abs(X));
   X = (X - mean(X(:,pre_trial_norm,:),2))./(std(X(:,pre_trial_norm,:),[],2)+1);
end

if isnan(b(1)) || isnan(a(1)) % If filter coefficients not present, skip filter
   Y = X;
else % Otherwise apply filter
   if ~isnan(jpca_decimation_factor)
      if ~isnan(jpca_start_stop_times(1))
         [~,iStart] = min(abs(times - jpca_start_stop_times(1)));
         [~,iStop] = min(abs(times - jpca_start_stop_times(2)));
         X = X(:,iStart:iStop,:);
         Y = nan(size(X,1),ceil(size(X,2)/jpca_decimation_factor),size(X,3));
         times = linspace(times(iStart),times(iStop),size(Y,2));
         for iCh = 1:size(X,3)
            for ik = 1:size(X,1)
               Y(ik,:,iCh) = decimate(filtfilt(b,a,X(ik,:,iCh)),jpca_decimation_factor);
            end
         end
      else
         Y = nan(size(X,1),ceil(size(X,2)/jpca_decimation_factor),size(X,3));
         for iCh = 1:size(X,3)
            for ik = 1:size(X,1)
               Y(ik,:,iCh) = decimate(filtfilt(b,a,X(ik,:,iCh)),jpca_decimation_factor);
            end
         end
         times = linspace(times(1),times(end),size(Y,2));
      end
   else
      Y = nan(size(X));
      for iCh = 1:size(X,3)
         Y(:,:,iCh) = filtfilt(b,a,X(:,:,iCh).').';
      end
   end
end




%% CONVERT TO CELL ARRAY BY TRIAL
A = cell(size(Y,1),1);
for ii = 1:size(Y,1)
   A{ii} = nan(size(Y,2),size(Y,3));
   for iCh = 1:size(Y,3)
      A{ii}(:,iCh) = Y(ii,:,iCh);
   end
end

Data = struct('A',A,'times',times);



end