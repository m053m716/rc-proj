classdef block < handle
   %BLOCK organizes all data from a single recording in RC project
   
   properties (GetAccess = public, SetAccess = private)
      Name           % Name of block folder
      Parent         % Parent object (if initialized)
      PostOpDay      % Post-operative day (numeric)
      Date           % Date of recording (char)
      BehaviorScore  % Behavior Performance (AP Scoring)
      NeurophysScore % Behavior Performance (By Neurophys Trial Category)
      TrueScore = nan% Behavior Performance (By Neurophys Advanced Scoring)
      ChannelInfo    % Information for each recording channel
      XCMean         % Cross-Condition Mean (struct)
      Data           % Data struct
      T              % Time (sec)
      Electrode      % (Masked) Electrode layouts
      xPC            % "Cross-day" principal components object
      pcFit          % PC-fit class object
      pc             % pc struct
   end
   
   properties (Access = private)
      Folder          % Full ANIMAL folder
      AllDaysScore
   end
   
   properties (Access = public, Hidden = true)
      ChannelMask          % Flag for each channel: true if GOOD
      HasAreaModulations = false; % Flag to set true if area modulations have been estimated
      HasAvgNormRate = false % Flag to set true if it has returned average normalized rate data
      HasData = false      % Flag to specify if it has data in it
      HasWarpData = false  % Flag to specify if rate data has been warped
      HasWarpedjPCA = false% Flag to specify if "warped jPCA" has been done
      HasDivergenceData = false; % Flag to specify if data comparing succ/unsucc trials in phase space is present
      dPCA_include = false; % Flag to specify if used in dPCA array
      IsOutlier = false    % Flag to specify that recording is outlier
      HasBases = false     % Flag to specify if bases were assigned from PC
      coeff                % Full matrix of PCA-defined basis vectors (columns)
      score                % Relative weighting of each PC
      x                    % Smoothed average rate used to compute PCs
      t                    % Decimated time-steps corresponding to coeff columns
      pc_idx               % Cutoff to reach desired % explained data
      RMSE                 % Final value of optimizer function for rebase
      tSnap                % Time relative to behavior to "snap" a video frame, for each trial
      chMod                % Struct with 'RFA' and 'CFA' fields that update channel modulations for those channel subsets
      nTrialRecent         % Struct with number of trials for most-recent alignment rate export
   end
   
   % Data-handling methods, including BLOCK class constructor
   methods (Access = public)
      % Block object class constructor
      function obj = block(path,doSpikeRateExtraction)
         if nargin < 1
            path = uigetdir('P:\Extracted_Data_To_Move\Rat\TDTRat',...
               'Select BLOCK folder');
            if path == 0
               disp('No block selected. Block object not created.');
               obj = [];
               return;
            end
         end
         
         if nargin < 2
            doSpikeRateExtraction = defaults.block('do_spike_rate_extraction');
         end
         
         if exist(path,'dir')==0
            error('Invalid path: %s',path);
         else
            pathInfo = strsplit(path,filesep);
            obj.Name = pathInfo{end};
            obj.Folder = strjoin(pathInfo(1:(end-1)),filesep);
         end
         
         [obj.PostOpDay,obj.Date] = parseRecDate(obj.Name);
         obj.T = defaults.experiment('t');
         resetChannelInfo(obj,true);
         
         % Add data to block object
         if doSpikeRateExtraction

            fprintf(1,'Doing spike rate extraction for %s...\n',obj.Name);
            behaviorData = obj.loadBehaviorData;
            if isempty(behaviorData)
               fprintf(1,'-->\tCould not load behaviorData.\n');
               return;
            end
            obj.doSpikeBinning(behaviorData); % No transform
