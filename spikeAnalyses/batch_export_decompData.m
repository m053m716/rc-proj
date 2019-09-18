clear
close all force;
clc;

load('info.mat');

TANK = 'P:\Extracted_Data_To_Move\Rat\TDTRat';
ACTIVE_CH = [14,2,9,14,4,7,8,7,13,18,6,31,2];
ALIGN = {'Grasp';'Reach'};
COL = {'r';'b'};

tic;
for iA = 1:numel(ALIGN)
   for iF = 1:size(F,1)
      fname = fullfile(TANK,F{iF,1},[F{iF,1} '_analyses'],...
         [F{iF,1} '_RateByDay_020ms_Align-' ALIGN{iA} '-All.mat']);
      if exist(fname,'file')==0
         fprintf(1,'%s not found. Skipped.\n',fname);
         continue;
      else
         load(fname,'rate');
      end

      for iDay = 1:numel(rate)
         r = rate{iDay};

         ratInfo = strsplit(r.info(1).file,'_');
         name = strjoin(ratInfo(1:4),'_');
         rat = ratInfo{1};

         load(fullfile(TANK,rat,name,...
            [name '_Digital'],[name '_Scoring.mat']),'behaviorData');

         [out,bData] = decompRateData(r,behaviorData,ACTIVE_CH(iF));

         %%
         if ~isempty(out{1})
            TrueLabel = nan(size(bData,1),numel(out));
            PredictedLabel = nan(size(TrueLabel));
            
            % Append the actual and predicted classification data for trial
            % outcomes:
            for iCh = 1:numel(out)
               TrueLabel(:,iCh) = out{iCh}.Mdl.Y;
               PredictedLabel(:,iCh) = resubPredict(out{iCh}.Mdl);
            end
            bData = [bData,table(PredictedLabel,TrueLabel)]; %#ok<*AGROW>
            
            save(fullfile(TANK,rat,name,[name '_' ALIGN{iA} '-decompData.mat']),...
               'out','bData','-v7.3');
         else
            fprintf(1,...
               '%s could not match bData and out sizes. Skipped.\n',name);
         end
      end
   end
end
toc;