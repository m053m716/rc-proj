function plotRateByDay(varargin)
%% PLOTRATEBYDAY  Superimpose spike rates by day, for each channel
%
%  PLOTRATEBYDAY;
%  PLOTRATEBYDAY('NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%  varargin    :     (Optional) 'NAME', value input argument pairs.
%
%  --------
%   OUTPUT
%  --------
%  Creates output directory with saved figures.
%
% By: Max Murphy  v1.0  12/28/2018  Original version (R2017a)

%% DEFAULTS
KERNEL_W = 0.020; % Kernel width (seconds)

DATA_DIR = 'P:\Extracted_Data_To_Move\Rat\TDTRat';
F_ID = 'info.mat';

SPIKE_ANALYSIS_DIR = '_SpikeAnalyses';
RATE_ID = '%s_SpikeRate%03gms_%s_%s.mat';

OUT_ID = '%s_RateByDay_%03gms_Align-%s-%s%s';

FIG_POS = [0.1,0.1,0.8,0.8];
LINE_W = [1.25,2.5];

XLIM = [-1 0.5];
YLIM = [-12 12];

TITLE_STR = '%s: Ch-%03g';

ALIGN = {'Reach'; 'Grasp'; 'Complete'};
OUTCOME = {'Unsuccessful','Successful','All'};

OVERWRITE = false;

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% LOAD FILE INFO
if exist('F','var')==0
   load(fullfile(DATA_DIR,F_ID),'F');
end
load('hotcoldmap.mat','cm');
nAnimal = size(F,1); %#ok<USENS>
for iA = 1:nAnimal
   %% GET ANIMAL-LEVEL INFORMATION
   a = F{iA,1};
   animalDir = F{iA,2}(1).folder;
   
   fprintf('\nAnimal: %s\n',a); 
   
   
   
   for iAlign = 1:numel(ALIGN)
      for iO = 1:numel(OUTCOME)
         nBlock = numel(F{iA,2});
         fig = figure('Name',sprintf('%s: Rates by Day',a),...
            'Units','Normalized',...
            'Color','w',...
            'Position',FIG_POS);

         %% CHECK FOR OUTPUT DIR FOR ANALYSES; IF NONE, MAKE ONE
         fprintf(1,'->\tSaving .mat file...');
         outDir = fullfile(animalDir,[a '_analyses']);
         if exist(outDir,'dir')==0
            mkdir(outDir);
         end
      %    rateMatFile = sprintf(OUT_ID,a,KERNEL_W*1e3,...
      %                      rate{1}.pars.alignmentEvent,'.mat');

         rateMatFile = sprintf(OUT_ID,a,KERNEL_W*1e3,...
                           ALIGN{iAlign},OUTCOME{iO},'.mat');

         %% LOAD ALL DAYS RATE DATA FOR THAT ANIMAL
         if or(exist(rateMatFile,'file')==0,OVERWRITE)
            rate = cell(nBlock,1);
            excVec = false(size(rate));
            fprintf('->\tLoading...%03g%%\n',0);
            for iB = 1:nBlock
               b = F{iA,2}(iB).name;
               spikeDir = fullfile(animalDir,b,[b SPIKE_ANALYSIS_DIR]);
               inFile = fullfile(spikeDir,sprintf(RATE_ID,b,KERNEL_W*1e3,...
                  ALIGN{iAlign},OUTCOME{iO}));
               if exist(inFile,'file')==0
                  excVec(iB) = true;
                  rate{iB} = nan;      
               else
                  rate{iB} = load(inFile,'data','info','pars');
               end
               fprintf('\b\b\b\b\b%03g%%\n',floor(iB/nBlock*100));
            end
            rate(excVec) = [];
            if isempty(rate)
               fprintf('->\tNo rate files found. %s skipped.\n',a);
               delete(fig);
               continue;
            end
            nBlock = nBlock - sum(excVec);

            %% SAVE RATE-BY-DAY CELL ARRAY
            save(fullfile(outDir,rateMatFile),'rate','-v7.3');
            fprintf(1,'complete.\n');

         else % Otherwise just load the previously-saved one
            fprintf('->\tLoading pre-compiled array...');
            load(rateMatFile,'rate');
            nBlock = numel(rate);
            fprintf(1,'complete.\n');
         end   

         %% MATCH CORRECT CHANNELS TO CORRECT SUBPLOTS AND SUPERIMPOSE
         % Get indices for ID of channels to match identical channels on plots
         idx = [[rate{1}.info.probe].',[rate{1}.info.channel].'];

         % Get indices for plotting (colormap index; number of plot rows & cols)
         cmIdx = round(linspace(1,size(cm,1),nBlock)); %#ok<NODEF>
         lw = linspace(LINE_W(1),LINE_W(2),nBlock);
         nRow = floor(sqrt(size(idx,1)));
         nCol = ceil(size(idx,1)/nRow);
         fprintf(1,'->\tPlotting figure...%03g%%\n',0);
         for iB = 1:nBlock
            for ii = 1:size(rate{iB}.data,3)
               subIdx = find(ismember(idx,parseChannelID(rate,iB,ii),'rows'),1,'first');
               if isempty(subIdx)
                  continue; % Extra channel not in every day
               end
               subplot(nRow,nCol,subIdx);
               hold on;
               plot(rate{iB}.pars.t,mean(rate{iB}.data(:,:,ii),1),...
                  'Color',cm(cmIdx(iB),:),...
                  'LineWidth',lw(iB));
               if isnan(XLIM(1))
                  xlim([min(rate{iB}.pars.t) max(rate{iB}.pars.t)]);
               else
                  xlim(XLIM);
               end
               ylim(YLIM);

               set(gca,'XColor','k');
               set(gca,'YColor','k');

               nameStr = sprintf(TITLE_STR,...
                           rate{iB}.info(ii).area,...
                           rate{iB}.info(ii).channel);

               title(nameStr,'FontName','Arial','Color','k','FontSize',15);
               % Label bottom row
               if ii > (size(rate{iB}.data,3) - nCol)
                  xlabel('Time (sec)','FontName','Arial','Color','k');
               end

               % Label left column
               if rem(ii,nCol)==1
                  ylabel('Normalized IFR','FontName','Arial','Color','k');
               end
               fprintf('\b\b\b\b\b%03g%%\n',...
                  floor((iB-1)/nBlock + ii/(size(rate{iB}.data,3)*nBlock))*100);         
            end      
         end 
         subplot(nRow,nCol,ii);
         legStr = cell(nBlock,1);
         for iB = 1:nBlock
            legStr{iB} = parseLegStr(rate{iB});
         end
         legend(legStr,'Location','bestoutside');

         %% SAVE RATE-BY-DAY FIGURE
         fprintf(1,'Saving figures...');
         rateFigFile = sprintf(OUT_ID,a,KERNEL_W*1e3,...
                           rate{1}.pars.alignmentEvent,...
                           OUTCOME{iO},'.fig');
         ratePNGFile = sprintf(OUT_ID,a,KERNEL_W*1e3,...
                           rate{1}.pars.alignmentEvent,...
                           OUTCOME{iO},'.png');

         savefig(fig,fullfile(outDir,rateFigFile));
         saveas(fig,fullfile(outDir,ratePNGFile));
         delete(fig);
         fprintf(1,'complete.\n');
      end
   end
   
   
end

   % Function to recover "ID" for channel
   function pchan = parseChannelID(rate,iB,ii)
      pchan = [rate{iB}.info(ii).probe,rate{iB}.info(ii).channel];
   end

   % Function to recover recording DATE for each block
   function str = parseLegStr(rateStruct)
      info = rateStruct.info(1);
      str = strsplit(info.file,'_');
      str = strjoin(str(3:4),'-');
   end

end