%             obj.doBinSmoothing;     % (old) Does square-root transform
%             obj.doRateDownsample;   % (old) Downsample rates & normalize
            obj.doRateNormalize; % Square-root transform + mean-subtract
            fprintf(1,'Rate extraction for %s complete.\n\n',obj.Name);
         end
         
         % Regardless if doing rate extraction or not, update behavior data
         % and try and associate spike rate data with object
         updateBehaviorData(obj);
         [o,e] = defaults.block('all_outcomes','all_events');
         for iE = 1:numel(e)
            for iO = 1:numel(o)
               updateSpikeRateData(obj,e{iE},o{iO});
            end
         end

         obj.parseElectrodeCoordinates('Full');
         
      end

      % To handle case where obj.behaviorData is referenced accidentally 
      % instead of using loadbehaviorData method.
      function [b,flag] = behaviorData(obj,trialIdx)
         %BEHAVIORDATA  Handles incorrect reference
         %
         %  [b,flag] = obj.behaviorData;
         %  [b,flag] = obj.behaviorData(trialIdx);
         
         if nargin < 2
            trialIdx = [];
         end
         
         flag = true(size(obj));
         if numel(obj) > 1
            
            b = [];
            for ii = 1:numel(obj)
               if iscell(trialIdx)
                  [tmp,flag(ii)] = behaviorData(obj(ii),trialIdx{ii});
               else
                  [tmp,flag(ii)] = behaviorData(obj(ii),trialIdx);
               end
               b = [b; tmp]; %#ok<AGROW>
            end
         end
         
         b = loadBehaviorData(obj);
         if isempty(b)
            flag = false;
         elseif ~isempty(trialIdx)
            b = b(trialIdx,:);            
         end
         
      end
      
      % Remove "Outlier" status
      function clearOutlier(obj)
         %CLEAROUTLIER  Removes "outlier" status for this Block
         %
         %  clearOutlier(obj);
         
         if obj.IsOutlier
            obj.IsOutlier = false;
            fprintf(1,'%s marked as NOT an Outlier.\n',obj.Name);
         end
      end

      % Put spikes into bins
      function data = doSpikeBinning(obj,behaviorData,w)
         %DOSPIKEBINNING  Puts spikes into bins
         %
         %  data = doSpikeBinning(obj,behaviorData,w);
         %  --> Note: This is required prior to running `doBinSmoothing`
         %  --> Note: This extracts non-square-root; non-normalized rates
         
         if nargin < 3 % Bin width, in ms
            w = defaults.block('spike_bin_w');
         end
         
         if numel(obj) > 1
            data = cell(numel(obj));
            for ii = 1:numel(obj)
               if nargin < 2
                  data{ii} = doSpikeBinning(obj(ii));
               else
                  data{ii} = doSpikeBinning(obj(ii),behaviorData{ii},w);
               end
            end            
            return;
         end
         
         if nargin < 2
            behaviorData = loadBehaviorData(obj);
            if isempty(behaviorData)
               data = [];
               return;
            end
         end
         
         if isempty(obj.ChannelInfo)
            data = [];
            return;
         end
         
         [ALIGN,EVENT,start_stop_bin,outExpr] = ...
            defaults.block('all_alignments','all_events',...
               'start_stop_bin','fname_binned_spikes');

         vec = start_stop_bin(1):w:start_stop_bin(2);      
         t = vec(1:(end-1)) + mode(diff(vec))/2; %#ok<PROPLC>
         outpath = obj.getPathTo('spikerate');
         if exist(outpath,'dir')==0
            mkdir(outpath);
         end
         for iE = 1:numel(EVENT)
            for iA = 1:size(ALIGN,1)
               savename = sprintf(outExpr,obj.Name,w,...
                  EVENT{iE},ALIGN{iA,1});               
               if (exist(fullfile(outpath,savename),'file')==0) || ...
                     defaults.block('overwrite_old_spike_data')
                  
                  ts = behaviorData.(EVENT{iE})(...
                     ismember(behaviorData.Outcome,ALIGN{iA,2}));
                  data = zeros(numel(ts),numel(vec)-1,numel(obj.ChannelInfo));
                  for iCh = 1:numel(obj.ChannelInfo)
                     spike_ts = obj.loadSpikes(iCh);
                     for iTrial = 1:numel(ts)
                        ds = (spike_ts - ts(iTrial))*1e3; % ms
                        data(iTrial,:,iCh) = histcounts(ds,vec);
                     end
                  end
                  save(fullfile(outpath,savename),'data','t');
                  fprintf(1,'-->\tSaved %s\n',savename);
               end               
            end
         end
         
      end
      
      % Normalize & save rates (if needed)
      function doRateNormalize(obj)
         %DORATENORMALIZE  Does rate normalization (if needed)
         %
         %  doRateNormalize(obj);
         %
         %  --> Note: this creates the files for 'NormSpikeRate' and
         %            requires that the `doSpikeBinning` has already been
         %            done)

         if numel(obj) > 1
            for i = 1:numel(obj)
               doRateNormalize(obj(i));
            end
            return;
         end
         
         ioPath = obj.getPathTo('spikerate');
         if exist(ioPath,'dir')==0
            error(['RC:' mfilename ':MissingData'],...
               ['\n<strong>[DORATENORMALIZE]:</strong> No such path: %s\n'...
                '\t->\tMust first run `doSpikeBinning`\n'],ioPath);
         end         
         [pre_trial_norm,pre_trial_norm_epoch,...
            fStr_in,fStr_out,w,o,e] = defaults.block(...
            'pre_trial_norm','pre_trial_norm_epoch',...
            'fname_binned_spikes','fname_norm_rate',...
            'spike_bin_w','all_outcomes','all_events'); 
         defTimes = defaults.experiment('t_ms');
         for iO = 1:numel(o)
            for iE = 1:numel(e)
               % Skip if there is no file to decimate
               str = sprintf(fStr_in,obj.Name,w,e{iE},o{iO});
               fName_In = fullfile(ioPath,str);
               if exist(fName_In,'file')==0
                  fprintf(1,'\t->\tMissing: <strong>%s</strong>\n',str);
                  continue;
               end
               
               % Skip if it's already been extracted
               str = sprintf(fStr_out,obj.Name,w,e{iE},o{iO});
               fName_Out = fullfile(ioPath,str);
               if exist(fName_Out,'file')~=0
                  continue;
               else
                  fprintf(1,'\t->\tExtracting: <strong>%s</strong>...',str);
               end
               in = load(fName_In,'data','t');
               if isfield(in,'t')
                  if ~isempty(in.t)
                     t = in.t; %#ok<*PROP>
                     % Time should be in milliseconds for everything
                     if (max(abs(t)) < 10)
                        t = t * 1e3;
                     end
                  else
                     t = defTimes;
                  end
               else
                  t = defTimes;
               end
               data = sqrt(abs(in.data));
               data = data - mean(data(:,pre_trial_norm,:),2);
               save(fName_Out,'data','t','pre_trial_norm_epoch','-v7.3');    
               fprintf(1,'complete\n');
            end
         end                  
      end
      
      % Returns table of stats for all child Block objects where each row
      % is a reach trial. Essentially is behaviorData of each child object,
      % with appended metadata for each child object.
      function T = exportTrialStats(obj)
         if numel(obj) > 1
            T = [];
            for ii = 1:numel(obj)
               T = [T; exportTrialStats(obj(ii))]; %#ok<AGROW>
            end
            return;
         end
         
         
         
         T = [];
         behaviorData = obj.loadBehaviorData;
         
         if isempty(behaviorData)
            return;
         end
         
         N = size(behaviorData,1);
         Name = repmat(categorical({obj.Name}),N,1);
         PostOpDay = repmat(obj.PostOpDay,N,1);
         Date = repmat(datetime(obj.Date),N,1);
         
         T = [table(Name,PostOpDay,Date),behaviorData];
         T.Properties.Description = 'Concatenated Trial Metadata';
         T.Properties.UserData = [nan(1,3), behaviorData.Properties.UserData];
         T.Properties.VariableDescriptions = defaults.block(...
            'trial_stats_var_descriptions');
      end
      
      % Load the channel mask
      function loadChannelMask(obj)
         if numel(obj) > 1
            for ii = 1:numel(obj)
               loadChannelMask(obj(ii));
            end
            return;
         end
         
         pname = obj.getPathTo('ChannelMask');
         fname = fullfile(pname,sprintf('%s_ChannelMask.mat',obj.Name));
         if exist(fname,'file')==0
            fprintf(1,'No such file: %s\n',fname);
            fprintf(1,'-->\tAll ChannelMask values for %s set to TRUE.\n',obj.Name);
            obj.ChannelMask = true(size(obj.ChannelInfo));
         elseif ~defaults.rat('suppress_data_curation')
            obj.ChannelMask = true(size(obj.ChannelInfo));
         else
            in = load(fname,'ChannelMask');
            if isfield(in,'ChannelMask')
               obj.ChannelMask = in.ChannelMask;
            else
               obj.ChannelMask = true(size(obj.ChannelInfo));
            end
         end
      end
      
      % Load behavior scoring file
      function behaviorData = loadBehaviorData(obj)
         path = obj.getPathTo('scoring');
         fname = fullfile(path,[obj.Name '_Scoring.mat']);
         if exist(fname,'file')==0
            behaviorData = [];
            fprintf(1,'No such file: %s\n',[obj.Name '_Scoring.mat']);
            return;
         end
         
         in = load(fname,'behaviorData');
         if isfield(in,'behaviorData')
            behaviorData = in.behaviorData(...
               ~isnan(in.behaviorData.Outcome) & ...
               ~isnan(in.behaviorData.Reach) & ...
               ~isnan(in.behaviorData.Grasp),:);
            iBad = isnan(behaviorData.PelletPresent);
            if any(iBad)
               iPresent = iBad & behaviorData.Outcome;
               iAbsent = iBad & ~behaviorData.Outcome;
               behaviorData.PelletPresent(iPresent) = 1;
               behaviorData.PelletPresent(iAbsent) = 0;
            end
            if ~ismember(behaviorData.Properties.VariableNames,'Trial_ID')
               trialID = cell(size(behaviorData,1),1);
               for i = 1:numel(trialID)
                  trialID{i} = sprintf('%s_%03g',obj.Name,i);
               end               
               behaviorData.Properties.RowNames = trialID;
               behaviorData.Properties.DimensionNames{1} = 'Trial_ID';
               % Make sure it's saved for next time:
               save(fname,'behaviorData','-append');
            elseif strcmp(behaviorData.Properties.DimensionNames{1},'TrialID')
               behaviorData.Properties.DimensionNames{1} = 'Trial_ID';
               save(fname,'behaviorData','-append');
            end
            obj.HasData = true;
         else
            fprintf(1,'Scoring file found, but no behaviorData table (%s)\n',obj.Name);
            behaviorData = [];
         end
      end
      
      % Load binned spikes
      function [data,t] = loadBinnedSpikes(obj,align,outcome,w)
         if nargin < 4
            w = defaults.block('spike_bin_w');
         end
         
         if nargin < 3
            outcome = 'All';
         end
         
         if nargin < 2
            align = defaults.jPCA('jpca_align');
         end
         
         path = obj.getPathTo('binnedspikes');
         name_expr = '%s_BinnedSpikes%03gms_%s_%s.mat';
         fname = sprintf(name_expr,obj.Name,w,align,outcome);
         if exist(fullfile(path,fname),'file')==0
            fprintf(1,'No such file: %s\n',fname);
            data = [];
            t = [];
            return;
         else
            in = load(fullfile(path,fname));
            if isfield(in,'data')
               data = in.data;
            else
               data = [];
            end
            if isfield(in,'t')
               t = in.t;
            else
               t = [];
            end
         end
      end
      
      % Load spike times
      function spike_ts = loadSpikes(obj,ch)
         fs = defaults.block('fs');
         path = obj.getPathTo('spikes');
         fname = fullfile(path,obj.ChannelInfo(ch).file);
         if exist(fname,'file')==0
            spike_ts = [];
            fprintf(1,'No such file: %s\n',obj.ChannelInfo(ch).file);
            return;
         else
            in = load(fname,'peak_train');
            spike_ts = find(in.peak_train)/fs;
         end
      end
      
      % Set "Outlier" status
      function markOutlier(obj)
         if ~obj.IsOutlier
            obj.IsOutlier = true;
            fprintf(1,'%s marked as an Outlier.\n',obj.Name);
         end
      end
      
      % Return the matched channel for the channel index (from parent);
      % i.e. iCh corresponds to the index for an array of rates from the
      % BLOCK object and ch corresponds to an array from RAT object.
      function iCh = matchChannel(obj,ch,useMask)
         if numel(obj) > 1
            error('matchChannel method is only for scalar BLOCK objects.');
         end
         
         if nargin < 3
            useMask = false;
         end
         
         if numel(ch) > 1
            iCh = nan(size(ch));
            for ii = 1:numel(ch)
               iCh(ii) = obj.matchChannel(ch(ii),useMask);
            end
            return;
         end
         
         if isempty(obj.Parent)
            iCh = ch;
            fprintf(1,'Parent of %s not yet initialized.\n',obj.Name);
            return;
         end
         % Child probe, channel
         ch_probe = [obj.ChannelInfo.probe];
         ch_channel = [obj.ChannelInfo.channel];
         
         % Parent probe, channel
         p_probe = obj.Parent.ChannelInfo(ch).probe;
         p_channel = obj.Parent.ChannelInfo(ch).channel;
         
         
         if useMask
            ch_probe = ch_probe(obj.ChannelMask);
            ch_channel = ch_channel(obj.ChannelMask);
            iCh = find((ch_probe==p_probe) & (ch_channel==p_channel),1,'first');
            if isempty(iCh)
               iCh = nan;
            end
         else
            iCh = find((ch_probe==p_probe) & (ch_channel==p_channel),1,'first');
         end
         
      end
      
      % Parse the mediolateral and anteroposterior coordinates from bregma
      % for a given set of electrodes (returned in millimeters), as well as
      % the channel indices that correspond to the matched electrode from
      % the parent RAT object (if it exists)
      function [x,y,ch] = parseElectrodeCoordinates(obj,area)
         if nargin < 2
            area = 'Full';
         end
         if numel(obj) > 1
            if nargout > 0
               x = cell(numel(obj),1); 
               y = cell(numel(obj),1);
               ch = cell(numel(obj),1);
               for ii = 1:numel(obj)
                  [x{ii},y{ii},ch{ii}] = parseElectrodeCoordinates(obj(ii),area);
               end
            else
               for ii = 1:numel(obj)
                  parseElectrodeCoordinates(obj(ii),area);
               end
            end
            return;
         end
         x = []; y = []; ch = [];
         if isempty(obj.Parent)
            fprintf(1,'No parent set for %s. Can''t parse electrode info.\n',obj.Name);
            return;
         end         
         
         
         E = readtable(defaults.block('elec_info_xlsx'));
         E = E(ismember(E.Rat,obj.Parent.Name),:);
         if isempty(E)
            fprintf(1,'Could not match parent name: %s. Can''t parse electrode info.\n',obj.Parent.Name);
            return;
         end
         loc = struct;
         loc.CFA.x = E.CFA_AP;
         loc.CFA.y = E.CFA_ML;
         loc.RFA.x = E.RFA_AP;
         loc.RFA.y = E.RFA_ML;
         
         Probe = [];
         Channel = [];
         ICMS = [];
         ch_info = obj.ChannelInfo(obj.ChannelMask);
         
         
         if ~strcmpi(area,'RFA')
            % Get CFA arrangement
            ch_CFA = ch_info(contains({ch_info.area},'CFA'));

            [x_grid_cfa,y_grid_cfa,ch_grid_cfa] = block.parseElectrodeOrientation(ch_CFA);
            x_grid_cfa = x_grid_cfa + loc.CFA.x;
            y_grid_cfa = y_grid_cfa + loc.CFA.y;
         end
         
         if ~strcmpi(area,'CFA')
            % Get RFA arrangement
            ch_RFA = ch_info(contains({ch_info.area},'RFA'));

            [x_grid_rfa,y_grid_rfa,ch_grid_rfa] = block.parseElectrodeOrientation(ch_RFA);
            x_grid_rfa = x_grid_rfa + loc.RFA.x;
            y_grid_rfa = -(y_grid_rfa + loc.RFA.y); % make RFA on "bottom" of plot
         end
         
         if (strcmpi(area,'CFA') || strcmpi(area,'RFA'))
            ch_info = ch_info(contains({ch_info.area},area));
         end
         
         for ii = 1:numel(ch_info)
            p = ch_info(ii).probe;
            if contains(ch_info(ii).area,'CFA')
               cch = ch_info(ii).channel;
               iParent = find([obj.Parent.ChannelInfo.probe]==p & ...
                  [obj.Parent.ChannelInfo.channel]==cch,1,'first');
               ch = [ch; iParent]; %#ok<AGROW>
               x = [x; x_grid_cfa(ch_grid_cfa == cch)]; %#ok<AGROW>
               y = [y; y_grid_cfa(ch_grid_cfa == cch)]; %#ok<AGROW>
            else % RFA
               rch = ch_info(ii).channel;
               iParent = find([obj.Parent.ChannelInfo.probe]==p & ...
                  [obj.Parent.ChannelInfo.channel]==rch,1,'first');
               ch = [ch; iParent]; %#ok<AGROW>
               x = [x; x_grid_rfa(ch_grid_rfa == rch)]; %#ok<AGROW>
               y = [y; y_grid_rfa(ch_grid_rfa == rch)]; %#ok<AGROW>
            end
            Probe = [Probe; p]; %#ok<AGROW>
            Channel = [Channel; ch_info(ii).channel]; %#ok<AGROW>
            ICMS = [ICMS; {ch_info(ii).icms}]; %#ok<AGROW>
         end
         ICMS = categorical(ICMS);
         
         if ~(strcmpi(area,'CFA') || strcmpi(area,'RFA'))
            obj.Electrode = table(Probe,Channel,ICMS,x,y,ch);
         end
         
      end
      
      % Parse the trials to be used, based on includeStruct
      function [idx,labels,b_out] = parseTrialIndicesFromIncludeStruct(obj,align,includeStruct,outcome)
         % Parse input
         if numel(obj) > 1
            error('parseTrialIndicesFromIncludeStruct is a method of scalar BLOCK objects only.');
         end
         
         if nargin < 4
            outcome = 'All';
         end
         
         % Reduce number of rows (trials) of BEHAVIORDATA
         b = obj.behaviorData;
         idx = ~isinf(b.(align));
         b = b(idx,:);

         if strcmpi(outcome,'Successful')
            idx = logical(b.Outcome);
            b = b(idx,:);
         elseif strcmpi(outcome,'Unsuccessful')
            idx = ~logical(b.Outcome);
            b = b(idx,:);
         end
         idx = true(size(b,1),1);
         labels = b.Outcome+1;

         % Parse trial indexing based on what char vector elements 
         % comprise 'Include' field cell array
         if isfield(includeStruct,'Include')
            for ii = 1:numel(includeStruct.Include)
               iCol = find(ismember(b.Properties.VariableNames,includeStruct.Include{ii}),1,'first');
               if isempty(iCol)
                  error('Bad includeStruct.Include element: %s',includeStruct.Include{ii});
               end
               switch b.Properties.UserData(iCol)
                  case 1
                     idx = idx & (~isinf(b.(includeStruct.Include{ii})));
                  case 3
                     idx = idx & logical(b.(includeStruct.Include{ii}));
                  case 4
                     idx = idx & logical(b.(includeStruct.Include{ii}));
                  otherwise
                     continue;
               end

            end
         end

         % Parse trial indexing based on what char vector elements 
         % comprise 'Exclude' field cell array
         if isfield(includeStruct,'Exclude')
            for ii = 1:numel(includeStruct.Exclude)
               iCol = find(ismember(b.Properties.VariableNames,includeStruct.Exclude{ii}),1,'first');
               if isempty(iCol)
                  error('Bad includeStruct.Exclude element: %s',includeStruct.Exclude{ii});
               end
               switch b.Properties.UserData(iCol)
                  case 1
                     idx = idx & (isinf(b.(includeStruct.Exclude{ii})));
                  case 3
                     idx = idx & ~logical(b.(includeStruct.Exclude{ii}));
                  case 4
                     idx = idx & ~logical(b.(includeStruct.Exclude{ii}));
                  otherwise
                     continue;
               end

            end
         end

         labels = labels(idx);
         b_out = b(idx,:);
      end
      
      % Remove cross-condition mean from a set of output rates
      rate = removeCrossCondMean(obj,rate,align,includeStruct,area);
      
      % Reset channel-wise metadata
      function resetChannelInfo(obj,resetMask)
         if nargin < 2
            resetMask = false;
         end
         fname = fullfile(obj.Folder,obj.Name,[obj.Name '_ChannelInfo.mat']);
         if exist(fname,'file')==0
            fprintf(1,'No Channel Info file (%s)\n',fname);
            return;
         else
            in = load(fname,'info');
            obj.ChannelInfo = in.info;
         end
         if resetMask
            obj.loadChannelMask;
         end
      end
      
      % Reset cross-condition means
      function resetXCmean(obj)
         if numel(obj) > 1
            for ii = 1:numel(obj)
               resetXCmean(obj(ii));
            end
            return;
         end
         obj.XCMean = struct;
         obj.XCMean.key = '(align).(outcome).(pellet).(reach).(grasp).(support).(complete)';
      end
      
      % Save the current channel masking
      function saveChannelMask(obj)
         if numel(obj) > 1
            for ii = 1:numel(obj)
               saveChannelMask(obj(ii));
            end
            return;
         end
         if ~isempty(obj.ChannelMask)
            channel_mask_loc = defaults.block('channel_mask_loc');
            pname = fullfile(pwd,channel_mask_loc);
            if exist(pname,'dir')==0
               mkdir(pname);
            end
            
            fname = fullfile(pname,sprintf('%s_ChannelMask.mat',obj.Name));
            ChannelMask = obj.ChannelMask;
            save(fname,'ChannelMask','-v7.3');
         end
      end
      
      % Set the behavior data score for the day
      function updateBehaviorData(obj)
         if numel(obj) > 1
            for ii = 1:numel(obj)
               updateBehaviorData(obj(ii));
            end
            return;
         end
         
         fname = defaults.block('behavior_data_file');
         B = readtable(fname);
         
         if isempty(obj.Parent)
            ratName = obj.Name(1:5);
         else
            ratName = obj.Parent.Name;
         end
         B = B(ismember(B.Name,ratName),:);
         obj.BehaviorScore = B.pct(B.Day==obj.PostOpDay);
         if isempty(obj.BehaviorScore)
            fprintf(1,'Behavior Data for %s not found.\n',obj.Name);
            obj.BehaviorScore = nan;
         end
         
         align = defaults.jPCA('jpca_align');
         
         spike_analyses_folder = defaults.block('spike_analyses_folder');
         spike_rate_smoother = defaults.block('spike_rate_smoother');
         fname_success = fullfile(obj.Folder,obj.Name,...
            [obj.Name spike_analyses_folder],...
            [obj.Name spike_rate_smoother align '_Successful.mat']);
         if exist(fname_success,'file')==0
            nSuccess = 0;
         else
            m = matfile(fname_success);
            nSuccess = size(m.data,1);
            clear m
         end

         fname_fail = fullfile(obj.Folder,obj.Name,...
            [obj.Name spike_analyses_folder],...
            [obj.Name spike_rate_smoother align '_Unsuccessful.mat']);

         if exist(fname_fail,'file')==0
            nFail = 0;
         else
            m = matfile(fname_fail);
            nFail = size(m.data,1);
            clear m
         end

         nTotal = nSuccess + nFail;

         if nTotal == 0
            obj.NeurophysScore = nan;
         else
            obj.NeurophysScore = nSuccess/nTotal;
         end
         
         behaviorData = obj.loadBehaviorData;         
         if ~isempty(behaviorData)
            x = behaviorData(~isnan(behaviorData.PelletPresent),:);
            if nTotal == 0
               obj.TrueScore = nan;
            else
               obj.TrueScore = nSuccess/(nTotal - sum(~x.PelletPresent));
            end            
            
            b = behaviorData(~isnan(behaviorData.Outcome) & ...
               ~isinf(behaviorData.(align)) & ...
               ~isnan(behaviorData.(align)),:);
            if size(b,1)==nTotal
               obj.updateNaNBehavior([],b);
            elseif nTotal > size(b,1)
               b = behaviorData(~isinf(behaviorData.(align)) & ...
                  ~isnan(behaviorData.(align)),:);
               if size(b,1)==nTotal
                  obj.updateNaNBehavior([],b);
               else
                  b = behaviorData(~isnan(behaviorData.Grasp),:);
                  if size(b,1)==nTotal
                     obj.updateNaNBehavior([],b);
                  else
                     obj.updateNaNBehavior(nTotal,b);
                  end
               end
            else
               [~,idx] = unique(b.Grasp);
               b = b(idx,:);
               if size(b,1)==nTotal
                  obj.updateNaNBehavior([],b);
               else
                  obj.updateNaNBehavior(nTotal,b);
               end
            end
         else
            obj.updateNaNBehavior(nTotal);            
         end
      end
      
      % Update values in channel modulation property struct
      function updateChMod(obj,rate,t,alreadyMasked)
         if numel(obj) > 1
            error('UPDATECHMOD method should only be used on scalar BLOCK objects.');
         end
         
         if nargin < 4
            alreadyMasked = true;
         end
         
         if nargin < 3
            t = linspace(obj.T(1)*1e3,obj.T(end)*1e3,size(rate,1));
         end
         
         % rate: nTimesteps x nChannels matrix
         if numel(size(rate)) > 2
            rate = squeeze(nanmean(rate,1));
         end
         
         % Get indexing for CFA and RFA channels
         if alreadyMasked
            ch_rfa = contains({obj.ChannelInfo(obj.ChannelMask).area},'RFA');
            ch_cfa = contains({obj.ChannelInfo(obj.ChannelMask).area},'CFA');
         else
            ch_rfa = contains({obj.ChannelInfo.area},'RFA');
            ch_cfa = contains({obj.ChannelInfo.area},'CFA');
         end
         
         % Restrict timepoints of interest to region around the peak
         % (for estimating channel modulations for index)
         tss = defaults.rat('ch_mod_epoch_start_stop');
         t_idx = (t >= tss(1)) & (t <= tss(2));
         
         % Get average "peak modulation" across channels for the legend
         obj.chMod = struct;
         obj.chMod.RFA = nanmean(max(rate(t_idx,ch_rfa),[],1) -...
                                 min(rate(t_idx,ch_rfa),[],1));
         obj.chMod.CFA = nanmean(max(rate(t_idx,ch_cfa),[],1) -...
                                 min(rate(t_idx,ch_cfa),[],1));
                              
         obj.HasAreaModulations = true;
      end
      
      % Update the Folder (path)
      function updateFolder(obj,newFolder)
         if nargin < 2
            fprintf(1,'Must specify second argument (newFolder; updateFolder method).\n');
            return;
         end
         
         if numel(obj) > 1
            for ii = 1:numel(obj)
               updateFolder(obj(ii),newFolder);
            end
            return;
         end
         
         putative_objloc = fullfile(newFolder,obj.Name); 
         if exist(putative_objloc,'dir')==0
            warning('%s does not exist. %s Folder property not updated.',...
               putative_objloc,obj.Name);
            return;
         else
            obj.Folder = newFolder;
         end
      end
      
      % Update behavior information with nans or corresponding timestamps
      function updateNaNBehavior(obj,nTotal,b)
         if isempty(nTotal)
            obj.Data.Grasp.t = b.Grasp;
            obj.Data.Reach.t = b.Reach;
            obj.Data.Pellet.present = b.PelletPresent;
            obj.Data.Pellet.n = b.Pellets;
            obj.Data.Outcome = b.Outcome;
            return;   
         end
         
         obj.Data.Grasp.t = nan(nTotal,1);
         obj.Data.Reach.t = nan(nTotal,1);
         obj.Data.Pellet.present = nan(nTotal,1);
         obj.Data.Pellet.n = nan(nTotal,1);
         obj.Data.Outcome = nan(nTotal,1);
         
         if (nargin < 3) && (~obj.HasData)
            fprintf(1,'-->\tMissing _Scoring file: %s\n',obj.Name);
         else
            fprintf(1,...
               ['Mismatch between number of spike rate trials ' ...
               '<strong>(%g)</strong> ' ...
               'and behaviorData <strong>(%g)</strong> for %s\n'],...
               nTotal,size(b,1),obj.Name);
         end
      end
      
      % Update Spike Rate data
      function flag = updateSpikeRateData(obj,align,outcome)
         %UPDATESPIKERATEDATA  Updates Block spike rate data
         %
         %  flag = updateSpikeRateData(obj,align,outcome);
         %
         %  -- Inputs --
         %  obj : `block` object
         %  align : `'Grasp'` or `'Reach'`
         %  outcome : `'Successful'` or `'Unsuccessful'` or `'All'`
         
         flag = false;
         if nargin < 2
            align = defaults.block('alignment');
         end
         if nargin < 3
            outcome = defaults.block('outcome');
         end
         
         if numel(obj) > 1
            flag = false(size(obj));
            for ii = 1:numel(obj)
               flag(ii) = updateSpikeRateData(obj(ii),align,outcome);
            end
            return;
         end
         
         [input_expr,w] = defaults.block('fname_norm_rate','spike_bin_w');         
         str = sprintf(input_expr,obj.Name,w,align,outcome);
         ioPath = obj.getPathTo('rate');
         fname = fullfile(ioPath,str);
         if (exist(fname,'file')==0) && (~obj.HasData)
            fprintf(1,'No such file: %s\n',str);
            obj.Data.(align).(outcome).rate = [];
            return;
         elseif exist(fname,'file')==0
            fprintf(1,'No such file: %s\n',str);
            obj.Data.(align).(outcome).rate = [];
            return;
         else
            fprintf('Updating %s-%s rate data for %s...\n',outcome,align,obj.Name);
            in = load(fname,'data','t');
            if nargin == 3
