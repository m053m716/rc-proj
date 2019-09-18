function [block,F,surgDict] = refreshInfo(varargin)
%% REFRESHINFO    Refresh info file in main TANK for RC analyses
%
%  [block,F,surgDict] = REFRESHINFO;
%  [block,F,surgDict] = REFRESHINFO('NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%  varargin       :     (Optional) 'NAME', value input argument pairs.
%                       -> 'TANKPATH' (string path to the container for
%                             animal folders that contain recording block 
%                             folders)
%
%                       -> 'BLOCK_ID' (def: '_2*') gets all the block names
%                          without picking up "extra" stuff that is kept at
%                          animal folder level, such as "RC-02_analyses"
%                          etc
%
%                       -> 'INFONAME' (def: 'info.mat') name of file that
%                          contains the variables output by this function.
%                                      
%                       -> 'ANIMAL_ID' (def: '_2*') gets all the rat names
%                          without picking up "extra" stuff that is kept at
%                          tank folder level, such as "info.mat" etc.
%
%  --------
%   OUTPUT
%  --------
%    block        :     nTotalRecordings x 1 struct array that contains
%                          folder name information for all BLOCKS in the
%                          tank.
%
%      F          :     nAnimal x 2 cell array: first column is cell array
%                          of animal names; second column is cell array of 
%                          structs similar to the block output, but only
%                          for the corresponding animal of that array
%                          element's row (matching the animal name from
%                          column 1 array).
%
%   surgDict      :     "Dict" of surgical datenums in order to easily
%                          compute the post-op day given the block naming
%                          convention.
%
% By: Max Murphy  v1.0  12/29/2018  Original version (R2017a)

%% DEFAULTS
TANKPATH = 'P:\Extracted_Data_To_Move\Rat\TDTRat';
BLOCK_ID = '_2*';
INFONAME = 'info.mat';
ANIMAL_ID = 'RC-*';
NAME_DELIM = '_';
META_NOTES = 'notes.txt';

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

addpath('libs');

%% LOAD "SURGDICT" FROM CURRENT INFO (IF IT EXISTS)
fname = fullfile(TANKPATH,INFONAME);
if exist(fname,'file')==0
   warning('No INFO file found (%s does not exist).',fname);
   disp('Building from empty SURGDICT struct.');
   surgDict = struct;
else
   load(fname,'surgDict');
end

%% LOOP ON ANIMAL FOLDERS
A = dir(fullfile(TANKPATH,ANIMAL_ID));
numAnimal = numel(A);
F = cell(numAnimal,2);
block = [];
for iA = 1:numAnimal
   ratName = strsplit(A(iA).name,NAME_DELIM);
   ratName = ratName{1};
   F{iA,1} = ratName;
   tmp = dir(fullfile(A(iA).folder,A(iA).name,[A(iA).name BLOCK_ID]));
   
   % Update surgical date, if not updated already
   r = strrep(ratName,'-','');
   if ~isfield(surgDict,r)
      meta = getMetadata(fullfile(A(iA).name,META_NOTES));
      if isfield(meta,'surg')
         surgDict.(r) = datenum(meta.surg,'yyyy-mm-dd');
      end
   end
   
   % Update other outputs
   F{iA,2} = tmp;
   block = [block; tmp]; %#ok<AGROW>
   
end

%% SAVE OUTPUTS AS WELL
save(fname,'block','F','surgDict','-v7.3');

end