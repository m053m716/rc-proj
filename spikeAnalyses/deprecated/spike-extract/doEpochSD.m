function b = doEpochSD(block,varargin)
%% DOEPOCHSD      Do spike detection within set epochs
%
%  b = DOEPOCHSD(block);
%  b = DOEPOCHSD(block,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%    block     :     Struct with folder and name fields for BLOCK folder.
%
%  varargin    :     (Optional) 'NAME', value input argument pairs.
%
%  --------
%   OUTPUT
%  --------
%     b        :     Name of block.
%
%  Do spike detection within set epochs, and exclude data everywhere else
%  so that detection doesn't get messed up by greater noise in non-behavior
%  periods.
%
% By: Max Murphy  v1.0  12/29/2018  Original version (R2017b)

%% DEFAULTS - Set the path of extracted data and whether to check for SD
TANK = 'P:\Extracted_Data_To_Move\Rat\TDTRat';
CHECK_FOR_SPIKES = true;
E_PRE = 2;  % seconds to keep before behavior
E_POST = 1; % seconds to keep after behavior
FS = 24414.0625; % sample rate of TDT system

SPK_FEAT = 'wav';       % features for clustering spikes
SPK_PKDETECT = 'sneo';  % peak-detection algorithm

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% ADD CORRECT PATHS
addpath('C:\MyRepos\shared\CPLtools\_SD');
addpath('C:\MyRepos\shared\CPLtools\_SD\APP_Code');
addpath('C:\MyRepos\shared\CPLtools\_SD\adhoc_detect');

% Otherwise, get the time stamps
fprintf('->\tGetting artifact times for %s.\n',block.name);
[ts,b,tFinal] = getRC_ts(block);

% Convert those time stamps to the appropriate "artifact" periods
art_samples = getRC_interTrial_Periods(ts,tFinal,...
   'E_PRE',E_PRE,...
   'E_POST',E_POST,...
   'FS',FS);

% Now, do spike detection
qSD('DIR',b,...
   'ARTIFACT',art_samples,...
   'FEAT',SPK_FEAT,...
   'PKDETECT',SPK_PKDETECT,...
   'DELETE_OLD_PATH',true);


end