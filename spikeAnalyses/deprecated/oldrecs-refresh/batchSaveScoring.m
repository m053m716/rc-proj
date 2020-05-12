function batchSaveScoring(block,varargin)
%% BATCHSAVESCORING  Re-saves scoring correctly to table format for old vid
%
%  BATCHSAVESCORING(block);
%  BATCHSAVESCORING(block,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%   block      :     Struct array that contains location of blocks that
%                       need to have old version of scoring re-saved.
%
%  varargin    :     (Optional) 'NAME', value input argument pairs.
%
%  --------
%   OUTPUT
%  --------
%  Saves [blockName _Scoring.mat] in the _Digital sub-folder of the BLOCK.
%  Contains behaviorData table, which has rows for each reach.
%
% By: Max Murphy  v1.0  12/29/2018  Original version (R2017a)

%% DEFAULTS
ORIG_SCORING = fullfile(pwd,'prev-scoring'); % path to original scoring
ORIG_ID = '_aligned.mat';

DIG_DIR = '_Digital';
SCORE_ID = '_Scoring.mat';

REPLACE_ID = '_OldScore.mat';

DATA_DIR = 'P:\Extracted_Data_To_Move\Rat\TDTRat';

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% LOOP THROUGH BLOCK AND SAVE OLD SCORING USING NEW CONVENTION
fprintf('Converting scoring...%03g%%\n',0);
for iB = 1:numel(block)
   alignFile = fullfile(ORIG_SCORING,[block(iB).name ORIG_ID]);
   if exist(alignFile,'file')==0
      warning('%s does not exist. Skipped.',alignFile);
      fprintf('\b\b\b\b\b%03g%%\n',floor(iB/numel(block)*100));
      continue;
   else
      in = load(alignFile,'other');
   end
   
   % Name the fields for clarity
   allGrasp = in.other.s;                    % s - "grasp"
   failGrasp = in.other.f;                   % f - "failed grasp"
   succGrasp = setdiff(allGrasp,failGrasp);  % ensure success ONLY
   reach = in.other.r;                       % r - "reach"
   support = in.other.b;                     % b - "both paws"
   
   behaviorData = parseBehaviorData(succGrasp,failGrasp,reach,support);
   [~,name,~] = fileparts(block(iB).folder);
   
   digDir = fullfile(DATA_DIR,name,block(iB).name,[block(iB).name DIG_DIR]);
   fname = fullfile(digDir,[block(iB).name SCORE_ID]);
   rname = fullfile(digDir,[block(iB).name REPLACE_ID]);
   
   % If "_scoring" exists but "_oldscore" does not, then save it
   if (exist(fname,'file')~=0) && (exist(rname,'file')==0)
      movefile(fname,rname,'f');
   end
   
   % Save new "_scoring"
   save(fname,'behaviorData','-v7.3');
   fprintf('\b\b\b\b\b%03g%%\n',floor(iB/numel(block)*100));
end

end