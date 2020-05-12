function batchSavePawSeries(tankPath,vidPath,varargin)
%% BATCHSAVEPAWSERIES   Extract paw probability time-series and save it
%
%  BATCHSAVEPAWSERIES;
%  BATCHSAVEPAWSERIES(tankPath);
%  BATCHSAVEPAWSERIES(tankPath,vidPath);
%  BATCHSAVEPAWSERIES(___,'NAME',value,...);
%
% By: Max Murphy  v1.0   08/31/2018    Original version (R2017b)

%% DEFAULTS
OUT_ID = '_Paw.mat';
IN_ID = '*.csv';

VID_FS = 30000/1001;

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% PARSE INPUT
if nargin < 2
   vidPath = 'K:\Rat\Video\BilateralReach\RC';
end

if nargin < 1
   tankPath = 'P:\Extracted_Data_To_Move\Rat\TDTRat';
end

%% LOOP THROUGH EVERYTHING IN TANK
% Try and find matching DLC file 
fs = VID_FS;
A = dir(fullfile(tankPath,'R*'));
tic;
h = waitbar(0, 'Please wait, batch saving paw digital stream...');
for iA = 1:numel(A)
   B = dir(fullfile(tankPath,A(iA).name,[A(iA).name '*']));
   for iB = 1:numel(B)
      name = B(iB).name;
      save_loc = fullfile(B(iB).folder,B(iB).name,[B(iB).name '_Digital']);
      
      C = dir(fullfile(vidPath,[name IN_ID]));
      if ~isempty(C)
         
         savePawSeries(fullfile(vidPath,C(1).name),...
            fs,...
            fullfile(save_loc,[name OUT_ID]));
      end      
   end
   waitbar(iA/numel(A));
end
delete(h);
toc;


end