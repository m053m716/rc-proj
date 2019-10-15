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
      Data           % Data struct
      T              % Time (sec)
   end
   
   properties (Access = private)
      Folder          % Full ANIMAL folder
      AllDaysScore
   end
   
   properties (Access = public, Hidden = true)
      ChannelMask          % Flag for each channel: true if GOOD
      HasData = false      % Flag to specify if it has data in it
      HasWarpData = false  % Flag to specify if rate data has been warped
      HasWarpedjPCA = false% Flag to specify if "warped jPCA" has been done
      HasDivergenceData = false; % Flag to specify if data comparing succ/unsucc trials in phase space is present
      IsOutlier = false    % Flag to specify that recording is outlier
      HasBases = false     % Flag to specify if bases were assigned from PC
      coeff                % Full matrix of PCA-defined basis vectors (columns)
      score                % Relative weighting of each PC
      x                    % Smoothed average rate used to compute PCs
      t                    % Decimated time-steps corresponding to coeff columns
      score_ch_idx         % Indices into ChannelInfo for elements of 'score'
      pc_idx               % Cutoff to reach desired % explained data
      p                    % Explained data for each PC
      P                    % Projection matrix to re-express top PCs
      RMSE                 % Final value of optimizer function for rebase
      tSnap                % Time relative to behavior to "snap" a video frame, for each trial
   end
   
   methods (Access = public)
      % Block object class constructor
      function obj = block(path,align,doSpikeRateExtraction,runJPCAonConstruction)
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
            align = defaults.jPCA('jpca_align');
         end
         
         if nargin < 3
            doSpikeRateExtraction = defaults.block('do_spike_rate_extraction');
         end
         
         if nargin < 4
            runJPCAonConstruction = defaults.block('run_jpca_on_construction');
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
            obj.doSpikeBinning(behaviorData);            
            obj.doBinSmoothing;
            obj.doRateDownsample;
            fprintf(1,'Rate extraction for %s complete.\n\n',obj.Name);

         end
         updateBehaviorData(obj);
         
         o = defaults.block('all_outcomes');
         e = defaults.block('all_events');
         for iE = 1:numel(e)
            for iO = 1:numel(o)
               updateSpikeRateData(obj,e{iE},o{iO});
            end
         end
%          updateSpikeRateData(obj,align,'Successful');
%          updateSpikeRateData(obj,align,'Unsuccessful');
         
         if runJPCAonConstruction
            jPCA(obj);
            jPCA_project(obj);
            jPCA_unsuccessful(obj);
            
         end
%          getChannelwiseRateStats(obj,align,'Successful');
         
      end

      % To handle case where obj.behaviorData is referenced accidentally 
      % instead of using loadbehaviorData method.
      function [b,flag] = behaviorData(obj)
         flag = true(size(obj));
         if numel(obj) > 1
            
            b = [];
            for ii = 1:numel(obj)
               [tmp,flag(ii)] = behaviorData(obj(ii));
               b = [b; tmp];
            end
         end
         
         b = loadBehaviorData(obj);
         if isempty(b)
            flag = false;
         end
         
      end
      
      % Remove "Outlier" status
      function clearOutlier(obj)
         if obj.IsOutlier
            obj.IsOutlier = false;
            fprintf(1,'%s marked as NOT an Outlier.\n',obj.Name);
         end
      end
      
      % Smooth spike rates
      function doBinSmoothing(obj,w)
         W = defaults.block('spike_bin_w');
         if nargin < 2 % Smooth width, in bin indices
            w = round(defaults.block('spike_smoother_w')/W);
         end
         
         ALIGN = defaults.block('all_alignments');
         EVENT = defaults.block('all_events');
         outpath = obj.getPathTo('spikerate');
         
         for iE = 1:numel(EVENT)
            for iA = 1:size(ALIGN,1)
               savename = sprintf(...
                  '%s_SpikeRate%03gms_%s_%s.mat',obj.Name,w,...
                  EVENT{iE},ALIGN{iA,1});
               
               if (exist(fullfile(outpath,savename),'file')==0) || ...
                     defaults.block('overwrite_old_spike_data')
               
                  [data,t] = obj.loadBinnedSpikes(EVENT{iE},ALIGN{iA,1},W); %#ok<ASGLU>
                  if isempty(data)
                     continue;
                  end
                  for iCh = 1:numel(obj.ChannelInfo)
                     data(:,:,iCh) = sqrt(max(fastsmooth(data(:,:,iCh),w,'pg',1,1)./mode(diff(obj.T)),0));
                  end

                  if exist(outpath,'dir')==0
                     mkdir(outpath);
                  end
                  save(fullfile(outpath,savename),'data','t');
                  fprintf(1,'-->\tSaved %s\n',savename);
               end
            end
         end
         
         
      end
      
      % Put spikes into bins
      function data = doSpikeBinning(obj,behaviorData,w)
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
         
         ALIGN = defaults.block('all_alignments');
         EVENT = defaults.block('all_events');
         start_stop_bin = defaults.block('start_stop_bin');
         vec = start_stop_bin(1):w:start_stop_bin(2);      
         t = vec(1:(end-1)) + mode(diff(vec))/2;
         outpath = obj.getPathTo('spikerate');
         if exist(outpath,'dir')==0
            mkdir(outpath);
         end
