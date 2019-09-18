%% EXTRACTSPIKESINBEHAVIOREPOCHS   Extract wav-SNEO spikes from RC vids
clear; clc;
close all force

%% FIND BLOCKS AND DO SD - Only in epochs around behavior
load(fullfile('..','info.mat'),'F');

for iA = 1:size(F,1)
   for iB = 1:numel(F{iA,2})
      % Skip if no scoring
      if exist(fullfile(fullfile(F{iA,2}(iB).folder,F{iA,2}(iB).name),...
            [F{iA,2}(iB).name '_Digital'],...
            [F{iA,2}(iB).name '_Scoring.mat']),'file')==0
         continue;
      end
      
      % Skip if spike detection already done
      if (exist(fullfile(fullfile(F{iA,2}(iB).folder,F{iA,2}(iB).name),...
            [F{iA,2}(iB).name '_wav-sneo_CAR_Spikes']),'dir')~=0)
         continue;
      end
      
      % Do spike detection in set epochs
       b = doEpochSD(F{iA,2}(iB)); % Comment if uncommented below
       
%       b = doEpochSD(F{iA,2}(iB),... % Uncomment for access to params
%             'TANK','P:\Extracted_Data_To_Move\Rat\TDTRat',...
%             'CHECK_FOR_SPIKES',true,...
%             'E_PRE',2,...
%             'E_POST',1,...
%             'FS',24414.0625,...
%             'SPK_FEAT','wav',...
%             'SPK_PKDETECT','sneo');
            
   end   
end
