function batchSaveBeamSeries(tankPath,varargin)
%% BATCHSAVEBEAMSERIES   Reduce beam break stream files to 1 file only
%
%  BATCHSAVEBEAMSERIES ;
%  BATCHSAVEBEAMSERIES (tankPath);
%  BATCHSAVEBEAMSERIES (tankPath,'NAME',value,...);
%
% By: Max Murphy  v1.0   08/31/2018    Original version (R2017b)

%% DEFAULTS
OUT_ID = '_Beam.mat';
IN_ID = '*Bea2*.mat';

RM_FILE = true;

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
      
      C = dir(fullfile(save_loc,[B(iB).name IN_ID]));
      if isempty(C)
         continue;
      end
      x = cell(numel(C),1);
      r = nan(numel(C),1);
      for iC = 1:numel(C)
         x{iC} = load(fullfile(C(iC).folder,C(iC).name));
         r(iC) = rms(x{iC}.data);        
      end
      [~,idx] = max(r);
      x = x{idx};
      save(fullfile(C(idx).folder,[name OUT_ID]),'-struct','x');
      if RM_FILE
         for iC = 1:numel(C)
            delete(fullfile(C(iC).folder,C(iC).name));
         end
      end
   end
   waitbar(iA/numel(A));
end
delete(h);
toc;


end