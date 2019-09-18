function saveAlignment(varargin)
%% SAVEALIGNMENT  wav-sneo Multi-unit: Align to behavior
%
%  SAVEALIGNMENT('NAME',value,...)
%
%  --------
%   INPUTS
%  --------
%  varargin    :     (Optional) 'NAME', value input argument pairs.
%
%  --------
%   OUTPUT
%  --------
%  Aligns multi-unit spiking data for each channel to behavioral events
%  that have been scored previously from videos. Saves data in a format
%  that can be used by LFADS.
%
% By: Max Murphy  v1.0  02/12/2018  Original version (R2017b)
%                 v1.1  07/29/2018  Changed bin size from 20 ms to 1 ms, as
%                                   with non-curated spikes you tend to
%                                   have over-saturation of 20 ms bins
%                                   leading to poor raster plots.
%                 v1.2  12/27/2018  

%% DEFAULTS
% Hyperparameters
BIN = 0.001;            % Bin size for counting spikes
E_PRE = 2;              % Number of seconds before alignment
E_POST = 1;             % Number of seconds after alignment

N_PRE = 1;              % Number of seconds before alignment to use for normalization

FS = 24414.0625;        % Sampling rate
KERNEL_W = 0.020;       % Kernel smoothing width
KERNEL_TYPE = 'tri';    % Kernel type (triangle is default; 2 sweeps)

% Directory info
SPK_DIR = '_wav-sneo_CAR_Spikes';
SPK_ID = 'ptrain';

DATA_DIR = 'P:\Extracted_Data_To_Move\Rat\TDTRat';
INFO_ID = 'info.mat';

BEH_DIR = '_Digital';
BEH_ID = '%s_Scoring.mat';

SPIKE_ANALYSIS_DIR = '_SpikeAnalyses';
RATE_OUT_ID = '%s_SpikeRate%03gms_%s_%s.mat';
RASTER_OUT_ID = '%s_BinnedSpikes%03gms_%s_%s.mat';

N_CH_TOTAL = 16; % 16 channels in total
OUTCOME = struct(...
   'label',{'Unsuccessful','Successful','All'},...
   'val',{0,1,[0,1]});

MIN_N_TRIAL = 3;  % Don't make struct if less than this
OVERWRITE = false; % Do not automatically overwrite extracted spiking data

NOTES = 'notes.txt';
ALIGN = {'Reach'; 'Grasp'; 'Complete'};

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

% Compute binning vector info
hVec = -E_PRE : BIN : E_POST;
tVec = hVec(1:(end-1)) + BIN/2;
nTimebin = numel(tVec);

%% LOOP THROUGH ALL BLOCKS AND EXPORT RASTERS FILES AND RATE ESTIMATES
load(fullfile(DATA_DIR,INFO_ID),'block');

h = waitbar(0,'Please wait, exporting multi-unit activity...');
for iF = 1:numel(block)
   % Parse naming stuff
   a = block(iF).folder;
   b = block(iF).name;
   inDir = fullfile(a,b,[b BEH_DIR]);
   outDir = fullfile(a,b,[b SPIKE_ANALYSIS_DIR]);
   scoreFile = sprintf(BEH_ID,b);
   
   % If no behaviorData (scoring) skip it
   if exist(fullfile(inDir,scoreFile),'file')==0
      fprintf(1,'->\t%s not found. Skipping...\n',b);
      continue;
   else % Otherwise load behaviorData;
      load(fullfile(inDir,scoreFile),'behaviorData');
      if exist(outDir,'dir')==0
         mkdir(outDir);
      elseif OVERWRITE
         delete(fullfile(outDir,'*')); %#ok<UNRCH>
      end
   end
   
   %% EXTRACT RECORDING METADATA
   dataDir = fullfile(block(iF).folder,...
                      block(iF).name,...
                      [block(iF).name SPK_DIR]);
                   
   S = dir(fullfile(dataDir,['*' SPK_ID '*.mat']));
   
   fnames = {S.name}.';
   [probe,channel] = parseFileNames(fnames);
   meta = getMetadata(fullfile(a,NOTES));
   chRow = channel + (probe - 1).*N_CH_TOTAL;
   info = struct( 'file',fnames,...
                  'probe',num2cell(probe),...
                  'channel',num2cell(channel),...
                  'ml',meta.ml(chRow),...
                  'icms',meta.icms(chRow),...
                  'area',meta.area(chRow));
   
   
   %% PUT SPIKES IN BINS AROUND BEHAVIOR
   fprintf(1,'->%s...',b);
   for iA = 1:numel(ALIGN)
      fprintf(1,'%s...',ALIGN{iA});
      for iO = 1:numel(OUTCOME)
      
         rasterFile = sprintf(RASTER_OUT_ID,b,BIN*1e3,ALIGN{iA},OUTCOME(iO).label);
         rateFile = sprintf(RATE_OUT_ID,b,KERNEL_W*1e3,ALIGN{iA},OUTCOME(iO).label);

         bd = behaviorData(ismember(behaviorData.Outcome,OUTCOME(iO).val),:); %#ok<NODEF>
         nUnit = numel(S);
         nTrial = size(bd,1);
         if (nTrial < MIN_N_TRIAL)
            warning('%s %s %s skipped (only %d trials).', b, ALIGN{iA}, OUTCOME(iO).label, nTrial);
            continue;
         end
         
         data = zeros(nTrial,nTimebin,nUnit);



         pars = struct('t',tVec,'normOffset',N_PRE,'fs',FS,...
                       'rasterBinWidth',BIN,'alignmentEvent',ALIGN{iA},...
                       'kernelWidth',KERNEL_W,'kernelType',KERNEL_TYPE,...
                       'group',meta.group,'name',meta.name);




         for iS = 1:nUnit % For each unit
            % Load the spike train
            in = load(fullfile(S(iS).folder,S(iS).name),'peak_train');

            % Convert to seconds
            ts = find(in.peak_train)/FS;

            for iTrial = 1:nTrial % And make a histogram
               ts_this = ts - bd.(ALIGN{iA})(iTrial);
               data(iTrial,:,iS) = histcounts(ts_this,hVec);
            end         
         end



         % Save raster output
         save(fullfile(outDir,rasterFile),'data','info','pars','-v7.3');

         %% SMOOTH BINNED SPIKE DATA
         if exist(fullfile(outDir,rateFile),'file')==0
            data = getLinearRates(data,...
                     'KERNEL_W',KERNEL_W,...
                     'BIN',BIN,...
                     'KERNEL_TYPE',KERNEL_TYPE,...
                     'NORM',N_PRE,...
                     'T',tVec); 
         else % This just makes sure correct info/pars are saved
            fprintf(1,'->\t%s found. Loading pre-computed values...\n',rateFile);
            load(fullfile(outDir,rateFile),'data');
         end

         % Save rate output
         save(fullfile(outDir,rateFile),'data','info','pars','-v7.3');
      end
      waitbar((iF-1+iA/numel(ALIGN))/numel(block));
   end
   fprintf(1,'complete.\n');
   
   waitbar(iF/numel(block));
end
delete(h);

   function [probe,channel] = parseFileNames(fnames)
      
      pIdx = cellfun(@(x)regexp(x,'ptrain_P'),fnames)+8;
      chIdx = cellfun(@(x)regexp(x,'Ch_'),fnames)+3;
      
      probe = nan(size(pIdx));
      channel = nan(size(chIdx));
      for ii = 1:numel(probe)
         probe(ii) = str2double(fnames{ii}(pIdx(ii)));
         channel(ii) = str2double(fnames{ii}(chIdx(ii):(chIdx(ii)+2)));
      end
      
   end


end

