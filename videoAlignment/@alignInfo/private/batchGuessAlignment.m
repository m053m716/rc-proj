%% BATCHGUESSALIGNMENT  Batch script to guess all alignments to speed up the manual scoring part
clear;
clc;

DIR = 'P:\Extracted_Data_To_Move\Rat\TDTRat'; % Location with rat folders
VID_DIR = 'K:\Rat\Video\BilateralReach\RC'; % Location with videos/DLC
IN = '_Bea2_Ch_001.mat'; % Beam-break channel
OUT = '_Bea2_Guess.mat'; % Append to make new file name

load('Processing-List.mat','T'); % T: Matlab table with 1 column: name

for iT = 1:size(T,1)
   rat = T.name{iT}(1:5);
   block = T.name{iT};
   
   % Output from DeepLabCut is in csv format - find file
   F = dir(fullfile(VID_DIR,[block '*.csv']));
   if isempty(F)
      continue;
   end
   
   % Get pellet retrieval paw probability time-series for video
   vidTracking = importRC_Grasp(fullfile(VID_DIR,F(1).name));
   p = vidTracking.grasp_p;
   
   % Filename of beam-break file
   pname = fullfile(DIR,rat,block,[block '_Digital']);
   fname = fullfile(pname,[block IN]);
   
   % Make guess
   try
      alignGuess = makeAlignmentGuess(p,fname);
   
      % Save guess to same location as beam-break series
      save(fullfile(pname,[block OUT]),'alignGuess','-v7.3');
   catch
      T(iT,:) = []; %#ok<SAGROW>
      iT = iT - 1;
   end
end

