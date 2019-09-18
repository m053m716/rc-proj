function batchExtractTrials(tankPath,varargin)
%% BATCHEXTRACTTRIALS   Reduce beam break stream files to 1 file only
%
%  BATCHEXTRACTTRIALS;
%  BATCHEXTRACTTRIALS(tankPath);
%  BATCHEXTRACTTRIALS(tankPath,'NAME',value,...);
%
% By: Max Murphy  v1.0   09/01/2018    Original version (R2017b)

%% DEFAULTS
PAW_ID = '_Paw.mat';
THRESH = 0.15;
DB = 0.25;

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% PARSE INPUT
if nargin < 1
   tankPath = 'P:\Extracted_Data_To_Move\Rat\TDTRat';
end

%% LOOP THROUGH EVERYTHING IN TANK
% Try and find matching DLC file 
A = dir(fullfile(tankPath,'R*'));
tic;
h = waitbar(0, 'Please wait, batch saving paw digital stream...');
for iA = 1:numel(A)
   B = dir(fullfile(tankPath,A(iA).name,[A(iA).name '*']));
   for iB = 1:numel(B)
      name = B(iB).name;
      save_loc = fullfile(B(iB).folder,B(iB).name,[B(iB).name '_Digital']);
      
      fname = fullfile(save_loc,[name PAW_ID]);
      extractTrials(fname);
   end
   waitbar(iA/numel(A));
end
delete(h);
toc;


end