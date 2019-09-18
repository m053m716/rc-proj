function moveAlignmentToIsilon(block,varargin)
%% MOVEALIGNMENTTOISILON   Move video alignment timestamp to Isilon BLOCK
%
%  MOVEALIGNMENTTOISILON(block);
%  MOVEALIGNMENTTOISILON(block,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%   block      :     Array struct of blocks (fields: 'folder', 'name') to
%                       have previously-aligned video timestamp exported
%                       from '_VideoScoredSuccesses.mat' file to separate
%                       file '_VideoAlignment.mat' in '_Digital' sub-folder
%                       of Isilon BLOCK.
%
%  --------
%   OUTPUT
%  --------
%  Take a single variable that is one time-stamp and put it in a different
%  file so that it conforms to the BLOCK format in use currently.
%
% By: Max Murphy  v1.0  12/29/2018  Original version (R2017a)

%% DEFAULTS
LOCAL_DIR = fullfile(pwd,'prev-scoring');
LOCAL_ID = '_VideoScoredSuccesses.mat';

TANK_PATH = 'P:\Extracted_Data_To_Move\Rat\TDTRat';
DIG_DIR = '_Digital';
OUT_ID = '_VideoAlignment.mat';

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% LOOP THROUGH EVERYTHING IN BLOCK ARRAY
fprintf('Transferring...%03g%%\n',0);
for iB = 1:numel(block)
   rat = block(iB).name(1:5);
   
   fname_in = fullfile(LOCAL_DIR,[block(iB).name LOCAL_ID]);
   if exist(fname_in,'file')==0
      warning('%s not found. Skipping.',fname_in);
      continue;
   end
   
   data = load(fname_in,'VideoStart');
   
   dir_out = fullfile(TANK_PATH,rat,block(iB).name,[block(iB).name DIG_DIR]);
   if exist(dir_out,'dir')==0
      warning('Invalid output path: %s',dir_out);
      fprintf('Transferring...%03g%%\n',floor(iB/numel(block)*100));
   else
      save(fullfile(dir_out,[block(iB).name OUT_ID]),'-struct','data');
   end
   fprintf('\b\b\b\b\b%03g%%\n',floor(iB/numel(block)*100));
end


end