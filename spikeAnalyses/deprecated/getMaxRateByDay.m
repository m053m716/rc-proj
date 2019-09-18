function [ratePkData,p,fig] = getMaxRateByDay(A,p)
%% GETMAXRATEBYDAY  Get data for scatter of rate peaks by times for every trial on every channel on every day
%
%  Motivation: find time instant where there is largest variance, through
%  days. Once that point is identified, return the value on every trial and
%  associate metadata with each observation.
%
%  ratePkData = GETMAXRATEBYDAY(A);
%  [ratePkData,p,fig] = GETMAXRATEBYDAY(A,p);
%
%  --------
%   INPUTS
%  --------
%     A        :     Dir struct containing animal (blocks)
%                    -> Can be given as a cell array. If so, outputs are
%                       wrapped as a cell array in the same dimension as A.
%
%     p        :     Parameters struct (see DEFAULTS section)
%  --------
%   OUTPUT
%  --------
%    out       :     Cell array, where each array element holds an output
%                       struct that gives a value for that particular
%                       channel corresponding to its point of maximal
%                       variation on average trajectories across days.
%
%     p        :     Params struct used for processing
%
%    fig       :     Figure handle. If specified, then this function also
%                       plots the scatters (otherwise it does not).
%
% By: Max Murphy  v1.0  2019-01-22  Original version (R2017a)

%% DEFAULTS
if nargin < 2
   p = defaults.MaxRateByDay();
end

%% USE RECURSION IF CELL INPUT
if iscell(A)
   ratePkData = cell(size(A));
   fig = cell(size(A));
   p.BATCH = true;
   for iA = 1:numel(ratePkData)
      [ratePkData,fig] = getMaxRateByDay(A{iA},p);
   end
   return;
end
addpath('libs');

%% LOAD FILE INFO
load(fullfile(pwd,p.F_ID),'surgDict');

%% GET ANIMAL-LEVEL INFORMATION
p.folder = A(1).folder;
p.name = A(1).name(1:5);
p.outDir = fullfile(p.folder,[p.name p.ANIMAL_ANALYSES_DIR]);

if exist(p.outDir,'dir')==0
   mkdir(p.outDir);
end
%% CHECK FOR OUTPUT DIR FOR ANALYSES; IF NONE, MAKE ONE
nBlock = numel(A);
rate = cell(nBlock,1);
for ii = 1:nBlock
   
   rateMatFile = sprintf(p.RATE_ID,A(ii).name,p.KERNEL_W*1e3);
   rateFolder = fullfile(A(ii).folder,...
      A(ii).name,...
      [A(ii).name p.SPIKE_ANALYSIS_DIR]);
   
   %% LOAD ALL DAYS RATE DATA FOR THAT ANIMAL
   
   fprintf('->\tLoading pre-compiled array...');
   inFile = fullfile(rateFolder,rateMatFile);
   if exist(inFile,'file')==0
      rate{ii} = nan;
   else
      rate{ii} = load(inFile);
   end
   fprintf(1,'complete.\n');
end

%% DISCARD ANY BAD BLOCKS
ii = 1;
while ii <= numel(rate)
   if isstruct(rate{ii})
      ii = ii + 1;
   else
      rate(ii) = [];
   end
end
nBlock = numel(rate);
p.info = rate{1}.info;
p.pars = rate{1}.pars;


%% PARSE INDEXING
tIdx = rate{1}.pars.t >= p.XLIM(1) & rate{1}.pars.t <= p.XLIM(2);
tOffset = find(tIdx,1,'first') - 1; % To adjust indexing of full pars.t

%% MATCH CORRECT CHANNELS AND FIND POINTS OF INTEREST
% Get indices for ID of channels to match identical channels on plots
idx = [[rate{1}.info.probe].',[rate{1}.info.channel].'];
newOutputStruct = struct(...
   'day',{},...
   'probe',{},...
   'channel',{},...
   'area',{},...
   't',{},...
   'tPeak',{},...
   'rateExtreme',{});