%                obj.Data.(align) = struct; % In case it needs to be overwritten
%                obj.Data.(align).(outcome) = struct;
               obj.Data.(align).(outcome).rate = in.data;
               if isfield(in,'t')
                  obj.Data.(align).(outcome).t = in.t;
               else
                  obj.Data.(align).(outcome).t = defaults.experiment('t_ms');
               end
            else % For old versions
               obj.Data.rate = in.data;
               if isfield(in,'t')
                  obj.Data.t = in.t;
               else
                  obj.Data.t = linspace(min(obj.T),max(obj.T),size(in.data,2));
               end
            end
            obj.HasData = true;
            flag = true;
         end
         
      end
   end
   
   % "GET" BLOCK methods
   methods (Access = public)      
      function [avgRate,channelInfo] = getAvgSpikeRate(obj,~,~,~) %#ok<*INUSD>
         error('Deprecated');
      end
      
      function [avgRate,channelInfo,t] = getAvgNormRate(obj,~,~,~,~) %#ok<*STOUT>
         error('Deprecated');
      end
      
      % Get "rates" for a specific area
      function x = getAreaRate(obj,area,align,outcome)
         if nargin < 3
            align = defaults.jPCA('jpca_align');
         end
         
         if numel(obj) > 1
            error('Only meant for single objects, not array.');
         end
         
         if nargin < 4
            if isempty(obj.Data.(align).Successful.rate)
               x = obj.Data.(align).Unsuccessful.rate(:,:,obj.ChannelMask);
            elseif isempty(obj.Data.(align).Unsuccessful.rate)
               x = obj.Data.(align).Successful.rate(:,:,obj.ChannelMask);
            elseif isempty(obj.Data.(align).Successful.rate) && ...
                  isempty(obj.Data.(align).Unsuccessful.rate)
               fprintf(1,'No rate data in %s. Unified jPCA not possible.\n',obj.Name);
               Projection = []; %#ok<NASGU>
               Summary = []; %#ok<NASGU>
               return;
            else
               x = cat(1,...
                  obj.Data.(align).Successful.rate(:,:,obj.ChannelMask),...
                  obj.Data.(align).Unsuccessful.rate(:,:,obj.ChannelMask));
            end
         else
            x = obj.Data.(align).(outcome).rate(:,:,obj.ChannelMask);
            
         end
         
         if strcmpi(area,'RFA') || strcmpi(area,'CFA')
            ch_idx = contains({obj.ChannelInfo(obj.ChannelMask).area},area);
            x = x(:,:,ch_idx);
         end
         
      end
      
      % Returns the channel info for this recording. ChannelInfo is masked
      % by default.
      function channelInfo = getBlockChannelInfo(obj,useMask)
         if nargout < 1
            fprintf(1,'No channelInfo output requested. Skipped.\n');
            return;
         end
         if nargin < 2
            useMask = true;
         end
         if numel(obj) > 1
            channelInfo = [];
            for ii = 1:numel(obj)
               channelInfo = [channelInfo; ...
                  obj(ii).getBlockChannelInfo(useMask)]; %#ok<AGROW>
            end
            return;
         end
         channelInfo = [];
         if isempty(obj.ChannelInfo)
            fprintf(1,'No ChannelInfo for %s\n',obj.Name);
            return;
         end
         if isempty(obj.Parent)
            fprintf(1,'No Parent set for %s\n',obj.Name);
            fprintf(1,'Did not retrieve channelInfo.\n');
         end
         Rat = {obj.Parent.Name};
         Name = {obj.Name}; %#ok<PROPLC>
         PostOpDay = obj.PostOpDay; %#ok<PROPLC>
         Score = obj.TrueScore;
         if useMask
            if isempty(obj.ChannelMask)
               fprintf(1,'No ChannelMask set for %s\n',obj.Name);
               return;
            end
            channelInfo = obj.ChannelInfo(obj.ChannelMask);
         else
            channelInfo = obj.ChannelInfo;
         end
         channelInfo = rmfield(channelInfo,'file');
         channelInfo = utils.addStructField(channelInfo,Rat,...
            Name,PostOpDay,Score); %#ok<PROPLC>
         channelInfo = orderfields(channelInfo,[6:9,1:5]);
      end
      
      % Returns the matched channel indices from some "larger" channelInfo
      % struct. Defaults to applying ChannelMask to BLOCK ChannelInfo prop.
      function [idx,mask] = getChannelInfoChannel(obj,channelInfo,useMask)
         if nargin < 3
            useMask = true;
         end
         
         if numel(obj) > 1
            idx = cell(numel(obj),1);
            mask = cell(numel(obj),1);
            for ii = 1:numel(obj)
               [idx{ii},mask{ii}] = getChannelInfoChannel(obj(ii),...
                  channelInfo,useMask);
            end
            return;
         end
         
         if useMask
            pch_block = block.makeProbeChannel(obj.ChannelInfo(obj.ChannelMask));
         else
            pch_block = block.makeProbeChannel(obj.ChannelInfo);
         end
         pch_match = block.makeProbeChannel(channelInfo);
         
         % Determine what type of 'Name' field is present (or 'file')
         if isfield(channelInfo,'Name')
            name = cellstr(vertcat(channelInfo.Name));
            name = cellfun(@(x){x(1:5)},name,'UniformOutput',true);
            iCh = find(ismember(name,obj.Name(1:5)));
            pch_match = pch_match(iCh,:);
         elseif isfield(channelInfo,'file')
            name = cellstr(vertcat(channelInfo.Name));
            iCh = find(contains(name,obj.Name));
            pch_match = pch_match(iCh,:);
         else % Otherwise, neither is present, so just match probe/channels    
            iCh = 1:size(pch_match,1); % iCh is an indexing vector
         end
         
         [idx_subset,mask] = block.matchProbeChannel(pch_block,pch_match);
         % Check to make that it is consistent: if mask returns any FALSE,
         %  that means there was a BLOCK ChannelInfo element that had no
         %  match in the struct array input argument (channelInfo). Warn
         %  the user that this is the case if useMask input argument flag
         %  is set to TRUE (which is the default). This means that whatever
         %  channelInfo was passed did not have the channel of interest
         %  even after masking was applied to the BLOCK object, indicating
         %  that (for example) the channels used across days may not have
         %  had the channel mask unified across days yet. 
         if useMask && (any(~mask))
            iMiss = find(~mask,1,'first');
            warning('%s could not find a match from input channelInfo array.',...
               obj.ChannelInfo(iMiss).file(1:end-4));
            fprintf(1,'-->\t This may be fine, depending on usage.\n');
         end
         
         % Do a little rearranging to keep output consistent with output of
         % BLOCK.MATCHPROBECHANNEL static method:
         idx = nan(size(mask));
         idx(mask) = iCh(idx_subset(mask));
      end
      
      % Return the channel-wise spike rate statistics for this recording
      function stats = getChannelwiseRateStats(obj,align,outcome)
         stats = [];
         if nargin < 2
            align = defaults.jPCA('jpca_align');
         end
         
         if nargin < 3
            outcome = 'All';
         end
         
         if numel(obj) > 1
            for ii = 1:numel(obj)
               if nargout < 1
                  getChannelwiseRateStats(obj(ii),align,outcome);
               else
                  stats = [stats; ...
                     getChannelwiseRateStats(...
                        obj(ii),align,outcome)]; %#ok<AGROW>
               end
            end
            return;
         end
         
         field_expr = sprintf('Data.%s.%s.rate',align,outcome);
         [x,isFieldPresent] = parseStruct(obj.Data,field_expr);%#ok<PROPLC>
         if ~isFieldPresent || isempty(x) %#ok<PROPLC>
            fprintf(1,'%s: missing rate for %s.\n',obj.Name,field_expr);
            return;
         end
         t = obj.Data.(align).(outcome).t; %#ok<PROPLC>
         
         % Do some rearranging of data
         file = {obj.ChannelInfo.file}.';
         probe = {obj.ChannelInfo.probe}.';
         channel = {obj.ChannelInfo.channel}.';
         ml = {obj.ChannelInfo.ml}.';
         icms = {obj.ChannelInfo.icms}.';
         area = {obj.ChannelInfo.area}.';
         
         mu = squeeze(mean(x,1)); %#ok<PROPLC> % result: nTimestep x nChannel array
