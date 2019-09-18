function Data = formatWarped(Y,times)
%% JPCA.FORMATWARPED Convert "warped" rate data
%
%  Data = format(Y,times)
%
%  --------
%   INPUTS
%  --------
%     Y        :     nTrials x nSamples x nChannels matrix of spike rates.
%                    --> Has already been normalized, decimated, filtered..
%
%   times      :     Times vector corresponding to samples of Y (ms)
%                    --> Cell array
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
% By: Max Murphy  v1.0  2019-06-16  Original version (R2017a)

%% CONVERT TO CELL ARRAY BY TRIAL
N = size(Y,1);
Data = struct('A',cell(N,1),'times',cell(N,1));

for ii = 1:size(Y,1)
   Data(ii).A = squeeze(Y(ii,:,:));
   Data(ii).times = times(ii,:).';
end





end