ratePkData = cell(size(idx,1),1);
newTrial = struct(newOutputStruct);
p.dayTracker = cell(numel(ratePkData),1);
fprintf(1,'Parsing Probes:\n---------------');
for ii = 1:numel(ratePkData) % Go through each probe/channel
   fprintf(1,'\n\t->\tProbe %02d: Channel %03d\t<-\n',...
      rate{1}.info(ii).probe,...
      rate{1}.info(ii).channel);
   p.dayTracker{ii} = nan(nBlock,1);
   
   ratePkData{ii} = struct(newOutputStruct);
   data = nan(nBlock,size(rate{1}.data,2));
   for iB = 1:nBlock
      p.dayTracker{ii}(iB) = parseDayNum(rate{iB}.info(ii).file,surgDict);
      subIdx = find(ismember(idx,parseChannelID(rate,iB,ii),'rows'),1,'first');
      if isempty(subIdx)
         continue;
      end
      data(iB,:) = mean(rate{iB}.data(:,:,subIdx),1);
   end
   rateVar = nanvar(data,[],1);
   [~,maxVarIdx] = max(rateVar(tIdx));
   maxVarIdx = maxVarIdx + tOffset;
   iCount = 1;
   for iB = 1:nBlock
      fprintf(1,'->\t->\tBlock %02d\n',iB);
      subIdx = find(ismember(idx,parseChannelID(rate,iB,ii),'rows'),1,'first');
      if isempty(subIdx)
         continue;
      end
      % Create a struct to store meta-parameters for each observation (row)
      newTrial(1).t = rate{iB}.pars.t(maxVarIdx);
      newTrial(1).day = parseDayNum(rate{iB}.info(subIdx).file,surgDict);
      newTrial(1).probe = rate{iB}.info(subIdx).probe;
      newTrial(1).channel = rate{iB}.info(subIdx).channel;
      newTrial(1).area = rate{iB}.info(subIdx).area;
      
      fraction_done = 0;
      % For each trial
      for iTrial = 1:size(rate{iB}.data,1)
         ratePkData{ii}(iCount) = newTrial;
         
         % Find the peak closest to the point of maximal variance
         iPk = getNearestPeakToMaximalVariancePoint(...
            rate{iB}.data(iTrial,:,subIdx),...
            maxVarIdx);
         
         % Store its time (sec) and value (normalized IFR)
         if isnan(iPk)
            ratePkData{ii}(iCount).rateExtreme = nan;
            ratePkData{ii}(iCount).tPeak = nan;
         else
            ratePkData{ii}(iCount).rateExtreme = rate{iB}.data(iTrial,iPk,subIdx);
            ratePkData{ii}(iCount).tPeak = rate{iB}.pars.t(iPk);
         end
         iCount = iCount + 1;
         pct = round(iTrial/size(rate{iB}.data,1)*100);
      end
      
   end
end

if nargout > 2
   fig = plotMaxVarianceScatter(ratePkData,p);
end

% Function to recover "ID" for channel
   function pchan = parseChannelID(rate,iB,ii)
      pchan = [rate{iB}.info(ii).probe,rate{iB}.info(ii).channel];
   end

% Function to get nearest peak to maximal variance index
   function iPk = getNearestPeakToMaximalVariancePoint(val,maxVarIdx)
      [~,iPk] = findpeaks(abs(val),'MinPeakDistance',10);
      [~,iMinDist] = min(abs(iPk - maxVarIdx));
      if isempty(iMinDist)
         iPk = nan;
      else
         iPk = iPk(iMinDist(1));
      end
   end

% Function to recover NUM DAYS post-op
   function n = parseDayNum(fileName,surgDict)
      dateStr = strsplit(fileName,'_');
      aniName = strrep(dateStr{1},'-','');
      dateStr = strjoin(dateStr(2:4),'');
      dateNum = datenum(dateStr,'yyyymmdd');
      n = dateNum - surgDict.(aniName);
   end


end