%          [mu,t] = obj.applyLPF2Rate(mu,obj.T*1e3,false);
%          start_stop = defaults.jPCA('jpca_start_stop_times');
%          idx = (t >= start_stop(1)) & (t <= start_stop(2));
%          mu = mu(idx,:);
%          t = t(idx);
         
         [maxRate,tMaxRate] = max(mu,[],1);
         [minRate,tMinRate] = min(mu,[],1);
         
         % Get correct orientation/format         
%          maxRate = num2cell((sqrt(abs(max(maxRate,eps)./mode(diff(obj.T))))).');
         maxRate = num2cell(maxRate.');
         tMaxRate = num2cell(t(tMaxRate).'); %#ok<PROPLC>
%          minRate = num2cell(sqrt(abs((max(minRate,eps)./mode(diff(obj.T))))).');
         minRate = num2cell(minRate.');
         tMinRate = num2cell(t(tMinRate).'); %#ok<PROPLC>
%          muRate = num2cell(mean(abs(sqrt(max(mu,eps)./mode(diff(obj.T)))),1).');
%          medRate = num2cell(median(abs(sqrt(max(mu,eps)./mode(diff(obj.T)))),1).');
         
         % For 20ms kernel:
%          c = 0.3;
%          e = 0.000;
         
         c = 0.109;
         e = 0.000;
         
%          x = sqrt(abs(max(x./mode(diff(obj.T)),eps)));
%          stdRate = num2cell(sqrt(mean(squeeze(var(x(:,idx,:),[],1)),1).'));
         NV = squeeze(c * (e + sum((x - mean(x,1)).^2,1)./(size(x,1)-1))./(c*e + mean(x,1))); %#ok<PROPLC>
%          NV = obj.applyLPF2Rate(NV,obj.T,false).';
         NV = NV.';
         dNV = min(NV(:,(t >   100) & (t <= 300)),[],2) ... % min var AFTER GRASP
             - max(NV(:,(t >= -300) & (t < -100)),[],2);    %#ok<PROPLC> % max var BEFORE GRASP
         
         NV = mat2cell(NV,ones(1,size(NV,1)),size(NV,2));
         dNV = num2cell(dNV);
         normRate = mat2cell(mu.',ones(1,numel(maxRate)),numel(t)); %#ok<PROPLC>
         
         
         tmp = struct(...
            'file',file,...
            'probe',probe,...
            'channel',channel,...
            'ml',ml,...
            'icms',icms,...
            'area',area,...
            'maxRate',maxRate,...
            'tMaxRate',tMaxRate,...
            'minRate',minRate,...
            'tMinRate',tMinRate,...
            'normRate',normRate,...
            'dNV',dNV,...
            'NV',NV);
         
         if nargout < 1
            obj.ChannelInfo = tmp;
         else
            if ~isempty(obj.Parent)
               Rat = repmat({obj.Parent.Name},numel(tmp),1);
               if ~isempty(obj.Parent.Parent)
                  Group = repmat({obj.Parent.Parent.Name},numel(tmp),1);
               else
                  Group = num2cell(nan(numel(tmp),1));
               end
            else
               Rat = num2cell(nan(numel(tmp),1));
               Group = num2cell(nan(numel(tmp),1));
            end
            
            Name = repmat({obj.Name},numel(tmp),1); %#ok<PROPLC>
            PostOpDay = repmat(obj.PostOpDay,numel(tmp),1); %#ok<PROPLC>
            output_score = defaults.group('output_score');
            Score = repmat(obj.(output_score),numel(tmp),1);
            switch outcome
               case 'Successful'
                  nTrial = ones(numel(tmp),1) * sum(obj.Data.Outcome==1);
               case 'Unsuccessful'
                  nTrial = ones(numel(tmp),1) * sum(obj.Data.Outcome==0);
               case 'All'
                  nTrial = ones(numel(tmp),1) * numel(obj.Data.Outcome);
               otherwise
                  error('Unrecognized outcome: %s.',outcome);
            end
            
            stats = [table(Rat,Name,Group,PostOpDay,Score,nTrial),struct2table(tmp)]; %#ok<PROPLC>
            stats.area = cellfun(@(x) {x((end-2):end)},stats.area);
         end
         
      end
      
      % Return the channel-wise correlation with the average cross-day mean
      % for a given alignment condition. A value of 1 corresponds to a
      % highly-conserved response, while a value of 0 is totally
      % uncorrelated.
      function [r,err_r,c,err_c,n] = getChannelResponseCorrelations(obj,align,includeStruct)
         if nargin < 2
            align = defaults.block('alignment');
         end
         
         if nargin < 3
            includeStruct = utils.makeIncludeStruct({'Reach','Grasp','Outcome'},{});
         end
         
         if numel(obj) > 1
            r = cell(numel(obj),1);
            err_r = cell(numel(obj),1);
            c = cell(numel(obj),1);
            err_c = cell(numel(obj),1);
            n = nan(numel(obj),1);
            for ii = 1:numel(obj)
               [r{ii},err_r{ii},c{ii},err_c{ii},n(ii)] = getChannelResponseCorrelations(obj(ii),align,includeStruct);
            end
            return;
         end
         obj.HasAreaModulations = false;
         
         % Initialize output
         r = nan(sum(obj.ChannelMask),1);
         err_r = nan(sum(obj.ChannelMask),1);
         c = nan(sum(obj.ChannelMask),1);
         err_c = nan(sum(obj.ChannelMask),1);
         f_c = nan(sum(obj.ChannelMask),1);
         n = nan;
         
         % Get parameterization and cross-condition mean
         p = defaults.conditionResponseCorrelations;
         [xcmean,t] = getCrossCondMean(obj,align,includeStruct,'Full'); %#ok<PROPLC>
         if isempty(xcmean)
            % Cross-condition mean doesn't exist for this condition
            return;
         end
         t_idx = (t >= p.t_start) & (t <= p.t_stop); %#ok<PROPLC>
         xcmean = xcmean(t_idx,:); 
         
         [rate,flag_exists,flag_isempty,t] = obj.getRate(align,'All','Full',includeStruct); %#ok<PROPLC>
         if (~flag_exists)
            fprintf(1,'No rate for %s: %s\n',obj.Name,utils.parseIncludeStruct(includeStruct));
            return;
         elseif (flag_isempty)
            fprintf(1,'No trials for %s: %s\n',obj.Name,utils.parseIncludeStruct(includeStruct));
            return;
         end
         t_idx = (t >= p.t_start) & (t <= p.t_stop); %#ok<PROPLC>
         rate = rate(:,t_idx,:);
         
         n = size(rate,1);
         
         fs = 1/(mode(diff(t.*1e-3))); %#ok<PROPLC>
         f = defaults.conditionResponseCorrelations('f');
         
         for iCh = 1:size(rate,3)
            % Compute Pearson's Correlation Coefficient
            rho = corrcoef([xcmean(:,iCh), rate(:,:,iCh).']);
            rho = rho(1,2:end);
            r(iCh) = nanmean(rho);
            err_r(iCh) = nanstd(rho);
            
            % Compute magnitude-squared coherence
            cxy = mscohere(rate(:,:,iCh).',xcmean(:,iCh),[],[],f,fs);
            cm = nanmean(cxy,1); %#ok<NASGU>
%             c(iCh) = nanmean(cm);
%             err_c(iCh) = nansum(cm)./numel(f); 
            [cmax,f_ind] = nanmax(cxy,[],1);
            f_ind(isnan(f_ind)) = [];
            cmax(isnan(cmax)) = [];
            err_c(iCh) = std(cmax);
            c(iCh) = mean(cmax);
            f_c(iCh) = median(f(f_ind));
         end
         
         iRFA = contains({obj.ChannelInfo(obj.ChannelMask).area},'RFA');
         obj.chMod = struct;
         obj.chMod.RFA = nanmedian(f_c(iRFA));
         obj.chMod.CFA = nanmedian(f_c(~iRFA));
%          obj.chMod.RFA = nanmean(r(iRFA));
%          obj.chMod.CFA = nanmean(r(~iRFA));
         obj.HasAreaModulations = true;
         
         if ~isempty(obj.Parent)
            Name = repmat({obj.Name},sum(obj.ChannelMask),1); %#ok<PROPLC>
            chInf = obj.ChannelInfo(obj.ChannelMask);
            Probe = [chInf.probe].';
            Channel = [chInf.channel].';
            ICMS = {chInf.icms}.';
            Area = categorical({chInf.area}.');
            PostOpDay = repmat(obj.PostOpDay,numel(Probe),1); %#ok<PROPLC>
            N = ones(numel(Probe),1)*n;
            obj.Parent.CR = [obj.Parent.CR; ...
               table(Name,PostOpDay,Probe,Channel,ICMS,Area,r,err_r,c,err_c,f_c,N)]; %#ok<PROPLC>
         end
         
      end
      
      % Get cross-condition mean for a specific condition
      [xcmean,t] = getCrossCondMean(obj,align,includeStruct,area)
      
      % Get the "dominant" aligned frequency for each channel for a given
      % alignment condition, for the cross-trial averaged spike rate.
      function [f,p] = getDominantFreq(obj,align,includeStruct)
         if nargin < 2
            align = defaults.block('alignment');
         end
         
         if nargin < 3
            includeStruct = defaults.block('include');
         end
         
         if numel(obj) > 1
            f = cell(numel(obj),1);
            p = cell(numel(obj),1);
            for ii = 1:numel(obj)
               f{ii} = getDominantFreq(obj(ii),align,includeStruct);
            end
            return;
         end
         % Get frequencies for channels indexed by masked parent channels
         f = nan(1,numel(obj.Parent.ChannelInfo(obj.Parent.ChannelMask))); %#ok<NASGU>
         p = nan(1,numel(obj.Parent.ChannelInfo(obj.Parent.ChannelMask))); %#ok<NASGU>
         
         % Get cross-condition mean to recover "dominant" frequency power
         [xcmean,t] = getCrossCondMean(obj,align,includeStruct,'Full'); %#ok<PROPLC>
         fs = 1/(mode(diff(t*1e-3))); %#ok<PROPLC>
         
         % Get the indexes into the parent frequencies
         nChannel = sum(obj.ChannelMask);
         ch = obj.getParentChannel(1:nChannel,true);
         
         [pxx,ff] = periodogram(xcmean,[],[],fs,'power');
         [p,ff_i] = max(mag2db(abs(pxx)),[],1);
         f = ff(ff_i);
         f = max(min(f,12),2); % must be 2 - 12 Hz range
         
         obj.Parent.setDominantFreq(ch,f,p);
      end
      
      % Return property associated with each channel, per unmasked channel
      function  out = getPropForEachChannel(obj,propName)
         out = [];
         if numel(obj) > 1
            for ii = 1:numel(obj)
               out = [out;getPropForEachChannel(obj(ii),propName)]; %#ok<AGROW>
            end
            return;
         end
         
         if ~isprop(obj,propName)
            fprintf(1,'%s is not a property of %s.\n',propName,obj.Name);
            return;
         end
         if ischar(obj.(propName))
            out = repmat({obj.(propName)},sum(obj.ChannelMask),1);
         else
            out = repmat(obj.(propName),sum(obj.ChannelMask),1);
         end
      end
      
      % Checks to make sure that this block can do that particular jPCA
      function [flag,out] = getChecker(obj,align,outcome,area)
         flag = true;
         out = obj.Data;
         if isfield(out,align)
            out = out.(align);
         else
            fprintf(1,'%s: missing jPCA for %s.\n',obj.Name,align);
            return;
         end
         if isfield(out,outcome)
            out = out.(outcome);
         else
            fprintf(1,'%s: missing jPCA for %s-%s.\n',obj.Name,align,outcome);
            return;
         end
         if isfield(out,'jPCA')
            out = out.jPCA;
         else
            fprintf(1,'%s: missing jPCA for %s-%s.\n',obj.Name,align,outcome);
            return;
         end
         if isfield(out,area)
            out = out.(area);
         else
            fprintf(1,'%s: missing jPCA for %s-%s-%s.\n',obj.Name,align,outcome,area);
            return;
         end
         flag = false;
      end
      
      % Get jPCA Projection and Summary fields for specific alignment etc
      function [Projection,Summary] = getjPCA(obj,field_expr)
         if nargin < 2
            error('Must provide field_expr argument (e.g. ''Data.Grasp.All.jPCA.Unified.CFA'')');
         end
         
         if numel(obj) > 1
            Projection = cell(numel(obj),1);
            Summary = cell(numel(obj),1);
            for ii = 1:numel(obj)
               [Projection{ii},Summary{ii}] = getjPCA(obj(ii),field_expr);
            end
            return;
         end
         
         [field_out,fieldExists,fieldIsEmpty] = parseStruct(obj.Data,field_expr);
         if ~fieldExists
            Projection = [];
            Summary = [];
            fprintf(1,'%s: missing %s.\n',obj.Name,field_expr);
            return;
         elseif fieldIsEmpty
            Projection = [];
            Summary = [];
            fprintf(1,'%s: %s is empty.\n',obj.Name,field_expr);
            return;
         end
         Projection = field_out.Projection;
         Summary = field_out.Summary;
         
      end
      
      % Return the coherence of each channel's average spike rate for a
      % given alignment condition with the corresponding channel's average
      % spike rate for a given alignment condition, averaged across days.
      function [cxy,f,poday] = getMeanCoherence(obj,align,includeStruct)
         if nargin < 3
            includeStruct = defaults.block('include');
         end
         
         if nargin < 2
            align = defaults.block('align');
         end
         
         if numel(obj) > 1
            cxy = cell(numel(obj),1);
            poday = [];
            for ii = 1:numel(obj)
               [cxy{ii},f,potmp] = getMeanCoherence(obj(ii),align,includeStruct);
               poday = [poday,potmp]; %#ok<AGROW>
            end
            return;
         end
         
         cxy = [];
         f = defaults.conditionResponseCorrelations('f_coh');
         poday = obj.PostOpDay;
         
         [xcmean,t] = getCrossCondMean(obj,align,includeStruct); %#ok<PROPLC>
         if isempty(xcmean)
            return;
         end
         
         t_idx = (t >= defaults.conditionResponseCorrelations('t_start')) & ...
            (t <= defaults.conditionResponseCorrelations('t_stop')); %#ok<PROPLC>
         xcmean = xcmean(t_idx,:);
         fs = 1/(mode(diff(t.*1e-3))); %#ok<PROPLC>
         
         [rate,t_rate,~,flag] = obj.getMeanRate(align,includeStruct,'Full',true);
         if ~flag
            return;
         end
         t_idx = (t_rate >= defaults.conditionResponseCorrelations('t_start')) & ...
            (t_rate <= defaults.conditionResponseCorrelations('t_stop'));
         rate = rate(t_idx,:);
         [cxy,f] = mscohere(rate,xcmean,[],[],f,fs);
         
      end
      
      % Return "dominant" frequency power for averaged condition rate on
      % each channel. Input 'f' is a pre-calculated array (one element per
      % channel) that corresponds to the "dominant" frequency for that
      % particular channel relative to the alignment (or freq of interest).
      % If obj is an array, then f should be passed as a cell array where
      % each cell element corresponds to an element of obj (and
      % corresponding number of MASKED channels).
      function [p,f] = getMeanAlignedFreqPower(obj,align,includeStruct,f)
         if nargin < 2
            align = defaults.block('alignment');
         end
         
         if nargin < 3
            includeStruct = defaults.block('include');
         end
         
%          if nargin < 4
%             f = getDominantFreq(obj,align,includeStruct);
%          end
         if nargin < 4
           f = nan;
         end
         
         if numel(obj) > 1
            p = cell(numel(obj),1);
            if nargin < 4
               f = cell(numel(obj),1);
            end
            for ii = 1:numel(obj)
               if nargin < 4
                  [p{ii},f{ii}] = getMeanAlignedFreqPower(obj(ii),align,includeStruct);
               else
                  [p{ii},f{ii}] = getMeanAlignedFreqPower(obj(ii),align,includeStruct,f{ii});
               end
            end
            return;
         end
         
         p = []; 
         
         [rate,t,~,flag] = getMeanRate(obj,align,includeStruct,'Full',false); %#ok<PROPLC>
         if ~flag
            fprintf(1,'No mean rate for %s.\n',obj.Name);
            return;
         end
         
         fs = 1/(mode(diff(t))*1e-3); %#ok<PROPLC>
         [pxx,ff] = periodogram(rate,[],[],fs,'power');
         p = nan(1,sum(obj.ChannelMask));
         F = nan(1,numel(p));
         
         for ii = 1:sum(obj.ChannelMask)
            if isnan(f)
               [p(ii),idx] = max(abs(mag2db(pxx(:,ii))));
               F(ii) = ff(idx); 
            else
               [~,idx] = min(abs(ff - f(ii)));
               p(ii) = mag2db(abs(pxx(idx,ii)));
               F(ii) = ff(idx);
            end
            
         end
         f = F;
      end
      
      % Get mean firing rate using "includeStruct" format which is a little
      % more general for handling alignment marginalizations using the
      % variables in BEHAVIORDATA table from video metadata scoring.
      function [rate,t,labels,flag] = getMeanRate(obj,align,includeStruct,area,updateAreaModulations)
         % Parse input arguments
         if nargin < 2
            align = defaults.block('alignment');
         end
         
         if nargin < 3
            includeStruct = utils.makeIncludeStruct;
         end
         
         if nargin < 4
            area = 'Full';
         end
         
         if nargin < 5
            updateAreaModulations = false;
         end
         
         % Iterate on all objects in array
         if numel(obj) > 1
            rate = cell(numel(obj),1);
            labels = cell(numel(obj),1);
            flag = false(numel(obj),1);
            for ii = 1:numel(obj)
               [rate{ii},t,labels{ii},flag(ii)] = getMeanRate(obj(ii),align,includeStruct,area,updateAreaModulations);
            end
            return;
         end
         
         if isempty(obj.nTrialRecent)
            obj.initRecentTrialCounter;
         end
         obj.nTrialRecent.rate = 0;
         
         % Get rate relative to some alignment/subset of conditions
         [rate,flag_exists,flag_isempty,t,labels] = obj.getRate(align,'All',area,includeStruct);
         
         % Check that rate does in fact exist for said alignment/conditions
         % from this particular recording
         flag = flag_exists && (~flag_isempty);
         if (~flag)
            fprintf(1,'Missing rate data for %s %s.\n',obj.Name,align);
            if updateAreaModulations
               obj.HasAreaModulations = false;
               obj.chMod = [];
            end
            return;
         else
            obj.nTrialRecent.rate = size(rate,1);
            rate = squeeze(nanmean(rate,1));
         end
         
         % If specified on input argument, update area modulations relating
         % to average rate maxima vs minima for channels in this
         % alignment/condition by CFA/RFA
         if updateAreaModulations
            obj.updateChMod(rate,t,true);
         end
      end
      
      % Get average rate from blocks within a post-op day range
      function [X,t,n,iKeep] = getMeanRateByDay(obj,align,includeStruct,poDayStart,poDayStop)
         if nargin < 5
            error('Must include all 5 input arguments.');
         end
         
         if numel(unique(vertcat(obj.Parent))) > 1
            error('All blocks in array must have SAME parent RAT object.');
         end
         
         % Init outputs
         X = [];
         t = [];
         n = 0;
         iKeep = [];
         
         s = getSubsetByDayRange(obj,poDayStart,poDayStop);
         if isempty(s)
            return;
         end
         [rate,t,labels] = getMeanRate(s,align,includeStruct,'All',false);
         
         if isempty(rate)
            return;
         end
         
         % Remove days with no data
         if ~iscell(rate)
            rate = {rate};
            labels = {labels};
         end
         iKeep = ~cellfun(@isempty,rate);
         labels = labels(iKeep);
         s = s(iKeep);
         rate = rate(iKeep);
         
         if isempty(rate)
            return;
         end
         
         X = zeros(numel(t),sum(s(1).Parent.ChannelMask));
         
         % Index according to parent
         n = sum(cellfun(@numel,labels));
         for i = 1:numel(rate)
            ch = getParentChannel(s(i),1:size(rate{i},2));
            % Weight each by total number of trials
            w = numel(labels{i}) / n;
            X(:,ch) = X(:,ch) + rate{i} .* w;
         end
      end
      
      % Similar to GETMEANRATE, but returns the average rate after
      % subtracting a marginalization using the cross-day average and
      % restrictions from the "includeStruct" format input
      % 'includeStructMarg.' 
      function [rate,t,labels,flag] = getMeanMargRate(obj,align,includeStruct,includeStructMarg,area,updateAreaModulations)
         % Parse input arguments
         if nargin < 2
            align = defaults.block('alignment');
         end
         
         if nargin < 3
            includeStruct = utils.makeIncludeStruct;
         end
         
         if nargin < 4
            includeStructMarg = utils.makeIncludeStruct;
         end
         
         if nargin < 5
            area = 'Full';
         end
         
         if nargin < 6
            updateAreaModulations = false;
         end
         
         % Handle array BLOCK object inputs
         if numel(obj) > 1
            rate = cell(numel(obj),1);
            labels = cell(numel(obj),1);
            flag = false(numel(obj),1);
            for ii = 1:numel(obj)
               [rate{ii},t,labels{ii},flag(ii)] = getMeanMargRate(obj(ii),align,includeStruct,includeStructMarg,area,updateAreaModulations);
            end
            return;
         end
         
         % Reset the trial counter, or initialize it if necessary
         if isempty(obj.nTrialRecent)
            obj.initRecentTrialCounter;
         else
            obj.nTrialRecent.marg = 0;
            obj.nTrialRecent.rate = 0;
         end
         
         % Get rate for a particular set of conditions, for this recording
         [rate,flag_exists,flag_isempty,t,labels] = obj.getRate(align,'All',area,includeStruct);
         flag = flag_exists && (~flag_isempty);
         
         % If couldn't retrieve any trials for those conditions, then skip
         % this one and make sure the channel modulation estimate has been
         % reset.
         if (~flag)
            fprintf(1,'Missing rate data for %s %s.\n',obj.Name,align);
            if updateAreaModulations
               obj.HasAreaModulations = false;
               obj.chMod = [];
            end
            return;
         else
            % Otherwise, try to remove the average cross-day mean from all
            % trials for the particular set of conditions specified in
            % includeStructMarg.
            obj.nTrialRecent.rate = size(rate,1);
            rate = obj.removeCrossCondMean(rate,align,includeStructMarg,area);
            
            % If the cross-day mean set of conditions is too restrictive to
            % find any trials, again, return an empty array and make sure
            % the channel modulations are reset.
            if isempty(rate)
               fprintf(1,'Missing marginal rate data for %s %s.\n',...
                  obj.Name,utils.parseIncludeStruct(includeStructMarg));
               if updateAreaModulations
                  obj.HasAreaModulations = false;
                  obj.chMod = [];
               end
               return;
            end
            % Otherwise, return the average and tally up the total number
            % of trials used in both the mean subtraction (.marg) and the
            % actual returned estimate (.rate)
            obj.nTrialRecent.marg = sum(obj.parseTrialIndicesFromIncludeStruct(align,includeStructMarg));
            obj.nTrialRecent.rate = size(rate,1);
            rate = squeeze(nanmean(rate,1));
         end
         
         % If specified, update "area" related channel modulations for this
         % recording (e.g. the max rate peak within a range minus the min
         % rate trough within a range, averaged across channels for RFA or
         % CFA).
         if updateAreaModulations
            obj.updateChMod(rate,t,true);
         end
      end
      
      % Get numeric property value (and check that it is numeric & scalar)
      function out = getNumProp(obj,propName,byChannel)
         if nargin < 2
            error('Must specify property name as second input argument.');
         end
         
         if nargin < 3
            byChannel = false;
         end
         
         if numel(obj) > 1
            out = [];
            for ii = 1:numel(obj)
               out = [out; getNumProp(obj(ii),propName,byChannel)]; %#ok<AGROW>
            end
            return;
         end
         out = nan;
         
         % Check that it's a valid property to return
         if ~isprop(obj,propName)
            fprintf(1,'''%s'' is not a property of %s\n',...
               propName,obj.Name);
            return;
         elseif ~isnumeric(obj.(propName))
            fprintf(1,'Property ''%s'' of %s is not numeric.\n',...
               propName,obj.Name);
            return;
         elseif ~isscalar(obj.(propName))
            fprintf(1,'Property ''%s'' of %s is not a scalar.\n',...
               propName,obj.Name);
            return;
         end
         
         % If all is well, then return it
         out = obj.(propName);
         
         if byChannel
            out = repmat(out,sum(obj.ChannelMask),1);
         end
      end
      
      % Get median offset latency (ms) between two behaviors
      %     align1 : "Later" alignment   (grasp, in reach-grasp pair)
      %     align2 : "Earlier" alignment (reach, in reach-grasp pair)
      %     offset : Positive value indicates that align1 occurs after
      %                 align2
      function offset = getOffsetLatency(obj,align1,align2,outcome,pellet,mustInclude,mustExclude)
         if nargin < 4
            outcome = [0 1];
         end
         
         if nargin < 5
            pellet = [0 1];
         end
         
         if nargin < 6
            mustInclude = {};
         end
         
         if nargin < 7
            mustExclude = {};
         end
         
         if nargin < 3
            align2 = defaults.block('alignment');
         end
         
         if nargin < 2
            error('Must specify a comparator alignment: (Reach, Grasp, Support, Complete)');
         end
         
         
         if ~ismember(align1,{'Reach','Grasp','Support','Complete'}) || ...
               ~ismember(align2,{'Reach','Grasp','Support','Complete'})
            error('Invalid alignment. Must specify from: (Reach, Grasp, Support, Complete)');
         end
         
         if numel(obj) > 1
            offset = nan(numel(obj),1);
            for i = 1:numel(obj)
               offset(i) = getOffsetLatency(obj(i),align1,align2,outcome,pellet,mustInclude,mustExclude);
            end
            return;
         end
         
         b = loadBehaviorData(obj);
         idx = ~isinf(b.(align1)) & ~isnan(b.(align1)) & ...
               ~isinf(b.(align2)) & ~isnan(b.(align2));
         idx = idx & (ismember(b.Outcome,outcome));
         idx = idx & (ismember(b.PelletPresent,pellet));
         for i = 1:numel(mustInclude)
            idx = idx & (...
               (~isinf(b.(mustInclude{i}))) & ...
               (~isnan(b.(mustInclude{i}))));
         end
         for i = 1:numel(mustExclude)
            idx = idx & (...
               (isinf(b.(mustExclude{i}))) | ...
               (isnan(b.(mustExclude{i}))));
         end   
         a1 = b.(align1)(idx);
         a2 = b.(align2)(idx);
         
         offset = median(a1 - a2) * 1e3; % return in milliseconds
      end
      
      % Given a channel index from the child block object, return the
      % corresponding channel index into the parent block object. useMask
      % argument defaults to true; by default returns the masked
      % channel indices (using mask of child object and assuming that
      % ChannelInfo of parent object is also masked)
      function ch = getParentChannel(obj,iCh,useMask)
         % Check inputs for errors
         if numel(obj) > 1
            error('GETPARENTCHANNEL is only a method for scalar BLOCK objects.');
         end
         % Object must have a parent in order to do the comparisons
         if isempty(obj.Parent)
            error('Parent for %s BLOCK object not yet set.',obj.Name);
         end   
         
         if nargin < 2
            iCh = 1:sum(obj.ChannelMask);
         elseif isempty(iCh)
            iCh = 1:sum(obj.ChannelMask);
         end
         % Default to using the channel mask unless specified
         if nargin < 3
            useMask = true;
         end
         % Handle array of channel index inputs
         if numel(iCh) > 1
            ch = nan(size(iCh));
            for ii = 1:numel(iCh)
               ch(ii) = obj.getParentChannel(iCh(ii),useMask);
            end
            return;
         end
   
         % Child probe, channel
         if useMask
            ch_chInf = obj.ChannelInfo(obj.ChannelMask);
         else
            ch_chInf = obj.ChannelInfo;
         end
         ch_probe = ch_chInf(iCh).probe;
         ch_channel = ch_chInf(iCh).channel;
         
         % Parent probe, channel
         if useMask
            p_chInf = obj.Parent.ChannelInfo(obj.Parent.ChannelMask);
         else
            p_chInf = obj.Parent.ChannelInfo;
         end
         p_probe = [p_chInf.probe];
         p_channel = [p_chInf.channel];
         
         % Find the channel index
         ch = find((p_probe == ch_probe) & ...
                   (p_channel == ch_channel),1,'first');
         if isempty(ch)
            ch = nan;
         end
      end
      
      % Returns phase data struct from primary jPCA plane projection
      function phaseData = getPhase(obj,align,outcome,area)
         if nargin < 4
            area = 'Full';
         end
         
         if nargin < 3
            outcome = 'All';
         end
         
         if nargin < 2
            align = 'Grasp';
         end
         
         if numel(obj) > 1
            phaseData = [];
            for ii = 1:numel(obj)
               phaseData = [phaseData; getPhase(obj(ii),align,outcome,area)]; %#ok<AGROW>
            end
            return;
         end
         [flag,out] = getChecker(obj,align,outcome,area);
         if flag
            tmp = [];
         else
            fprintf(1,'\t-->\tGetting phase data for %s...\n',obj.Name);
            tmp = jPCA.getPhase(out.Projection,...
               out.Summary.sortIndices(1),...
               out.Summary.outcomes);
         end
         
         Name = {obj.Name}; %#ok<PROPLC>
         Score = obj.(defaults.group('output_score'));
         PostOpDay = obj.PostOpDay; %#ok<PROPLC>
         if ~isempty(obj.Parent)
            Rat = {obj.Parent.Name};
            if ~isempty(obj.Parent.Parent)
               Group = {obj.Parent.Parent.Name};
            else
               Group = [];
            end
         else
            Rat = [];
         end
         Align = {align};
         Outcome = {outcome};
         Area = {area};
         phaseData = table(Rat,Name,Group,PostOpDay,Score,Align,Outcome,Area,{tmp}); %#ok<PROPLC>
         phaseData.Properties.VariableNames{end} = 'phaseData';
         
      end
      
      % Helper method to get paths to stuff
      function path = getPathTo(obj,dataType)
         switch lower(dataType)
            case 'channelmask'
               channel_mask_loc = defaults.block('channel_mask_loc');
               path = fullfile(pwd,channel_mask_loc);
            case 'tank'
               path = defaults.files('tank');
            case 'block'
               path = fullfile(obj.Folder,obj.Name);
            case {'digital','scoring','alignment','align'}
               path = fullfile(obj.getPathTo('block'),...
                  [obj.Name '_Digital']);
            case {'spikes','spike'}
               path = fullfile(obj.getPathTo('block'),...
                  [obj.Name '_wav-sneo_CAR_Spikes']);
            case {'rate','spikerate','rates','spikebins','bins','binnedspikes'}
               path = fullfile(obj.getPathTo('block'),...
                  [obj.Name defaults.block('spike_analyses_folder')]);
            case {'vid','video','behaviorvid','rcvids','vids','videos','dlc'}
               behavior_vid_loc = defaults.block('behavior_vid_loc');
               path = fullfile(behavior_vid_loc);
            case {'dpca','demixing'}
               path = defaults.dPCA('path');
            case {'dpca-repo','dpca-code'}
               path = defaults.dPCA('local_repo_loc');
            otherwise
               fprintf(1,'Unrecognized type: %s.\n',dataType);
               path = [];
         end
      end
      
      % Return specified property, if it exists
      function out = getProp(obj,propName)
         out = [];
         for ii = 1:numel(obj)
            if isprop(obj(ii),propName) && ~strcmpi(propName,'Data')
               out = [out; obj(ii).(propName)]; %#ok<AGROW>
            elseif isprop(obj(ii),propName)
               out = [out; {obj(ii).(propName)}]; %#ok<AGROW>
            end
         end
      end
      
      % Returns rate for a given field configuration, if it exists
      % 
      %  -> inclusionStruct : Struct that tells what other elements
      %                          need to be present (based on behaviorData)
      %                          for a given trial to be included (in
      %                          addition to the align, outcome, and area)
      %
      %                 Usage:
      %                 iS = struct;
      %                 iS.Include = {'Grasp','PelletPresent'};
      %                 iS.Exclude = {'Complete','Support'};
      %                 rate = getRate(obj,'Reach','All','Full',iS);
      %
      %           Rate: nTrials x nTimesteps x nChannels tensor
      %
      function [rate,flag_exists,flag_isempty,t,labels,b,channelInfo] = getRate(obj,align,outcome,area,includeStruct,updateAreaModulations)         
         % GETRATE  Returns rate for a given field configuration
         % 
         %  [rate,flag_exists,flag_isempty,t,labels,b,channelInfo] = getRate(obj,align,outcome,area,includeStruct,updateAreaModulations);         
         %
         %  -> includeStruct : Struct that tells what other elements
         %                     need to be present (based on behaviorData)
         %                     for a given trial to be included (in
         %                     addition to the align, outcome, and area)
         %
         %                 Usage:
         %                 iS = struct;
         %                 iS.Include = {'Grasp','PelletPresent'};
         %                 iS.Exclude = {'Complete','Support'};
         %                 rate = getRate(obj,'Reach','All','Full',iS);
         %
         %           Rate: nTrials x nTimesteps x nChannels tensor
         %              --> `Rate` is the corresponding downsampled,
         %                    normalized rate data.
         %              --> Must be assigned to the rate `.Data` struct
         %                  property field using `updateSpikeRateData`
         
         % Parse input
         if nargin < 4
            area = 'Full';
         elseif isempty(area)
            area = 'Full';
         elseif iscell(area)
            % Do nothing
         elseif isnan(area(1))
            area = 'Full';
         end
         
         if nargin < 5
            includeStruct = utils.makeIncludeStruct([],[]);
         end
         
         if nargin < 6
            updateAreaModulations = false;
         end
         
         if numel(obj) > 1
            [rate,labels,b,channelInfo] = utils.initCellArray(numel(obj),1);
            [flag_exists,flag_isempty] = utils.initFalseArray(numel(obj),1);

            for ii = 1:numel(obj)
               switch nargin
                  case 6
                     [rate{ii},flag_exists(ii),flag_isempty(ii),t,labels{ii},b{ii},channelInfo{ii}] = ...
                        obj(ii).getRate(align,outcome,area,includeStruct,updateAreaModulations);                      
                  case 5
                     [rate{ii},flag_exists(ii),flag_isempty(ii),t,labels{ii},b{ii},channelInfo{ii}] = ...
                        obj(ii).getRate(align,outcome,area,includeStruct);                    
                  case 4
                     [rate{ii},flag_exists(ii),flag_isempty(ii),t,labels{ii},b{ii},channelInfo{ii}] = ...
                        obj(ii).getRate(align,outcome,area);
                  case 3
                     [rate{ii},flag_exists(ii),flag_isempty(ii),t,labels{ii},b{ii},channelInfo{ii}] = ...
                        obj(ii).getRate(align,outcome);
                  case 2
                     [rate{ii},flag_exists(ii),flag_isempty(ii),t,labels{ii},b{ii},channelInfo{ii}] = ...
                        obj(ii).getRate(align);
                  otherwise
                     error('Invalid number of input arguments (%g).',nargin);
               end
            end
            return;
         end
         % Initialize outputs
         [rate,t,labels,b] = utils.initEmpty;
         [flag_exists,flag_isempty] = utils.initTrueArray(1);
         channelInfo = obj.ChannelInfo(obj.ChannelMask);
         obj.nTrialRecent.rate = 0;
         
         if obj.IsOutlier
            fprintf(1,'%s has been marked as an outlier point. Skipped.\n',obj.Name);
            obj.HasAreaModulations = false;
            obj.chMod = [];
            return;
         end
         
         switch nargin
            case 6
               field_expr_rate = sprintf('Data.%s.%s.rate',align,outcome);
               field_expr_t = sprintf('Data.%s.%s.t',align,outcome);
            case 5
               field_expr_rate = sprintf('Data.%s.%s.rate',align,outcome);
               field_expr_t = sprintf('Data.%s.%s.t',align,outcome);
            case 4
               field_expr_rate = sprintf('Data.%s.%s.rate',align,outcome);
               field_expr_t = sprintf('Data.%s.%s.t',align,outcome);
            case 3
               field_expr_rate = sprintf('Data.%s.%s.rate',align,outcome);
               field_expr_t = sprintf('Data.%s.%s.t',align,outcome);
            case 2
               field_expr_rate = sprintf('Data.%s.rate',align);
               field_expr_t = sprintf('Data.%s.t',align);
            otherwise
               error('Invalid number of input arguments (%g).',nargin);
         end
         
         % % -- GET THE INDIVIDUAL TRIAL RATES HERE -- % %
         [rate,flag_exists,flag_isempty] = parseStruct(obj.Data,field_expr_rate);
         
         % Get behavior data table
         switch outcome
            case 'Successful'
               b = obj.behaviorData(logical(obj.Data.Outcome));
            case 'Unsuccessful'
               b = obj.behaviorData(~logical(obj.Data.Outcome));
            otherwise
               b = obj.behaviorData;
         end
         
         % Get timestep values relative to alignment
         t = parseStruct(obj.Data,field_expr_t);
         
         if (~flag_exists) || (flag_isempty)
            fprintf(1,'No rate for %s: %s\n',obj.Name,field_expr_rate);
            if updateAreaModulations
               obj.HasAreaModulations = false;
               obj.chMod = [];
            end
            return;
         end
         
         % If includeStruct has been specified as an input argument, then
         % use it to refine what trials should be included
         if (nargin > 4)            
            [idx,labels,b] = obj.parseTrialIndicesFromIncludeStruct(align,includeStruct,outcome);
            rate = rate(idx,:,:);
            flag_isempty = isempty(rate);
            
            if (flag_isempty)
               fprintf(1,'No rate for %s: %s\n',...
                  obj.Name,utils.parseIncludeStruct(includeStruct));
               if updateAreaModulations
                  obj.HasAreaModulations = false;
                  obj.chMod = [];
               end
               return;
            end
         end
         obj.nTrialRecent.rate = size(rate,1);

         % If no outcome specified, parse outcome labels
         if nargin < 3
            labels = parseStruct(obj.Data,'Data.Outcome')+1;
         elseif (nargin < 5) && (nargin >= 3) % If "outcome" was specified but not includeStruct
            switch outcome
               case 'Unsuccessful'
                  labels = ones(size(rate,1),1);
               case 'Successful'
                  labels = ones(size(rate,1),1)+1;
               otherwise
                  labels = parseStruct(obj.Data,'Data.Outcome')+1;
            end
         end
         
         % Remove masked channels
         rate = rate(:,:,obj.ChannelMask);

         % Exclude based on area if 'RFA' or 'CFA' are explicitly specified
         if contains(upper(area),{'RFA','CFA'})
            ch_idx = contains({channelInfo.area},upper(area));
            rate = rate(:,:,ch_idx);
            channelInfo = channelInfo(ch_idx);
         end

         % If asked to update area modulations, do so for the rate
         % structure given default parameters in defaults.block regarding
         % the relevant indexing for time-periods to look at modulations in
         if updateAreaModulations
            obj.updateChMod(rate,t,true);
         end

         
      end
      
      % Alternative way to get/set include struct that's a little more
      % general than the initial methods. GETS CROSS-CONDITION MEAN
      % (AVERAGED ACROSS DAYS).
      [rate,t] = getSetIncludeStruct(obj,align,includeStruct,rate,t)
      
      % Return a subset of BLOCK objects from a BLOCK array using PostOpDay
      %  s = getSubsetByDayRange(blockObjArray,3,28); % Returns days 3-28
      %  s = getSubsetByDayRange(blockObjArray,[3,10,11:18]); % Specific
      function s = getSubsetByDayRange(obj,poDayStart,poDayStop)
         if nargin == 3
            d = poDayStart:poDayStop;
         else
            d = poDayStart;
         end
         poday = getNumProp(obj,'PostOpDay');
         idx = ismember(poday,d);
         s = obj(idx);
      end
      
      % Return rate data as a tensor of [nTrial x nTimesteps x nChannels],
      % corresponding time values (milliseconds) in t, and corresponding
      % channel/trial metadata in meta
      function [rate,t,meta] = getTrialData(obj,includeStruct,align,area,icms,forceClean)
         % GETTRIALDATA    Return trial-aligned spike rates and metadata
         %
         %  [rate,t,meta] = GETTRIALDATA(obj);
         %  [rate,t,meta] = GETTRIALDATA(obj,includeStruct);
         %  [rate,t,meta] = GETTRIALDATA(obj,includeStruct,align);
         %  [rate,t,meta] = GETTRIALDATA(obj,includeStruct,align,area);
         %  [rate,t,meta] = GETTRIALDATA(obj,includeStruct,align,area,icms);
         %  [rate,t,meta] = GETTRIALDATA(___,forceClean);
         %
         %  in- 
         %  includeStruct : Returned by utils.makeIncludeStruct
         %  align : 'Grasp', 'Reach', 'Support', or 'Complete'
         %  area : 'CFA', 'RFA', or 'Full'
         %  icms : 'DF' or {'DF','PF','DF-PF','O',...} (to include those)
         %  forceClean : (Default: false) can set to true if this is called
         %                 directly in order to "clean" the channelInfo
         %                 struct in meta as would be done by the rat and
         %                 group objects above it.
         %
         %  out-
         %  rate : [nTrial x nTimesteps x nChannels] tensor of rates
         %  t : [1 x nTimesteps] vector it times (milliseconds)
         %  meta : Struct containing metadata fields --
         %     --> .behaviorData : Table of all trial times, corresponds to
         %              rows of 'rate'
         %     --> .channelInfo : Struct of all channel info, corresponds
         %              to 3rd dim of 'rate'
         %     --> .poday : Number of days relative to implant operation
         %     --> .score : 'TrueScore' property reflecting scoring for
         %              neurophysiological dataset.
         
         if nargin < 6
            forceClean = false;
         end
         
         if nargin < 5
            icms = defaults.block('icms');
         elseif isempty(icms)
            icms = defaults.block('icms');
         end
         
         if nargin < 4
            area = defaults.block('area');
         elseif isempty(area)
            area = defaults.block('area');
         end
         
         if nargin < 3
            align = defaults.block('align');
         elseif isempty(align)
            align = defaults.block('align');
         end
         
         if nargin < 2
            includeStruct = defaults.block('include');
         elseif isempty(includeStruct)
            includeStruct = defaults.block('include');
         end
         
         % Handle input array
         if numel(obj) > 1
            [rate,t,meta] = utils.initCellArray(numel(obj),1);
            for i = 1:numel(obj)
               [rate{i},t{i},meta{i}] = obj(i).getTrialData(includeStruct,align,area,icms,forceClean);
            end
            iRemove = cellfun(@isempty,rate);
            rate(iRemove) = [];
            meta(iRemove) = [];
            t = utils.getFirstNonEmptyCell(t);
            return;
         end
         meta = struct('behaviorData',[],'channelInfo',[],'poday',[],'score',[]);
         [rate,~,~,t,~,meta.behaviorData,meta.channelInfo] = ...
            obj.getRate(align,'All',area,includeStruct,false);
         if isempty(rate)
            return;
         end
         
         ci = contains({meta.channelInfo.icms}.',icms);
         if sum(ci)==0
            warning('No channels returned for %s due to icms exclusion',obj.Name);
            fprintf(1,'-->\t%s\n',icms{:});
         end
         meta.channelInfo = meta.channelInfo(ci);
         if forceClean && ~isempty(meta.channelInfo) % Assumes both Parents are set
            meta.channelInfo = ...
               group.cleanChannelInfo(...
                  rat.cleanChannelInfo(...
                     meta.channelInfo,{obj.Parent.Name}),...
                  {obj.Parent.Parent.Name});            
         end
         rate = rate(:,:,ci);
         meta.score = obj.TrueScore;
         meta.poday = obj.PostOpDay;
         
      end
      
      % Return "unified" property (from parent)
      function out = getUnifiedProp(obj,area,propName)
         
         
         if isempty(obj(1).Parent)
            out = [];
            fprintf(1,'No parent of %s.\n',obj(1).Name);
            return;
         end
         
         if ~isfield(obj(1).Parent.Data,area)
            out = [];
            fprintf(1,'%s has not been extracted for %s.\n',...
               area,obj(1).Parent.Name);
            return;
         end
         
         if ~isfield(obj(1).Parent.Data.(area),propName)
            out = [];
            fprintf(1,'%s has not been extracted for %s-%s.\n',...
               area,obj(1).Parent.Name,area);
            return;
         end
         
         if numel(obj) > 1
            out = [];
            for ii = 1:numel(obj)
               out = [out; obj(ii).Parent.Data.(propName)]; %#ok<AGROW>
            end
            return;
         end
         
         out = obj.Parent.Data.(propName);
      end
      
      % Return object handle to behavioral video
      function [V,offset] = getVideo(obj)
         if numel(obj) > 1
            V = cell(numel(obj),1);
            for ii = 1:numel(obj)
               V{ii} = getVideo(obj(ii));
            end
            return;
         end
         
         vpath = obj.getPathTo('vid');
         F = dir(fullfile(vpath,[obj.Name '*.avi']));
                  
         if isempty(F)
            V = [];
            offset = [];
            fprintf(1,'\t-->\tMissing video: %s\n',obj.Name);
            return;
         end
            
         apath = obj.getPathTo('align');
         fname = fullfile(sprintf('%s_VideoAlignment.mat',obj.Name));
         if exist(fullfile(apath,fname),'file')==0
            V = [];
            offset = [];
            fprintf(1,'\t-->\tMissing alignment: %s\n',fname);
            return;
         end
         V = VideoReader(fullfile(vpath,F(1).name));
         in = load(fullfile(apath,fname),'VideoStart');
         if ~isfield(in,'VideoStart')
            V = [];
            offset = [];
            fprintf(1,'\t-->\tMissing alignment variable: %s\n',obj.Name);
            return;
         end
         offset = in.VideoStart;

      end
      
   end
   
   % "SET" BLOCK methods
   methods (Access = public)
      % Set "AllDaysScore" property
      function setAllDaysScore(obj,score)
         if nargin < 2
            error('Not enough input arguments.');
         end
         
         if numel(obj) > 1
            if numel(obj) ~= numel(score)
               error('Each element of score must correspond to a block object.');
            end
            for ii = 1:numel(obj)
               setAllDaysScore(obj(ii),score(ii));
            end
            return;
         end
         
         obj.AllDaysScore = score;
      end
      
      % Set channel masking
      function isGoodChannel = setChannelMask(obj,chIdx,isGoodChannel)
         if isempty(obj.ChannelMask)
            resetChannelInfo(obj,true);
         end
         
         if nargin < 3
            isGoodChannel = ~obj.ChannelMask(chIdx);
         end
         
         obj.ChannelMask(chIdx) = isGoodChannel;
         if ~isGoodChannel
            if sum(obj.ChannelMask)==0
               obj.HasData = false;
            end
         end
         
      end
      
      % Set cross-condition means, averaged across all days
      function setCrossCondMean(obj,xcmean,t,align,outcome,pellet,reach,grasp,support,complete)
         if nargin < 10
            complete = 'All';
         end
         
         if nargin < 9
            support = 'All';
         end
         
         if nargin < 8
            grasp = 'All';
         end
         
         if nargin < 7
            reach = 'All';
         end
         
         if nargin < 6
            pellet = 'All';
         end
         
         if nargin < 5
            outcome = 'All';
         end
         
         if nargin < 4
            align = defaults.block('alignment');
         end
         
         if numel(obj) > 1
            for ii = 1:numel(obj)
               setCrossCondMean(obj(ii),xcmean,t,align,outcome,pellet,reach,grasp,support,complete);
            end
            return;
         end
         if isempty(obj.XCMean)
            resetXCmean(obj);
         end
         obj.XCMean.(align).(outcome).(pellet).(reach).(grasp).(support).(complete) = struct;
         obj.XCMean.(align).(outcome).(pellet).(reach).(grasp).(support).(complete).rate = xcmean;
         obj.XCMean.(align).(outcome).(pellet).(reach).(grasp).(support).(complete).t = t;
         
      end
      
      % Set data regarding divergence of unsuccessful and  successful
      % trajectories in primary plane of jPCA phase space
      % -- deprecated --
      function setDivergenceData(obj,T)
         if numel(obj) > 1
            for ii = 1:numel(obj)
               Tsub = T(ismember(T.Name,obj(ii).Name),:);
               if isempty(Tsub)
                  fprintf(1,'No divergence data for %s.\n',obj(ii).Name);
                  continue;
               else
                  setDivergenceData(obj(ii),Tsub);
               end
            end
            return;
         end
         
         data = struct(...
            'S_mu',T.S_mu,...
            'Cs_med',T.Cs_med,...
            'S_min',T.S_min,...
            'T_0',T.T_0,...
            'T_min',T.T_min,...
            'N_min',T.N_min);
         obj.Data.Divergence = data;
         if isempty(obj.tSnap)
            obj.tSnap = T.T_0;
         end
         obj.HasDivergenceData = true;
      end
      
      % Set the parent
      function setParent(obj,p)
         if isa(p,'rat')
            obj.Parent = p;
         else
            fprintf(1,'%s is an invalid parent class for block object.\n',...
               class(p));
         end
      end
      
      % Set property for an ARRAY of block objects
      function setProp(obj,propName,propVal)
         if numel(obj) ~= numel(propVal)
            error('Number of elements in BLOCK array (%g) must match number of elements in ''propVal'' argument (%g).',numel(obj),numel(propVal));
         end
         if ~isprop(obj,propName)
            error('Invalid BLOCK property: %s',propName);
         end
         
         for ii = 1:numel(obj)
            obj(ii).(propName) = propVal(ii);
         end
      end
      
      % Set snap time (sec) for taking frames relative to video
      % -- deprecated --
      function setSnapTime(obj,t)
         if nargin < 2
            t = 0;
         end
         if numel(obj) > 1
            for ii = 1:numel(obj)
               setSnapTime(obj(ii),t);
            end
            return;
         end
         
         obj.tSnap = t;
      end
      
      % Set xPC object
      function setxPCs(obj,xPC)
         if numel(obj) > 1
            for ii = 1:numel(obj)
               setxPCs(obj(ii),xPC);
            end
            return;
         end
         obj.xPC = xPC;
         obj.pc = getMatchedCoeffs(xPC,obj.ChannelInfo(obj.ChannelMask));
      end
      
   end
   
   % "GRAPHICS" BLOCK methods
   methods (Access = public)
      % Plot the average normalized spike rate for a given
      % alignment/outcome combination
      function ax = plotAverageChannelRate(obj,align,outcome)
         if nargin < 3
            outcome = defaults.block('outcome');
         end
         
         if nargin < 2
            align = defaults.jPCA('jpca_align');
         end
         
         if numel(obj) > 1
            for ii = 1:numel(obj)
               figure('Name',sprintf('%s-%s-%s Average Rate',...
                  obj(ii).Name,align,outcome));
               plotAverageChannelRate(obj(ii),align,outcome);
            end
            if nargout > 0
               warning('Cannot return axes array for block array argument.');
               ax = [];
            end
            return;
         end
         
         xl = defaults.block('x_lim');
         yl = defaults.block('y_lim');
         
         ax = gca;
         ax.NextPlot = 'add';
         ax.XLim = xl;
         ax.YLim = yl;
         
         area = defaults.block('area_opts');
         col = defaults.block('area_color');
         
         
         offset = obj.getOffsetLatency(align,defaults.block('alignment'));
         
%          t = obj.T * 1e3 + offset;
         for ii = 1:numel(area)
%             x = getAreaRate(obj,area{ii},align,outcome);
%             y = obj.doSmoothNorm(x);
%             z = squeeze(mean(y,1));
            [rate,flag_exists,flag_isempty,t] = getRate(obj,align,outcome,area{ii}); %#ok<PROPLC>
            if (~flag_exists) || (flag_isempty)
               continue;
            end
            z = squeeze(mean(rate,1));
            if (max(abs(t)) < 10) %#ok<PROPLC>
               t = t * 1e3; %#ok<PROPLC>
            end
            plot(ax,t,z,'Color',col{ii},'LineWidth',1.5); %#ok<PROPLC>
         end
         
         e_col = defaults.block('event_color');
         e = defaults.block('all_events');
         
         l = line([offset,offset],yl,'Color',e_col{ismember(e,align)},...
            'LineStyle','--','LineWidth',2);
         
         h = get(ax,'Children');
         legend([h([2,end-1]); l],[area, ...
            sprintf('Median %s offset',align)],'Location','NorthWest');
         
         xlabel('Time (ms)','Color','k','FontName','Arial','FontSize',14);
         ylabel('Spike Rate','Color','k','FontName','Arial','FontSize',14);
      end
      
      % Plot all alignments of a given outcome as subplots for this block
      function fig = plotAllAlignmentsRate(obj,outcome)
         if nargin < 2
            outcome = defaults.block('outcome');
         end
         
         if numel(obj) > 1
            fig = [];
            for ii = 1:numel(obj)
               fig = [fig; plotAllAlignmentsRate(obj(ii),outcome)]; %#ok<AGROW>
            end
            return;
         end
         
         fig = figure('Name',sprintf('%s-%s All Alignment Average Rate',...
            obj.Name,outcome),...
            'Color','w',...
            'Units','Normalized',...
            'Position',[0.4 0.1 0.45 0.8]);
         
         a = defaults.block('all_events');
         for ii = 1:numel(a)
            subplot(numel(a),1,ii);
            obj.plotAverageChannelRate(a{ii},outcome);
            title(a{ii},'Color','k','FontName','Arial','FontSize',16);
         end
      end
   end
   
   % Private methods (init)
   methods (Access = private)
      % Initialize a function that counts trials in any recently-retrieved
      % alignment condition average
      function initRecentTrialCounter(obj)
         obj.nTrialRecent = struct('rate',0,'marg',0);
      end
   end
   
   % Static methods
   methods (Access = public, Static = true)
      % Static function to apply LPF and down-sample for jPCA
      function [y,t_out] = applyLPF2Rate(x,t_in,doNorm)
         if nargin < 3
            doNorm = true;
         end
         
         fs = 1/(defaults.block('spike_bin_w')*1e-3);
         lpf_order = defaults.block('lpf_order');
         lpf_fc = defaults.block('lpf_fc');
         [b,a] = butter(lpf_order,lpf_fc/(fs/2));
         
         
         if doNorm
            r = defaults.jPCA('jpca_decimation_factor');
            norm_samples = defaults.block('pre_trial_norm');
            y = nan(size(x,1),ceil(size(x,2)/r),size(x,3));
            x = sqrt(abs(x));
            x = (x - mean(x(:,norm_samples,:),2)) ./ ...
                  (std(x(:,norm_samples,:),[],2)+1);

            for iCh = 1:size(x,3)
               for ii = 1:size(x,1)
                  tmp = x(ii,:,iCh);
                  y(ii,:,iCh) = decimate(filtfilt(b,a,tmp),r);
               end
            end
            if nargin > 1
               t_out = linspace(t_in(1)*1e3,t_in(end)*1e3,size(y,2));
            else
               t_out = defaults.experiment('t')*1e3;
            end
         else
            switch numel(size(x))
               case 2
                  if size(x,1) < size(x,2)
                     x = x.'; % Assume that time is "long" dimension
                  end
                  y = filtfilt(b,a,x);
               case 3
                  y = nan(size(x));
                  for iCh = 1:size(x,3)
                     y(:,:,iCh) = filtfilt(b,a,x(:,:,iCh).').';
                  end
               otherwise
                  error('Invalid number of dimensions for x (%g).',numel(size(x)));
            end
            if nargin > 1
               t_out = t_in;
            else
               t_out = defaults.experiment('t')*1e3;
            end
         end
      end
      
      % Static function to apply time warning based on "anchor" behavioral
      % events -- that analysis didn't work well
      function [y,times,labels] = applyTimeWarping(x,t,outcome,d_ts)
         if nargin < 3
            outcome = ones(size(x,1),1);
         end
         warp_params = defaults.block('warp');
         p = warp_params.nPoints;
         y = nan(size(x,1),p,size(x,3));
         times = nan(size(y,1),p);
         [~,iStop] = min(abs(t - warp_params.post_grasp));
         
         for ii = 1:numel(d_ts)
            [~,iStart] = min(abs(t-(d_ts(ii)-warp_params.pre_reach)));
            if iStart < 1
               continue;
            end
            q = iStop - iStart + 1;
            for iCh = 1:size(x,3)
               if p ~= q
                  y(ii,:,iCh) = resample(x(ii,iStart:iStop,iCh),p,q);
                  times(ii,:) = linspace(t(iStart),t(iStop),p);
               else
                  y(ii,:,:) = x(ii,iStart:iStop,:);
                  times(ii,:) = t(iStart:iStop); % convert to ms
                  break; % only need to do once
               end
            end
         end
         labels = outcome(~isnan(y(:,1,1)));
         labels(labels==0) = 2; % 2 -> failures
         y(isnan(y(:,1,1)),:,:) = [];
         times(isnan(times(:,1)),:) = [];
         y = y(:,warp_params.trim:(end-warp_params.trim+1),:);
         times = times(:,warp_params.trim:(end-warp_params.trim+1));
      end
      
      function y = doSmoothNorm(~,~)
         error('Deprecated');
      end
      
      function y = doSmoothOnly(~,~)
         error('Deprecated');
      end
      
      % Make "probechannel" array from ChannelInfo struct
      function pCh = makeProbeChannel(channelInfo)
         pCh = horzcat(vertcat(channelInfo.probe),vertcat(channelInfo.channel));
      end
      
      % Match probe and channel. For each probe-channel combination of
      % pCh_in (row), checks against all rows of pCh_match and returns
      % indexing to matched rows.
      function [idx,mask] = matchProbeChannel(pCh_in,pCh_match)
         nCh = size(pCh_in,1);
         idx = nan(nCh,1);
         for ii = 1:nCh
            tmp = find(...
               (pCh_in(ii,1) == pCh_match(:,1)) & ...
               (pCh_in(ii,2) == pCh_match(:,2)),1,'first');
            if ~isempty(tmp)
               idx(ii) = tmp;
            end
         end
         mask = ~isnan(idx);
      end
      
      
      % Parse electrode layout from channel info struct
      function [x_grid_out,y_grid_out,ch_grid_out] = parseElectrodeOrientation(ch_info)
         x_grid = defaults.block('elec_grid_x');
         y_grid = defaults.block('elec_grid_y');
         ch_grid = defaults.block('elec_grid_ord');
         if strcmpi(ch_info(1).ml,'L')
            if contains(ch_info(1).area,'Left')
               % ch_grid matches x_grid, y_grid
               ch_grid_out = ch_grid;
               x_grid_out = x_grid;
               y_grid_out = y_grid;
            else
               % x_grid is correct, y_grid is flipped
               ch_grid_out = ch_grid;
               x_grid_out = x_grid;
               y_grid_out = fliplr(y_grid);
            end            
         else
            if contains(ch_info(1).area,'Left')
               % ch_grid needs to be flipped lr and ud to match x_grid,
               % y_grid (respectively)
               ch_grid_out = rot90(ch_grid,2);
               x_grid_out = x_grid;
               y_grid_out = y_grid;
            else
               % y_grid is correct, x_grid is flipped
               ch_grid_out = ch_grid;
               x_grid_out = flipud(x_grid);
               y_grid_out = y_grid;
            end 
         end
         
      end
      
      
   end
   
end