%          [~,idx] = unique(behaviorData.Grasp);
%          behaviorData = behaviorData(idx,:); % ensure only unique grasps
         
         for iE = 1:numel(EVENT)
            for iA = 1:size(ALIGN,1)
               
               
               savename = sprintf(...
                  '%s_BinnedSpikes%03gms_%s_%s.mat',obj.Name,w,...
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
      
      % Downsample the smoothed/normalized spike rates (and save)
      function doRateDownsample(obj)
         n_ds_bin_edges = defaults.block('n_ds_bin_edges');
         r_ds = defaults.block('r_ds');
         
         w = defaults.block('spike_smoother_w');
         fStr_in = '%s_SpikeRate%03gms_%s_%s.mat';
         fStr_out = '%s_NormSpikeRate%03gms_%s_%s_ds.mat';
         o = defaults.block('all_outcomes');
         e = defaults.block('all_events');
         for iO = 1:numel(o)
            for iE = 1:numel(e)
               % Skip if there is no file to decimate
               str = sprintf(fStr_in,obj.Name,w,e{iE},o{iO});
               fName_In = fullfile(obj.getPathTo('rate'),str);
               if exist(fName_In,'file')==0
                  continue;
               end
               
               % Skip if it's already been extracted
               str = sprintf(fStr_out,obj.Name,w,e{iE},o{iO});
               fName_Out = fullfile(obj.getPathTo('rate'),str);
               if exist(fName_Out,'file')~=0
                  continue;
               else
                  fprintf(1,'Extracting %s...\n',fName_Out);
               end
               in = load(fName_In,'data','t');
               if isfield(in,'t')
                  if ~isempty(in.t)
                     out.t = linspace(in.t(1),in.t(end),n_ds_bin_edges);
                  else
                     out.t = linspace(obj.T(1),obj.T(end),n_ds_bin_edges);
                  end
               else
                  out.t = linspace(obj.T(1),obj.T(end),n_ds_bin_edges);
               end
               
               data = obj.doSmoothNorm(in.data);
               out.data = zeros(size(data,1),n_ds_bin_edges,size(data,3));
               for ii = 1:size(data,1)
                  for ik = 1:size(data,3)
                     out.data(ii,:,ik) = decimate(data(ii,:,ik),r_ds);
                  end
               end
               save(fName_Out,'-struct','out');
                                                            
            end
         end
         
                  
      end
      
      % Export jPCA movie for RFA-only and CFA-only rotations
      function export_jPCA_RFA_CFA_movie(obj,align,outcome)
         if nargin < 3
            outcome = defaults.block('outcome');
         end
         
         if nargin < 2
            align = defaults.block('alignment');
         end
         
         % Parse arrays
         if numel(obj) > 1
            for ii = 1:numel(obj)
               export_jPCA_RFA_CFA_movie(obj(ii),align,outcome);
            end
            return;
         end
         

         if ~isfield(obj.Data.(align),outcome)
            fprintf(1,'%s: %s outcomes not obtained yet (for %s alignment).\n',...
               obj.Name,outcome,align);
            return;
         end
         
         if ~isfield(obj.Data.(align).(outcome),'jPCA')
            fprintf(1,'jPCA not yet run for %s.\n',obj.Name);
            return;
         end
         
         vid_folder = defaults.jPCA('video_export_base');
         cvid_folder = fullfile(vid_folder,outcome,'CFA');
         rvid_folder = fullfile(vid_folder,outcome,'RFA');
         movie_params = defaults.jPCA('movie_params',...
            obj.Data.(align).(outcome).jPCA.Summary.outcomes);
         moviename = sprintf('%s_%s_PostOpDay-%02g',...
                  align,...
                  obj.Parent.Name,...
                  obj.PostOpDay);
         movie_params.movieName = moviename;
         
         if ~isempty(obj.Parent)
            if ~isempty(obj.Parent.Parent)
               cmoviename = fullfile(pwd,...
                  cvid_folder,obj.Parent.Parent.Name,obj.Parent.Name,moviename);
               rmoviename = fullfile(pwd,...
                  rvid_folder,obj.Parent.Parent.Name,obj.Parent.Name,moviename);
            else
               cmoviename = fullfile(pwd,...
                  cvid_folder,obj.Parent.Name,moviename);
               rmoviename = fullfile(pwd,...
                  rvid_folder,obj.Parent.Name,moviename);
            end
            
         else
            cmoviename = fullfile(pwd,cvid_folder,moviename);
            rmoviename = fullfile(pwd,rvid_folder,moviename);
         end
         output_score = defaults.group('output_score');
         movie_params.score = obj.(output_score);
                  
         tic;
         fprintf(1,'Exporting CFA video:\n-->\t\t%s\n',cmoviename);
         cMV = jPCA.phaseMovie(...
            obj.Data.(align).(outcome).jPCA.CFA.Projection,...
            obj.Data.(align).(outcome).jPCA.CFA.Summary, ...
            movie_params);
         export_jPCA_movie(cMV,cmoviename);
         clear cMV
         fprintf(1,'Exporting RFA video:\n-->\t\t%s\n',rmoviename);
         rMV = jPCA.phaseMovie(...
            obj.Data.(align).(outcome).jPCA.RFA.Projection,...
            obj.Data.(align).(outcome).jPCA.RFA.Summary, ...
            movie_params);
         jPCA.export_jPCA_movie(rMV,rmoviename);
         clear rMV
         toc;
      end
      
      % Returns table of stats for all child Block objects where each row
      % is a reach trial. Essentially is behaviorData of each child object,
      % with appended metadata for each child object.
      function T = exportTrialStats(obj)
         if numel(obj) > 1
            T = [];
            for ii = 1:numel(obj)
               T = [T; exportTrialStats(obj(ii))];
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
      
      % Format down-sampled rate data for dPCA
      function [X,t] = format_dPCA(obj)
         % Parse array input
         if numel(obj) > 1
            X = cell(numel(obj),1);
            for ii = 1:numel(obj)
               [X{ii},t] = format_dPCA(obj(ii)); % t is always the same
            end
            return;
         end
         
         p = defaults.dPCA;
         addpath(p.local_repo_loc);
         
         X = [];
         t = [];
         
         [g,flag_exists,flag_isempty] = obj.getRate('Grasp','All');
         if (~flag_exists) || (flag_isempty)
            fprintf(1,'No grasp rate data in %s.\n',obj.Name);
            return;
         end
         
         % Get reduced number of timesteps
         t = obj.Data.Grasp.All.t;
         t_idx = (t >= p.t_start) & (t <= p.t_stop);
         t = t(t_idx);
         
         g = g(:,t_idx,:);
         % Three outcomes: 
         % iPP_succ (pellet present, successful);
         % iPP_unsucc (pellet present, unsuccessful); 
         % iPA_unsucc (pellet absent, unsuccessful)
         iPP_succ = find(obj.Data.Outcome);
         nTrial = numel(iPP_succ);
         iPP_unsucc = find(~obj.Data.Outcome & obj.Data.Pellet.present);
         nTrial = [nTrial, numel(iPP_unsucc)];
         iPA_unsucc = find(~obj.Data.Pellet.present);
         nTrial = [nTrial, numel(iPA_unsucc)];
         trialIndex = {iPP_succ,iPP_unsucc,iPA_unsucc};
         nTrialMax = max(nTrial);
         
         if any(nTrial < 1)
            X = []; 
            return;
         end
         
         % # neurons x 1 (day) x 3 (outcomes) x # timesteps (sum(t_idx)) x
         % # trials
         X = nan(size(g,3),1,3,size(g,2),nTrialMax);
         for iNeu = 1:size(g,3)
            for iOutcome = 1:numel(nTrial)
               for iTrial = 1:nTrial(iOutcome)
                  idx = trialIndex{iOutcome}(iTrial);
                  X(iNeu,1,iOutcome,:,iTrial) = g(idx,:,iNeu);
               end               
            end
         end
            
      end
      
      % Return spike rate data and associated metadata
      function [avgRate,channelInfo] = getAvgSpikeRate(obj,align,outcome,ch)
         if nargin < 4
            ch = nan;
         end
         if nargin < 3
            outcome = 'Successful'; % 'Successful' or 'Unsuccessful' or 'All'
         end
         if nargin < 2
            align = 'Grasp'; % 'Grasp' or 'Reach'
         end
         
         if numel(obj) > 1
            avgRate = [];
            channelInfo = [];
            for ii = 1:numel(obj)
               [tmpRate,tmpCI] = getAverageSpikeRate(obj(ii),align,outcome,ch);
               avgRate = [avgRate; tmpRate]; %#ok<*AGROW>
               channelInfo = [channelInfo; tmpCI];
            end
            return;
         end
         
         if isnan(ch)
            ch = 1:numel(obj.ChannelInfo);
         end
         
         obj = obj([obj.HasData]);
         avgRate = [];
         channelInfo = [];
         filter_order = defaults.block('lpf_order');
         fs = defaults.block('fs');
         cutoff_freq = defaults.block('lpf_fc');
         if ~isnan(cutoff_freq)
            [b,a] = butter(filter_order,cutoff_freq/(fs/2),'low');
         end

         avgRate = nan(numel(ch),numel(obj.T));
         channelInfo = [];
         idx = 0;
         for iCh = ch
            idx = idx + 1;
            channelInfo = [channelInfo; obj.ChannelInfo(iCh)];
            if obj.ChannelMask(iCh)
               if isfield(obj.Data,align)
                  if isfield(obj.Data.(align),outcome)
                     x = obj.Data.(align).(outcome).rate(:,:,iCh);
                  else
                     fprintf('No %s rate extracted for %s alignment for block %s. Extracting...\n',...
                        outcome,align,obj.Name);
                     obj.updateSpikeRateData(align,outcome);
                     if ~isfield(obj.Data.(align),outcome)
                        continue;
                     end
                     x = obj.Data.(align).(outcome).rate(:,:,iCh);
                  end
               else
                  fprintf('No %s rate extracted for block %s. Extracting...\n',...
                        align,obj.Name);
                  obj.updateSpikeRateData(align,outcome);
                  if ~isfield(obj.Data,align)
                     continue;
                  elseif ~isfield(obj.Data.(align),outcome)
                     continue;
                  end
                  x = obj.Data.(align).(outcome).rate(:,:,iCh);
               end

               mu = mean(x,1); %#ok<*PROPLC,*PROP>

               if isnan(cutoff_freq)
                  avgRate(idx,:) = mu;
               else
                  avgRate(idx,:) = filtfilt(b,a,mu);
               end
            end
         end

      end
      
      % Return (normalized) spike rate data and associated metadata
      function [avgRate,channelInfo,t] = getAvgNormRate(obj,align,outcome,ch)
         if nargin < 4
            ch = nan;
         end
         if nargin < 3
            outcome = 'Successful'; % 'Successful' or 'Unsuccessful' or 'All'
         end
         if nargin < 2
            align = 'Grasp'; % 'Grasp' or 'Reach'
         end
         
         if numel(obj) > 1
            avgRate = [];
            channelInfo = [];
            for ii = 1:numel(obj)
               [tmpRate,tmpCI,t] = getAverageSpikeRate(obj(ii),align,outcome,ch);
               avgRate = [avgRate; tmpRate]; %#ok<*AGROW>
               channelInfo = [channelInfo; tmpCI];
            end
            return;
         end
         
         if isnan(ch)
            ch = 1:numel(obj.ChannelInfo);
         end
         
         obj = obj([obj.HasData]);
         avgRate = [];
         channelInfo = [];
         t = [];
         
         if isfield(obj.Data,align)
            if isfield(obj.Data.(align),outcome)
               if isfield(obj.Data.(align).(outcome),'t')
                  t = obj.Data.(align).(outcome).t;
               else
                  fprintf('No %s trials for %s alignment for block %s.\n',...
                     outcome,align,obj.Name);
                  return;
               end
            else
               fprintf('No %s rate extracted for %s alignment for block %s. Extracting...\n',...
                  outcome,align,obj.Name);
               obj.updateSpikeRateData(align,outcome);
               if ~isfield(obj.Data.(align),outcome)
                  fprintf('Invalid field for %s: %s\n',obj.Name,outcome);
                  return;
               end
            end
         else
            obj.updateSpikeRateData(align,outcome);
            if ~isfield(obj.Data,align)
               fprintf('Invalid field for %s: %s\n',obj.Name,align);
               return;
            elseif ~isfield(obj.Data.(align),outcome)
               fprintf('Invalid field for %s: %s\n',obj.Name,outcome);
               return;
            else
               t = obj.Data.(align).(outcome).t;
            end
         end
         
         if ~isempty(t)
            if max(abs(t) < 10)
               t = t.*1e3; % Scale if it is not already scaled to ms
            end
         end
         

         avgRate = nan(numel(ch),numel(t));
         channelInfo = [];
         idx = 0;
         fs = defaults.block('fs') / defaults.block('r_ds');
         for iCh = ch
            idx = idx + 1;
            channelInfo = [channelInfo; obj.ChannelInfo(iCh)];
            if obj.ChannelMask(iCh)
               x = obj.Data.(align).(outcome).rate(:,:,iCh);
               avgRate(idx,:) = obj.doSmoothOnly(x,fs);
            end
         end

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
               Projection = [];
               Summary = [];
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
                     getChannelwiseRateStats(obj(ii),align,outcome)];
               end
            end
            return;
         end
         
         field_expr = sprintf('Data.%s.%s.rate',align,outcome);
         [x,isFieldPresent] = parseStruct(obj.Data,field_expr);         
         if ~isFieldPresent || isempty(x)
            fprintf(1,'%s: missing rate for %s.\n',obj.Name,field_expr);
            return;
         end
         t = obj.Data.(align).(outcome).t;
         
         % Do some rearranging of data
         file = {obj.ChannelInfo.file}.';
         probe = {obj.ChannelInfo.probe}.';
         channel = {obj.ChannelInfo.channel}.';
         ml = {obj.ChannelInfo.ml}.';
         icms = {obj.ChannelInfo.icms}.';
         area = {obj.ChannelInfo.area}.';
         
         mu = squeeze(mean(x,1)); % result: nTimestep x nChannel array
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
         tMaxRate = num2cell(t(tMaxRate).');
%          minRate = num2cell(sqrt(abs((max(minRate,eps)./mode(diff(obj.T))))).');
         minRate = num2cell(minRate.');
         tMinRate = num2cell(t(tMinRate).');
%          muRate = num2cell(mean(abs(sqrt(max(mu,eps)./mode(diff(obj.T)))),1).');
%          medRate = num2cell(median(abs(sqrt(max(mu,eps)./mode(diff(obj.T)))),1).');
         
         % For 20ms kernel:
%          c = 0.3;
%          e = 0.000;
         
         c = 0.109;
         e = 0.000;
         
%          x = sqrt(abs(max(x./mode(diff(obj.T)),eps)));
%          stdRate = num2cell(sqrt(mean(squeeze(var(x(:,idx,:),[],1)),1).'));
         NV = squeeze(c * (e + sum((x - mean(x,1)).^2,1)./(size(x,1)-1))./(c*e + mean(x,1)));
%          NV = obj.applyLPF2Rate(NV,obj.T,false).';
         NV = NV.';
         dNV = min(NV(:,(t >   100) & (t <= 300)),[],2) ... % min var AFTER GRASP
             - max(NV(:,(t >= -300) & (t < -100)),[],2);    % max var BEFORE GRASP
         
         NV = mat2cell(NV,ones(1,size(NV,1)),size(NV,2));
         dNV = num2cell(dNV);
         normRate = mat2cell(mu.',ones(1,numel(maxRate)),numel(t));
         
         
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
            
            Name = repmat({obj.Name},numel(tmp),1);
            PostOpDay = repmat(obj.PostOpDay,numel(tmp),1);
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
            
            stats = [table(Rat,Name,Group,PostOpDay,Score,nTrial),struct2table(tmp)];
            stats.area = cellfun(@(x) {x((end-2):end)},stats.area);
         end
         
      end
      
      % Return property associated with each channel, per unmasked channel
      function  out = getPropForEachChannel(obj,propName)
         out = [];
         if numel(obj) > 1
            for ii = 1:numel(obj)
               out = [out;getPropForEachChannel(obj(ii),propName)];
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
      
      % Get median offset latency (ms) between two behaviors
      function offset = getOffsetLatency(obj,align1,align2)
         if numel(obj) > 1
            error('Method only works on scalar objects.');
         end
         
         if nargin < 3
            align2 = defaults.block('alignment');
         end
         
         if nargin < 2
            error('Must specify a comparator alignment: (Reach, Grasp, Support, Complete)');
         end
         
         
         if ~ismember(align1,{'Reach','Grasp','Support','Complete'})
            error('Invalid alignment. Must specify from: (Reach, Grasp, Support, Complete)');
         end
         
         b = loadBehaviorData(obj);
         idx = ~isinf(b.(align1)) & ~isnan(b.(align1)) & ...
               ~isinf(b.(align2)) & ~isnan(b.(align2));
         a1 = b.(align1)(idx);
         a2 = b.(align2)(idx);
         
         offset = median(a1 - a2) * 1e3; % return in milliseconds
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
               phaseData = [phaseData; getPhase(obj(ii),align,outcome,area)];
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
         
         Name = {obj.Name};
         Score = obj.(defaults.group('output_score'));
         PostOpDay = obj.PostOpDay;
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
         phaseData = table(Rat,Name,Group,PostOpDay,Score,Align,Outcome,Area,{tmp});
         phaseData.Properties.VariableNames{end} = 'phaseData';
         
      end
      
      % Helper method to get paths to stuff
      function path = getPathTo(obj,dataType)
         switch lower(dataType)
            case 'channelmask'
               channel_mask_loc = defaults.block('channel_mask_loc');
               path = fullfile(pwd,channel_mask_loc);
            case 'tank'
               path = defaults.experiment('tank');
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
                  [obj.Name '_SpikeAnalyses']);
            case {'vid','video','behaviorvid','rcvids','vids','videos','dlc'}
               behavior_vid_loc = defaults.block('behavior_vid_loc');
               path = fullfile(behavior_vid_loc);
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
               out = [out; obj(ii).(propName)];
            elseif isprop(obj(ii),propName)
               out = [out; {obj(ii).(propName)}];
            end
         end
      end
      
      % Returns rate for a given field configuration, if it exists
      function [rate,flag_exists,flag_isempty] = getRate(obj,align,outcome,area)
         if numel(obj) > 1
            rate = cell(numel(obj),1);
            flag_exists = false(numel(obj),1);
            flag_isempty = false(numel(obj),1);
            for ii = 1:numel(obj)
               switch nargin
                  case 4
                     [rate{ii},flag_exists(ii),flag_isempty(ii)] = ...
                        obj(ii).getRate(align,outcome,area);
                  case 3
                     [rate{ii},flag_exists(ii),flag_isempty(ii)] = ...
                        obj(ii).getRate(align,outcome);
                  case 2
                     [rate{ii},flag_exists(ii),flag_isempty(ii)] = ...
                        obj(ii).getRate(align);
                  otherwise
                     error('Invalid number of input arguments (%g).',nargin);
               end
            end
            return;
         end
         
         switch nargin
            case 4
               field_expr = sprintf('Data.%s.%s.%s.rate',align,outcome,area);
            case 3
               field_expr = sprintf('Data.%s.%s.rate',align,outcome);
            case 2
               field_expr = sprintf('Data.%s.rate',align);
            otherwise
               error('Invalid number of input arguments (%g).',nargin);
         end
         
         [rate,flag_exists,flag_isempty] = parseStruct(obj.Data,field_expr);
         if (flag_exists) && (~flag_isempty)
            rate = rate(:,:,obj.ChannelMask);
         end
         
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
               out = [out; obj(ii).Parent.Data.(propName)];
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
      
      % Do jPCA analysis on this recording
      function [Projection,Summary] = jPCA(obj,align)
         if nargin < 2
            align = defaults.jPCA('jpca_align');
         end
         
         % Parse arrays
         if numel(obj) > 1
            if nargout > 1
               Projection = cell(size(obj));
               Summary = cell(size(obj));
               for ii = 1:numel(obj)
                  [Projection{ii},Summary{ii}] = jPCA(obj(ii));
               end
            else
               for ii = 1:numel(obj)
                  jPCA(obj(ii));
               end
            end
            return;
         end
         
         % If no output arguments, then close all current figures and print
         % the generated ones to pdf files
         if nargout < 1
            close all force;
         end
         
         % Only allow SUCCESSFUL alignment for initial jPCA extraction
         D = obj.jPCA_format(align,'Successful');
         
         jpca_params = defaults.jPCA('jpca_params',ones(numel(D),1));
         analyze_times = defaults.jPCA('analyze_times');
         if numel(D) < 3
            fprintf(1,'Too few successful %s trials for %s (%g).\n',...
               align,obj.Name,numel(D));
            Projection = [];
            Summary = [];
            return;
         end
         
         [Projection,Summary] = jPCA.jPCA(D,analyze_times,jpca_params);
         obj.Data.(align).Successful.jPCA.Full.Projection = Projection;
         obj.Data.(align).Successful.jPCA.Full.Summary = Summary;
         
         if nargout < 1
            obj.jPCA_save_previews(align,'Successful','Full');
         end
      end
      
      % Helper function to determine if alignment/outcome is viable
      function flag = jPCA_check(obj,align,outcome,area)
         flag = false;
         if ~isfield(obj.Data,align)
            fprintf(1,'Missing Data field: %s. Getting rate data.\n',align);
            obj.updateSpikeRateData(align,'Successful');
            obj.updateSpikeRateData(align,'Unsuccessful');
         end
         
         if ~isfield(obj.Data,align)
            fprintf(1,'-->\tNo rate data to extract.\n');
            flag = true;
            return;
         end
         
         if nargin == 2
            if ~isfield(obj.Data.(align).Successful,'jPCA')
               fprintf(1,'Too few successful %s trials for jPCA.\n',align);
               flag = true;
               return;
            end
         end
         
         if nargin > 2 % Check outcome as well
            if ~isfield(obj.Data.(align),outcome)
               fprintf(1,'%s: %s outcomes not obtained yet (for %s alignment).\n',...
                  obj.Name,outcome,align);
               obj.updateSpikeRateData(align,outcome);
            end

            if ~isfield(obj.Data.(align),outcome)
               fprintf(1,'-->\tNo rate data to extract.\n');
               flag = true;
               return;
            end
            
         end
         
         if nargin > 3 % Check area as well
            if ~isfield(obj.Data.(align).(outcome),'jPCA')
               fprintf(1,'-->Too few %s trials for jPCA.\n',outcome);
               flag = true;
               return;
            end
            
            if ~isfield(obj.Data.(align).(outcome).jPCA,area)
               fprintf(1,'%s: %s-%s outcomes not obtained yet (for %s alignment).\n',...
                  obj.Name,outcome,align,area);
               flag = true;
               return;
            end            
         end
      end
      
      % Helper function that returns the formatted rate data for jPCA
      function [D,idx] = jPCA_format(obj,align,outcome,area)
         % Initialize output
         D = [];
         idx = [];
         
         if nargin < 2
            align = defaults.jPCA('jpca_align');
         end
         
         if nargin < 3
            outcome = 'All';
         end
         
         if nargin < 4
            area = 'Full';            
         end
         
         % Parse array
         if numel(obj) > 1
            for ii = 1:numel(obj)
               [dTmp,idxTmp] = jPCA_format(obj(ii),align,outcome,area);
               D = [D; dTmp];
               idx = [idx; idxTmp * ii];
            end
            return;
         end
         
         flag = obj.jPCA_check(align,outcome);
         if (flag)
            return;
         end
         
         if isempty(obj.Data.(align).(outcome).rate)
            fprintf(1,'No %s %s trials for %s.\n',outcome,align,obj.Name);
            return
         end
         
         x = obj.Data.(align).(outcome).rate(:,:,obj.ChannelMask);
         if strcmpi(area,'RFA') || strcmpi(area,'CFA')
            ch_idx = contains({obj.ChannelInfo(obj.ChannelMask).area},area);
            x = x(:,:,ch_idx);
         end
         
         filter_order = defaults.block('lpf_order');
         fs = 1/((defaults.block('spike_bin_w')*1e-3));
         cutoff_freq = defaults.block('lpf_fc');
         if ~isnan(cutoff_freq)
            [b,a] = butter(filter_order,cutoff_freq/(fs/2),'low');
         else
            b = nan; a = nan;
         end
         
         jpca_decimation_factor = defaults.jPCA('jpca_decimation_factor');
         jpca_start_stop_times = defaults.jPCA('jpca_start_stop_times');         
         
         D = jPCA.format(...
            x,...
            obj.T*1e3,...
            b,...
            a,...
            jpca_decimation_factor,...
            jpca_start_stop_times);
         idx = ones(numel(D),1);
      end
      
      % Helper function that returns the formatted rate data for jPCA
      function [D,idx,outcomes] = jPCA_format_warped(obj,outcome)
         % Initialize output
         D = [];
         idx = [];
         
         if nargin < 2
            outcome = 'Successful';
         end
         
         % Parse array
         if numel(obj) > 1
            for ii = 1:numel(obj)
               [dTmp,idxTmp] = jPCA_format_warped(obj(ii),outcome);
               D = [D; dTmp];
               idx = [idx; idxTmp * ii];
            end
            return;
         end
         
         if ~obj.HasWarpData
            return;
         end

         switch outcome
            case 'Successful'
               iMatch = 1;
            case 'Unsuccessful'
               iMatch = 2;
            case 'All'
               iMatch = [1,2];
            otherwise
               fprintf(1,'%s: invalid outcome (%s)\n',obj.Name,outcome);
               return;
         end
         
         o = obj.Data.Warp.label;
         idx = ismember(o,iMatch);
         
         D = jPCA.formatWarped(...
            obj.Data.Warp.rate(idx,:,:),...
            obj.Data.Warp.time(idx,:,:));
         idx = ones(numel(D),1);
         outcomes = o(idx);
      end
      
      % Export jPCA movie for full dataset 
      function jPCA_movie(obj,align,outcome,area)
         if nargin < 4
            area = 'Full';
         end
         
         if nargin < 3
            outcome = 'Successful';
         end
         
         if nargin < 2
            align = defaults.jPCA('jpca_align');
         end
         
         % Parse arrays
         if numel(obj) > 1
            for ii = 1:numel(obj)
               jPCA_movie(obj(ii),align,outcome,area);
            end
            return;
         end
         
         if obj.jPCA_check(align,outcome)
            fprintf(1,'-->\tCould not create movie (%s: %s-%s)\n',obj.Name,...
               outcome,align);
            return;
         end
         
         vid_folder = fullfile(defaults.jPCA('video_export_base'),...
            outcome,area);
         output_score = defaults.group('output_score');
         movie_params = defaults.jPCA('movie_params',...
            obj.Data.(align).(outcome).jPCA.(area).Summary.outcomes,...
            obj.(output_score));
         
         
         moviename = sprintf('%s_%s_PostOpDay-%02g',...
            obj.Parent.Name,...
            align,...
            obj.PostOpDay);
         movie_params.movieName = moviename;
         
         if ~isempty(obj.Parent)
            if ~isempty(obj.Parent.Parent)
               moviename = fullfile(pwd,...
                  vid_folder,obj.Parent.Parent.Name,obj.Parent.Name,moviename);
            else
               moviename = fullfile(pwd,...
                  vid_folder,obj.Parent.Name,moviename);
            end
         else
            moviename = fullfile(pwd,vid_folder,moviename);
         end
         tic;
         
         fprintf(1,'Exporting video:\n-->\t\t%s\n',moviename);
         MV = jPCA.phaseMovie(...
            obj.Data.(align).(outcome).jPCA.(area).Projection,...
            obj.Data.(align).(outcome).jPCA.(area).Summary, ...
            movie_params);
         jPCA.export_jPCA_movie(MV,moviename);
         clear MV;
         toc;
      end
      
      % Project unsuccessful trials onto jPCA plane using jPCs from success
      function [Projection,Summary] = jPCA_unsuccessful(obj,align)         
         if nargin < 2
            align = defaults.jPCA('jpca_align');
         end
         
         if numel(obj) > 1
            if nargout > 1
               Projection = cell(numel(obj),1);
               Summary = cell(numel(obj),1);
            end
            for ii = 1:numel(obj)
               if nargout > 1
                  [Projection{ii},Summary{ii}] = jPCA_unsuccessful(obj(ii),align);
               else
                  jPCA_unsuccessful(obj(ii),align);
               end
            end
            return;
         end
         
         if ~isfield(obj.Data.(align).Unsuccessful,'rate')
            fprintf(1,'%s: missing rate for unsuccessful trials.\n',obj.Name);
            return;
         end
         
         close all force;
         
         x = obj.Data.(align).Unsuccessful.rate;
         if size(x,1) < 3
            Summary = [];
            Projection = [];
            fprintf(1,'-->\tNot enough trials for unsuccessful jPCA on %s.\n',obj.Name);
            return;
         else
            x = x(:,:,obj.ChannelMask);
         end
         
         if obj.jPCA_check(align,'Successful','Full')
            Summary = [];
            Projection = [];
            fprintf(1,'-->\tNo successful jPCs yet for %s.\n',obj.Name);
            return;
         end
         
         Summary = obj.Data.(align).Successful.jPCA.Full.Summary;
         Summary.outcomes = ones(size(x,1),1)*2;
         
         allTimes = Summary.allTimes;
         times = Summary.times;
         jPCs_highD = Summary.jPCs_highD;
         PCs = Summary.PCs;
         mu = Summary.preprocessing.meanFReachNeuron;
         norms = Summary.preprocessing.normFactors;
         
         fprintf(1,'-->\tCollecting unsuccessful jPCA data for %s.\n',obj.Name);
         Projection = [];
         for ii = 1:size(x,1)
            Projection = [Projection, ...
               makeTrialCondition(...
                  squeeze(x(ii,:,:)),...
                  obj.T*1e3,...
                  times,...
                  allTimes,...
                  PCs,...
                  jPCs_highD,...
                  mu,...
                  norms)];
         end
         
         jpca_params = defaults.jPCA('jpca_params');
         numPCs = size(Summary.PCs,2);
         circStats = cell(numPCs/2,1);
         for jPCplane = 1:(numPCs/2)
            phaseData = jPCA.getPhase(Projection, jPCplane);
            if ~jpca_params.suppressBWrosettes
               jPCA.plotRosette(Projection,jPCplane,Summary.varCaptEachPlane(jPCplane));
            end
            circStats{jPCplane} = jPCA.plotPhaseDiff(phaseData,jPCplane,...
               jpca_params.suppressHistograms);
         end
         Summary.circStats = circStats;
         Summary.numTrials = size(x,1);
         
         obj.Data.(align).Unsuccessful.jPCA.Full.Projection = Projection;
         obj.Data.(align).Unsuccessful.jPCA.Full.Summary = Summary;
         
         if nargout < 1
            obj.jPCA_save_previews(align,'Unsuccessful','Full');
         end
      end
      
      % Project all trials onto jPCA plane using jPCs from success only
      function [Projection,Summary] = jPCA_project(obj,align,Summary,x,area,doAssignment)
         if nargin < 2
            align = defaults.jPCA('jpca_align');
         end
         
         if nargin < 5
            area = 'Full';
         end
         
         if nargin < 6
            doAssignment = true;
         end
         
         if nargin < 3
            if obj.jPCA_check(align,'Successful',area)
               fprintf(1,'No successes for jPC projection: %s.\n',obj.Name);
               Projection = [];
               Summary = [];
               return;
            end
            Summary = obj.Data.(align).Successful.jPCA.Full.Summary;
         elseif isempty(Summary)
            if obj.jPCA_check(align,'Successful',area)
               fprintf(1,'No successes for jPC projection: %s.\n',obj.Name);
               Projection = [];
               Summary = [];
               return;
            end
            Summary = obj.Data.(align).Successful.jPCA.(area).Summary;
            if isempty(Summary)
               fprintf(1,'No successes for jPC projection: %s.\n',obj.Name);
               Projection = [];
               return;
            end
         end
         
         if nargin < 4
            x = nan;
         end
         
         % Parse arrays
         if numel(obj) > 1
            for ii = 1:numel(obj)
               jPCA_project(obj(ii),align,Summary,x,area);
            end
            return;
         end         
         
         if isnan(x(1))
            if isempty(obj.Data.(align).Successful.rate)
               x = obj.Data.(align).Unsuccessful.rate(:,:,obj.ChannelMask);
            elseif isempty(obj.Data.(align).Unsuccessful.rate)
               x = obj.Data.(align).Successful.rate(:,:,obj.ChannelMask);
            elseif isempty(obj.Data.(align).Successful.rate) && ...
                  isempty(obj.Data.(align).Unsuccessful.rate)
               fprintf(1,'No rate data in %s. Unified jPCA not possible.\n',obj.Name);
               Projection = [];
               Summary = [];
               return;
            else
               x = cat(1,...
                  obj.Data.(align).Successful.rate(:,:,obj.ChannelMask),...
                  obj.Data.(align).Unsuccessful.rate(:,:,obj.ChannelMask));
            end
            if strcmpi(area,'RFA') || strcmpi(area,'CFA')
               ch_idx = contains({obj.ChannelInfo(obj.ChannelMask).area},area);
               x = x(:,:,ch_idx);
            end
            
         end
         
         if size(x,1)<3
            Summary = [];
            Projection = [];
            fprintf(1,'-->\tNot enough trials for unified jPCA on %s.\n',obj.Name);
            return;
         end
         
         
         % Need to re-assign outcomes depending on state
         Summary.outcomes = ...
            [ones(size(obj.Data.(align).Successful.rate,1),1);...
             ones(size(obj.Data.(align).Unsuccessful.rate,1),1)*2];
         
         if ~isfield(Summary,'allTimes')
            Projection = [];
            fprintf(1,'%s: missing Summary.\n',obj.Name);
            return;
         end
         allTimes = Summary.allTimes;
         times = Summary.times;
         jPCs_highD = Summary.jPCs_highD;
         PCs = Summary.PCs;
         mu = Summary.preprocessing.meanFReachNeuron;
         norms = Summary.preprocessing.normFactors;

         Projection = [];
         for ii = 1:size(x,1)
            Projection = [Projection, ...
               makeTrialCondition(...
                  squeeze(x(ii,:,:)),...
                  obj.T*1e3,...
                  times,...
                  allTimes,...
                  PCs,...
                  jPCs_highD,...
                  mu,...
                  norms)];
         end

         jpca_params = defaults.jPCA('jpca_params');
         numPCs = size(Summary.PCs,2);
         circStats = cell(numPCs/2,1);
         for jPCplane = 1:(numPCs/2)
            phaseData = jPCA.getPhase(Projection, jPCplane);
            if ~jpca_params.suppressBWrosettes
               jPCA.plotRosette(Projection,jPCplane,Summary.varCaptEachPlane(jPCplane));
            end
            circStats{jPCplane} = jPCA.plotPhaseDiff(phaseData,jPCplane,...
               jpca_params.suppressHistograms);
         end
         Summary.circStats = circStats;
         Summary.numTrials = size(x,1);

         if doAssignment
            obj.Data.(align).All.jPCA.(area).Projection = Projection;
            obj.Data.(align).All.jPCA.(area).Summary = Summary;
         end

         if nargout < 1
            obj.jPCA_save_previews(align,'All',area);
         end       
         

      end
      
      % Save previews (BW rosettes / phase angle histograms)
      function jPCA_save_previews(obj,align,outcome,area)
         if nargin < 4
            area = 'Full';
         end
         r = get(gcf,'Parent'); % get "root"
         N = numel(r.Children); % count number of figures
         fname = cell(N,1);
         if ~isempty(obj.Parent)
            if ~isempty(obj.Parent.Parent)
               jpca_preview_folder = fullfile(pwd,defaults.jPCA('preview_folder'),outcome,area,obj.Parent.Parent.Name);
            else
               jpca_preview_folder = fullfile(pwd,defaults.jPCA('preview_folder'),outcome,area);
            end
            for ii = 1:round(N/2)
               fname{ii} = ...
                  sprintf('%s_%s_PostOp-%g_jPCA-plane-%g_rosette',...
                  obj.Parent.Name,align,obj.PostOpDay,ii);
               fname{ii+(round(N/2))} = ...
                  sprintf('%s_%s_PostOp-%g_jPCA-plane-%g_dPhase-hist',...
                  obj.Parent.Name,align,obj.PostOpDay,ii);
            end
         else
            jpca_preview_folder = fullfile(pwd,defaults.jPCA('preview_folder'),outcome,area);
            for ii = 1:round(N/2)
               fname{ii} = ...
                  sprintf('%s_%s_jPCA-plane-%g_rosette',obj.Name,align,ii);
               fname{ii+(round(N/2))} = ...
                  sprintf('%s_%s_jPCA-plane-%g_dPhase-hist',obj.Name,align,ii);
            end
         end
         if N > 1 % If the figures weren't suppressed:
            if exist(jpca_preview_folder,'dir')==0
               mkdir(jpca_preview_folder);
            end

            jPCA.printFigs(1:N,jpca_preview_folder,'-dpdf',fname);
         else
            delete(gcf);
         end
      end
      
      % Do jPCA analysis for CFA
      function [Projection,Summary] = jPCA_suppress(obj,active_area,align,outcome,doReProject)
         if strcmpi(active_area,'CFA')
            suppressed_area = 'RFA';
         elseif strcmpi(active_area,'RFA')
            suppressed_area = 'CFA';
         else
            Projection = [];
            Summary = [];
            fprintf(1,'''%s'' is not valid for [active_area] input. Must be ''CFA'' or ''RFA''.\n',active_area);
            return;
         end
         
         if nargin < 3
            align = defaults.jPCA('jpca_align');
         end
         
         if nargin < 4
            outcome = 'All';
         end
         
         if nargin < 5
            doReProject = false;
         end
         
         % Parse arrays
         if numel(obj) > 1
            if nargout > 1
               Projection = cell(size(obj));
               Summary = cell(size(obj));
               for ii = 1:numel(obj)
                  [Projection{ii},Summary{ii}] = jPCA_suppress(obj(ii),active_area,align,outcome,doReProject);
               end
            else
               for ii = 1:numel(obj)
                  jPCA_suppress(obj(ii),active_area,align,outcome,doReProject);
               end
            end
            return;
         end
         
         % If no output arguments, then close all current figures and print
         % the generated ones to pdf files
         if nargout < 1
            close all force;
         end
         
         if ~isfield(obj.Data.(align),'All')
            fprintf(1,'jPCA_project_unsuccessful method not yet run for BLOCK (%s) for alignment: %s\n',...
               obj.Name,align);
            Projection = []; 
            Summary = [];
            return;
         end   
         
         if ~isfield(obj.Data.(align).All,'jPCA')
            fprintf(1,'jPCA_project_unsuccessful method not yet run for BLOCK (%s) for alignment: %s\n',...
               obj.Name,align);
            Projection = []; 
            Summary = [];
            return;
         end 
         
         [flag,out] = getChecker(obj,align,'All','Full');
         if flag
            Projection = []; Summary = []; return;
         end
         
         fprintf(1,'Suppressing %s for %s-%s in %s...\n',suppressed_area,...
            outcome,align,obj.Name);
         if doReProject
            Projection = out.Projection;
            Summary = out.Summary;
            switch outcome
               case 'All'
                  x = cat(1,obj.Data.(align).Successful.rate(:,:,obj.ChannelMask),...
                            obj.Data.(align).Unsuccessful.rate(:,:,obj.ChannelMask));
               case 'Successful'
                  x = obj.Data.(align).Successful.rate(:,:,obj.ChannelMask);
               case 'Unsuccessful'
                  x = obj.Data.(align).Unsuccessful.rate(:,:,obj.ChannelMask);
               otherwise
                  error('Invalid outcome: %s',outcome);
            end
            ch_idx = contains({obj.ChannelInfo(obj.ChannelMask).area},suppressed_area);
               
         
         
            x(:,:,ch_idx) = 0; % "zero out" suppressed channels  
            [Projection,Summary] = obj.jPCA_project(align,Summary,x,active_area);
            
            obj.Data.(align).(outcome).jPCA.(active_area).Projection = Projection;
            obj.Data.(align).(outcome).jPCA.(active_area).Summary = Summary;

            if nargout < 1
               obj.jPCA_save_previews(align,outcome,active_area);
            end
         elseif strcmpi(outcome,'Successful')
            D = obj.jPCA_format(align,'Successful',active_area);
            
            jpca_params = defaults.jPCA('jpca_params',ones(numel(D),1));
            analyze_times = defaults.jPCA('analyze_times');
            if numel(D) < 3
               fprintf(1,'Too few successful %s trials for %s (%g).\n',...
                  align,obj.Name,numel(D));
               Projection = [];
               Summary = [];
               return;
            end

            [Projection,Summary] = jPCA.jPCA(D,analyze_times,jpca_params);
            obj.Data.(align).Successful.jPCA.(active_area).Projection = Projection;
            obj.Data.(align).Successful.jPCA.(active_area).Summary = Summary;

            if nargout < 1
               obj.jPCA_save_previews(align,'Successful',active_area);
            end
         else
            Projection = [];
            Summary = [];
            fprintf(1,'%s: invalid suppression combination. Check doReProject input.\n',obj.Name);
            return;
         end
         

         
         
            
      end
      
      % Project "unified" jPCs using coefficients collected across days
      function jPCA_unified_project(obj,align,area,Summary)
         if nargin < 4
            Summary = getUnifiedProp(obj,area,'Summary');
         end
         
         if nargin < 3
            area = 'Full';
         end
         
         if nargin < 2
            align = defaults.jPCA('jpca_align');
         end
         
         if numel(obj) > 1
            for ii = 1:numel(obj)
               jPCA_unified_project(obj(ii),align,area,Summary);
            end
            return;
         end
         
         x = getAreaRate(obj,area);
         
         fprintf(1,'\t-->\t%s\n',obj.Name);
         [obj.Data.(align).All.jPCA.Unified.(area).Projection,...
            obj.Data.(align).All.jPCA.Unified.(area).Summary] = ...
               jPCA_project(obj,align,Summary,x,area,false);
            
      end
      
      % Do jPCA on "warped" rates
      function [Projection,Summary] = jPCA_warped(obj,outcome)
         if nargin < 2
            outcome = 'Successful';
         end
         
         if numel(obj) > 1
            for ii = 1:numel(obj)
               Projection = cell(numel(obj),1);
               Summary = cell(numel(obj),1);
               if nargout > 1
                  [Projection{ii},Summary{ii}] = jPCA_warped(obj(ii),outcome);
               else
                  jPCA_warped(obj(ii),outcome);
               end
            end
            return;
         end
         
         [D,~,outcomes] = jPCA_format_warped(obj,outcome);
         
         jpca_params = defaults.jPCA('jpca_params',ones(numel(D),1));
         analyze_times = defaults.jPCA('analyze_times');
         if numel(D) < 3
            fprintf(1,'Too few successful %s trials for %s (%g).\n',...
               align,obj.Name,numel(D));
            Projection = [];
            Summary = [];
            return;
         end
         
         [Projection,Summary] = jPCA.jPCA(D,analyze_times,jpca_params);
         Summary.outcomes = outcomes;
         obj.Data.Warp.jPCA.(outcome).Projection = Projection;
         obj.Data.Warp.jPCA.(outcome).Summary = Summary;
         obj.HasWarpedjPCA = true;
         
         if nargout < 1
            obj.jPCA_save_previews('Warp',outcome,'Full');
         end
      end
      
      % Export jPCA movie for full dataset 
      function jPCA_warped_movie(obj,outcome)

         if nargin < 2
            outcome = 'Successful';
         end
         
         % Parse arrays
         if numel(obj) > 1
            for ii = 1:numel(obj)
               jPCA_warped_movie(obj(ii),outcome);
            end
            return;
         end
         
         if ~obj.HasWarpedjPCA
            fprintf(1,'%s: warped jPCA not yet performed.\n',obj.Name);
            return;
         end
         
         vid_folder = fullfile(defaults.jPCA('video_export_base'),...
            outcome,'Warp');
         output_score = defaults.group('output_score');
         movie_params = defaults.jPCA('movie_params',...
            obj.Data.Warp.jPCA.(outcome).Summary.outcomes,...
            obj.(output_score));
         
         
         moviename = sprintf('%s_%s_PostOpDay-%02g',...
            obj.Parent.Name,...
            'Warp',...
            obj.PostOpDay);
         movie_params.movieName = moviename;
         
         
         if ~isempty(obj.Parent)
            if ~isempty(obj.Parent.Parent)
               moviename = fullfile(pwd,...
                  vid_folder,obj.Parent.Parent.Name,moviename);
            else
               moviename = fullfile(pwd,...
                  vid_folder,obj.Parent.Name,moviename);
            end
         else
            moviename = fullfile(pwd,vid_folder,moviename);
         end
         tic;
         
         fprintf(1,'Exporting video:\n-->\t\t%s\n',moviename);
         MV = jPCA.phaseMovie(...
            obj.Data.Warp.jPCA.(outcome).Projection,...
            obj.Data.Warp.jPCA.(outcome).Summary, ...
            movie_params);
         jPCA.export_jPCA_movie(MV,moviename);
         clear MV;
         toc;
      end
      
      % Set "Outlier" status
      function markOutlier(obj)
         if ~obj.IsOutlier
            obj.IsOutlier = true;
            fprintf(1,'%s marked as an Outlier.\n',obj.Name);
         end
      end
      
      % Return the matched channel for the channel index (from parent)
      function iCh = matchChannel(obj,ch)
         if isempty(obj.Parent)
            iCh = ch;
            fprintf(1,'Parent of %s not yet initialized.\n',obj.Name);
            return;
         end
         ch_probe = [obj.ChannelInfo.probe];
         ch_channel = [obj.ChannelInfo.channel];
         
         p_probe = obj.Parent.ChannelInfo(ch).probe;
         p_channel = obj.Parent.ChannelInfo(ch).channel;
         
         iCh = find((ch_probe==p_probe) & (ch_channel==p_channel),1,'first');
      end
      
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
         
         t = obj.T * 1e3 + offset;
         for ii = 1:numel(area)
            x = getAreaRate(obj,area{ii},align,outcome);
            y = obj.doSmoothNorm(x);
            z = squeeze(mean(y,1));
            plot(ax,t,z,'Color',col{ii},'LineWidth',1.5);
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
               fig = [fig; plotAllAlignmentsRate(obj(ii),outcome)];
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
      
      % Set data regarding divergence of unsuccessful and  successful
      % trajectories in primary plane of jPCA phase space
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
      
      % Set snap time (sec) for taking frames relative to video
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
      
      % "Snap" frames
      function snapFrames(obj,align,t)
         % Parse input
         if nargin > 2
            % t should be in seconds
            setSnapTime(obj,t);
         end
         
         if nargin < 2
            align = defaults.jPCA('jpca_align');
         end
         
         if numel(obj) > 1
            for ii = 1:numel(obj)
               snapFrames(obj(ii),align);
            end
            return;
         end
         
         % Check data         
         if ~isfield(obj.Data,align)
            fprintf(1,'-->\t%s: missing field (%s).\n',obj.Name,align);
            return;
         elseif ~isfield(obj.Data.(align),'t')
            fprintf(1,'-->\t%s: missing field (%s.t).\n',obj.Name,align);
            return;
         else
            tTrial = obj.Data.(align).t;
         end
         
         if isempty(tTrial)
            fprintf(1,'-->\t%s: no trial times.\n',obj.Name);
            return;
         end
         
         [V,vidOffset] = getVideo(obj);
         if isempty(V)
            fprintf(1,'-->\t%s: no video.\n',obj.Name);
            return;
         end
         
         % Make output path
         p = defaults.block('frame_snaps_loc');
         pname = fullfile(pwd,p,align);
         if ~isempty(obj.Parent)
            pname = fullfile(pname,obj.Parent.Name);
         end
         pname = fullfile(pname,obj.Name);
         out_path = {fullfile(pname,'Unsuccessful'),...
                     fullfile(pname,'Successful')};
         for ii = 1:numel(out_path)
            if exist(out_path{ii},'dir')==0
               mkdir(out_path{ii});
            end
         end
         
         % Loop through video and export snapshots and save mat file
         fname_expr = '%s_%s_PostOpDay-%g_Trial-%03g_%gms';
         if isempty(obj.tSnap)
            fprintf(1,'%s: missing snapshot time.\n',obj.Name);
            return;
         else
            t_off = obj.tSnap;
         end
         
         if abs(t_off) > 2
            t_off = t_off *1e-3;
         end
         t_ms = round(t_off*1e3);
         C = readFrame(V);
         C = repmat(C,1,1,1,numel(tTrial));
         snapshotTic = tic;
         fprintf(1,'Exporting snapshots for %s (%s: %gms)...',obj.Name,align,t_ms);
         for ii = 1:numel(tTrial)
            tCur = tTrial(ii) + t_off - vidOffset;
            V.CurrentTime = tCur;
            C(:,:,:,ii) = readFrame(V);
            str = sprintf(fname_expr,obj.Name,align,obj.PostOpDay,ii,t_ms);
            imwrite(C(:,:,:,ii),fullfile(out_path{obj.Data.Outcome(ii)+1},[str '.png']));
         end
         fprintf(1,'complete (%g seconds elapsed).\n',round(toc(snapshotTic)));
         save(fullfile(pname,sprintf('%s_%s_PostOpDay-%g_%gms_snapshots.mat',...
            obj.Name,align,obj.PostOpDay,t_ms)),'C','-v7.3');
         clear V C
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
                     obj.updateNaNBehavior(nTotal);
                  end
               end
            else
               [~,idx] = unique(b.Grasp);
               b = b(idx,:);
               if size(b,1)==nTotal
                  obj.updateNaNBehavior([],b);
               else
                  obj.updateNaNBehavior(nTotal);
               end
            end
         else
            obj.updateNaNBehavior(nTotal);            
         end
      end
      
      % Update decomposition data relating to profile activity
      function updateDecompData(obj)
         fname = fullfile(obj.Folder,obj.Name,...
            [obj.Name '_Grasp-decompData.mat']);
         
         if exist(fname,'file')==0
            fprintf(1,'%s missing. Could not update.\n',fname);
            return;
         else
            in = load(fname,'out');
         end
         
         if isempty(obj.Data)
            obj.Data = struct;
         end
         
         obj.Data.pc = in.out;
         obj.HasData = true;
         
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
            fprintf(1,'Mismatch between number of spike rate trials (%g) and behaviorData (%g) for %s.\n',...
               nTotal,size(b,1),obj.Name);
         end
      end
      
      % Update Spike Rate data
      function flag = updateSpikeRateData(obj,align,outcome)
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
         
         spike_analyses_folder = defaults.block('spike_analyses_folder');
%          spike_rate_smoother = defaults.block('spike_rate_smoother');
         norm_spike_rate_tag = defaults.block('norm_spike_rate_tag');
         fname = fullfile(obj.Folder,obj.Name,...
            [obj.Name spike_analyses_folder],...
            [obj.Name norm_spike_rate_tag align '_' outcome '_ds.mat']);
         if (exist(fname,'file')==0) && (~obj.HasData)
            fprintf(1,'No such file: %s\n',fname);
            obj.Data.(align).(outcome).rate = [];
            return;
         elseif exist(fname,'file')==0
            fprintf(1,'No such file: %s\n',fname);
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
                  obj.Data.(align).(outcome).t = linspace(min(obj.T),max(obj.T),size(in.data,2));
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
      
      % Create a new data field "Warp" using reach/grasp times
      function warpRateBetweenReachAndGrasp(obj,outcome)         
         % Parse input
         if nargin < 2
            outcome = 'All';
         end
         
         % Parse array
         if numel(obj) > 1
            for ii = 1:numel(obj)
               obj(ii).warpRateBetweenReachAndGrasp(outcome);
            end
            return;
         end
         
         obj.Data.Warp.rate = [];
         obj.Data.Warp.time = [];
         obj.Data.Warp.label = [];
         
         % Check appropriate data is present
         align = defaults.jPCA('jpca_align');
         if (~isfield(obj.Data,'Grasp')) || (~isfield(obj.Data,'Reach'))
            fprintf(1,'%s is missing Grasp or Reach field. No Warp applied.\n',obj.Name);
            return;
         end
         
         if (~isfield(obj.Data.(align),outcome))
            fprintf(1,'%s is missing %s. No Warp applied.\n',obj.Name);
            return;
         end
         
         if (~isfield(obj.Data.(align).(outcome),'rate'))
            if ~obj.updateSpikeRateData(align,outcome)
               fprintf(1,'%s is missing rate. No Warp applied.\n',obj.Name);
               return;
            end
         end

         if numel(obj.Data.Reach.t) ~= numel(obj.Data.Grasp.t)
            fprintf(1,'%s could not Warp: mismatch between grasp_ts (%g) and reach_ts (%g).\n',...
               obj.Name,numel(grasp_ts),numel(reach_ts));
            return;
         end
         
         % Get times
         d_ts = (obj.Data.Reach.t-obj.Data.Grasp.t)*1e3; % convert to ms
         
         fprintf(1,'Applying reach-to-grasp time-warp: %s...',obj.Name);
         [x,T] = obj.applyLPF2Rate(obj.Data.(align).(outcome).rate(:,:,obj.ChannelMask),obj.T);
         [y,t,label] = obj.applyTimeWarping(x,T,obj.Data.Outcome,d_ts);
         
         if ~isempty(y)
            obj.HasWarpData = true;
            fprintf(1,'successful.\n');
         else
            fprintf(1,'unsuccessful.\n');
         end
         
         obj.Data.Warp.rate = y;
         obj.Data.Warp.time = t;
         obj.Data.Warp.label = label;
      end
   end
   
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
      
      % Static function to apply "smoothing" (lowpass filter) and
      % normalization (square-root transform & mean-subtraction)
      function y = doSmoothNorm(x)
         filter_order = defaults.block('lpf_order');
         fs = defaults.block('fs');
         cutoff_freq = defaults.block('lpf_fc');
         if ~isnan(cutoff_freq)
            [b,a] = butter(filter_order,cutoff_freq/(fs/2),'low');
         end
         pre_trial_norm = defaults.block('pre_trial_norm');
         
         mu = mean(x,1); 

         if isnan(cutoff_freq)
            z = mu;
         else
            z = filtfilt(b,a,mu);
         end
         z = sqrt(abs(x)) .* sign(x);
         y =  z - mean(z(:,pre_trial_norm,:),2);
      end
      
      % Static function to apply "smoothing" (lowpass filter)
      function y = doSmoothOnly(x,fs)
         filter_order = defaults.block('lpf_order');
         if nargin < 2
            fs = defaults.block('fs');
         end
         cutoff_freq = defaults.block('lpf_fc');
         if ~isnan(cutoff_freq)
            [b,a] = butter(filter_order,cutoff_freq/(fs/2),'low');
         end
         
         mu = mean(x,1).'; 

         if isnan(cutoff_freq)
            y = mu.';
         else
            y = filtfilt(b,a,mu).';
         end
      end
      
   end
   
end

