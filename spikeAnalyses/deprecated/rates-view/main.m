%% MAIN


%% VIEW RATES FOR INDIVIDUAL CHANNELS
% For example:
load('P:\Extracted_Data_To_Move\Rat\TDTRat\RC-02\RC-02_2012_05_01\RC-02_2012_05_01_SpikeAnalyses\RC-02_2012_05_01_SpikeRate020ms.mat')
singleChannelFigArray = batchViewRates(data,info,pars);


%% VIEW INDIVIDUAL TRIALS FOR A SINGLE CHANNEL
load('P:\Extracted_Data_To_Move\Rat\TDTRat\RC-02\RC-02_analyses\RC-02_RateByDay_020ms_Align-Reach.mat')
load('P:\Extracted_Data_To_Move\Rat\TDTRat\RC-02\RC-02_2012_05_01\RC-02_2012_05_01_Digital\RC-02_2012_05_01_Scoring.mat')
iCh = 31;
iBlock = 1;
viewSingleTrialRates(rate{iBlock},behaviorData,iCh,...
   'XLIM',[-1 0.5],...
   'MOV_NAME','test');

%% VIEW INDIVIDUAL TRIALS FOR A SINGLE CHANNEL WITH SAVITZKY-GOLAY FILTER
load('P:\Extracted_Data_To_Move\Rat\TDTRat\info.mat');
sa = load('alert.mat','fs','sfx');
alertplayer = audioplayer(sa.sfx,sa.fs);
fprintf(1,'Exporting videos\n----------------\n');
for iAnimal = 1
   animalAnalysesDir = fullfile(F{iAnimal,2}(1).folder,[F{iAnimal,1} '_analyses']);
   animalRateFile = fullfile(animalAnalysesDir,[F{iAnimal,1} ...
      '_RateByDay_020ms_Align-Reach.mat']);
   if (exist(animalRateFile,'file')==0)  
      continue;
   else
      load(animalRateFile,'rate');
   end
   fprintf(1,'->\t%s...%03g%%\n',F{iAnimal,1},0);
   for iBlock = 1:numel(F{iAnimal,2})
      digDir = fullfile(F{iAnimal,2}(iBlock).folder,F{iAnimal,2}(iBlock).name,...
         [F{iAnimal,2}(iBlock).name '_Digital']);
      fname = fullfile(digDir,[F{iAnimal,2}(iBlock).name '_Scoring.mat']);
      if exist(fname,'file')~=0
         load(fname,'behaviorData');
%          for iCh = 1:size(rate{iBlock}.data,3)
         for iCh = [8,12,14,23,26]
            mname = sprintf('%s-%s-%s_%03g.avi',...
               rate{iBlock}.pars.name,...
               rate{iBlock}.pars.group,...
               rate{iBlock}.info(iCh).area,...
               rate{iBlock}.info(iCh).channel);
            
            viewSingleTrialRates_SG(rate{iBlock},behaviorData,iCh,...
               'XLIM',[-1.5 0.75],...
               'MOV_NAME',fullfile(F{iAnimal,1},mname));
         end
      end
      fprintf(1,'\b\b\b\b\b%03g%%\n',floor(iBlock/numel(F{iAnimal,2})*100));
   end
   fprintf(1,'\b\b\b\b\b\b\b\b\b\b\b\b\b');
   play(alertplayer,[1,sa.fs]);
end