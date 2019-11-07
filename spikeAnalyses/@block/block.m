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
            obj.doSpikeBinning(behaviorData);            
            obj.doBinSmoothing;
            obj.doRateDownsample;
            fprintf(1,'Rate extraction for %s complete.\n\n',obj.Name);

         end
         
         % Regardless if doing rate extraction or not, update behavior data
         % and try and associate spike rate data with object
         updateBehaviorData(obj);
         o = defaults.block('all_outcomes');
         e = defaults.block('all_events');
         for iE = 1:numel(e)
            for iO = 1:numel(o)
               updateSpikeRateData(obj,e{iE},o{iO});
            end
         end

         obj.parseElectrodeCoordinates('Full');
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
         
         pre_trial_norm = defaults.block('pre_trial_norm');
         spike_rate_smoother = defaults.block('spike_rate_smoother');
         norm_spike_rate_tag = defaults.block('norm_spike_rate_tag');
         fStr_in = defaults.block('fname_orig_rate');
         fStr_out = defaults.block('fname_ds_rate');
         o = defaults.block('all_outcomes');
         e = defaults.block('all_events');
         for iO = 1:numel(o)
            for iE = 1:numel(e)
               % Skip if there is no file to decimate
               str = sprintf(fStr_in,obj.Name,spike_rate_smoother,e{iE},o{iO});
               fName_In = fullfile(obj.getPathTo('rate'),str);
               if exist(fName_In,'file')==0
                  continue;
               end
               
               % Skip if it's already been extracted
               str = sprintf(fStr_out,obj.Name,norm_spike_rate_tag,e{iE},o{iO},r_ds);
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
               
               if (max(abs(out.t)) < 10)
                  out.t = out.t * 1e3;
               end
               
               data = obj.doSmoothNorm(in.data,pre_trial_norm);
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
      
      % Format down-sampled rate data for dPCA, wherein the days are used
      % as different stimuli (S) and outcomes (successful or unsuccessful
      % when pellet is present, unsuccessful when pellet is absent) are
      % used as decision (D). Other parts are formatted similarly to the
      % Romo et al dataset referenced in the dPCA toolkit.
      function [X,t,trialNum] = format_dPCA_days_are_stimuli(obj)
         % Parse array input
         if numel(obj) > 1
            X = cell(numel(obj),1);
            trialNum = [];
            for ii = 1:numel(obj)
               [X{ii},t,trialNum_tmp] = format_dPCA_days_are_stimuli(obj(ii)); % t is always the same
               trialNum = cat(2,trialNum,trialNum_tmp);
            end
            return;
         end
         
         p = defaults.dPCA;
         addpath(p.local_repo_loc);
         
         X = [];
         t = [];
         trialNum = [];
         
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
         
         N = size(g,3);
         
         trialNum = nan(N,1,3);
         for ii = 1:N
            trialNum(ii,:,:) = nTrial;
         end
         
         if any(nTrial < 1)
            X = []; 
            return;
         end
         
         % # neurons x 1 (day) x 3 (outcomes) x # timesteps (sum(t_idx)) x
         % # trials
         X = nan(N,1,3,size(g,2),nTrialMax);
         for iNeu = 1:size(g,3)
            for iOutcome = 1:numel(nTrial)
               for iTrial = 1:nTrial(iOutcome)
                  idx = trialIndex{iOutcome}(iTrial);
                  X(iNeu,1,iOutcome,:,iTrial) = g(idx,:,iNeu);
               end               
            end
         end
            
      end
      
      % Format down-sampled rate data for dPCA, wherein the "stimulus" is
      % whether the pellet was present or absent, and the "decision" is
      % whether he did a secondary reach or not.
      function [X,t,trialNum] = format_dPCA_pellet_present_absent(obj)
         % Parse array input
         if numel(obj) > 1
            X = cell(numel(obj),1);
            trialNum = [];
            for ii = 1:numel(obj)
               [X{ii},t,trialNum_tmp] = format_dPCA_pellet_present_absent(obj(ii)); % t is always the same
               trialNum = cat(2,trialNum,trialNum_tmp);
            end
            return;
         end
         
         p = defaults.dPCA;
         addpath(p.local_repo_loc);
         
         X = [];
         t = [];
         trialNum = [];
         
         [r,flag_exists,flag_isempty,t] = obj.getRate('Reach','All');
         if (~flag_exists) || (flag_isempty)
            fprintf(1,'No reach rate data in %s.\n',obj.Name);
            return;
         end
         
         [g,flag_exists,flag_isempty] = obj.getRate('Grasp','All');
         if (~flag_exists) || (flag_isempty)
            fprintf(1,'No grasp rate data in %s.\n',obj.Name);
            return;
         end       
         
         % Get reduced number of timesteps
         t_idx_r = (t >= p.t_start_reach) & (t <= p.t_stop_reach);
         tr = t(t_idx_r);
         r = r(:,t_idx_r,:);
         t_idx_g = (t >= p.t_start_grasp) & (t <= p.t_stop_grasp);
         tg = t(t_idx_g);
         g = g(:,t_idx_g,:);
         
         % Get median offset latency and then add this to the time vector
         offset = obj.getOffsetLatency('Grasp','Reach');
         
         % This part is for visualization purposes
         if offset < (p.t_stop_reach - p.t_start_grasp)
            offset = p.t_stop_reach - p.t_start_grasp + mode(diff(t));
         end
         t = [tr, (tg + offset)];
         
         % Get alignment on behavioral trials
         b = obj.behaviorData;
         
         iGrasp = ~isinf(b.Grasp);
         iReach = ~isinf(b.Reach);
         
         % Make a matrix to match and concatenate reach/grasp together
         x = nan(size(b,1),size(r,2)+size(g,2),size(r,3));
         for ii = 1:size(b,1)
            if (iReach(ii) && iGrasp(ii))
               x(ii,:,:) = cat(2,r(ii,:,:),g(ii,:,:));
            end
         end
         iDiscard = isnan(x(:,1,1));
         
         % Discard
         x(iDiscard,:,:) = [];
         b(iDiscard,:) = [];
         
         % 4 conditions: 
         % pp_complete (pellet present, complete trial)
         % pp_flail (pellet present, flail)
         % pa_complete (pellet absent, complete trial)
         % pa_flail (pellet absent, flail)
         
         pp = b.PelletPresent + 1; % pellet present: 2 = present, 1 = absent
         cf = ~isinf(b.Complete)+1; % complete/flail: 2 = complete, 1 = flail
         
         nTrial = [sum(~b.PelletPresent & isinf(b.Complete)), ...
            sum(~b.PelletPresent & ~isinf(b.Complete)); ...
            sum(b.PelletPresent & isinf(b.Complete)), ...
            sum(b.PelletPresent & ~isinf(b.Complete))];
         
         nTrialMax = max(max(nTrial));         
         
         N = size(x,3);
         trialNum = nan(N,2,2);
         for ii = 1:N
            trialNum(ii,:,:) = nTrial;
         end
         
         if any(nTrial < 1)
            X = []; 
            return;
         end
         
         % # neurons x 2 (absent/present) x 2 (complete/not) x 40 ts x
         % # trials
         X = nan(N,numel(unique(pp)),numel(unique(cf)),size(x,2),nTrialMax);
         k = zeros(2,2);
         for iNeu = 1:size(g,3)
            for ii = 1:size(b,1)
               k(pp(ii),cf(ii)) = k(pp(ii),cf(ii)) + 1;
               X(iNeu,pp(ii),cf(ii),:,k(pp(ii),cf(ii))) = x(ii,:,iNeu);
            end               
         end
         
         % If no output argument, save data in array X
         if nargout < 1
            fname = fullfile(p.path,sprintf(p.fname_pell,obj.Name));
            save(fname,'X','t','trialNum','-v7.3');
         end
            
      end
      
      % Do jPCA analysis on this recording
      % -- deprecated --
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
         [D,~,t] = obj.jPCA_format(align,'Successful');
         if isempty(t)
            Projection = [];
            Summary = [];
            return;
         end
         jpca_params = defaults.jPCA('jpca_params',ones(numel(D),1));
         jpca_params.score = obj.TrueScore;
         start_stop_times = defaults.jPCA('jpca_start_stop_times');
         analyze_times = t(t>=start_stop_times(1) & t<=start_stop_times(2));
         
         if numel(D) < 3
            fprintf(1,'Too few successful %s trials for %s (%g).\n',...
               align,obj.Name,numel(D));
            Projection = [];
            Summary = [];
            return;
         end
         
         [Projection,Summary] = jPCA.jPCA(D,analyze_times,jpca_params);
         Summary.outcomes = ones(numel(D),1) + 1;
         obj.Data.(align).Successful.jPCA.Full.Projection = Projection;
         obj.Data.(align).Successful.jPCA.Full.Summary = Summary;
         
         if nargout < 1
            obj.jPCA_save_previews(align,'Successful','Full');
         end
      end
      
      % Helper function to determine if alignment/outcome is viable
      % -- deprecated --
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
      % -- deprecated --
      function [D,idx,t] = jPCA_format(obj,align,outcome,area)
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
               [dTmp,idxTmp,t] = jPCA_format(obj(ii),align,outcome,area);
               D = [D; dTmp];
               idx = [idx; idxTmp * ii];
            end
            return;
         end

         if strcmp(outcome,'Successful')
            includeStruct = utils.makeIncludeStruct({'Reach','Grasp','Complete','PelletPresent'});
            [rate,flag_exists,flag_isempty,t] = getRate(obj,align,outcome,area,includeStruct);
         else
            includeStruct = utils.makeIncludeStruct({'Reach','Grasp','Complete'},[]);
            [rate,flag_exists,flag_isempty,t] = getRate(obj,align,outcome,area,includeStruct);
         end
         if (~flag_exists) || flag_isempty
            fprintf(1,'No %s %s (%s) rates to do jPCA for %s.\n',...
               outcome,align,area,obj.Name);
            t = [];
            return;
         end        
         
         start_stop_times = defaults.jPCA('jpca_start_stop_times');
%          analyze_times = t(t>=start_stop_times(1) & t<=start_stop_times(2));
         
         rate = obj.removeCrossCondMean(rate,align,includeStruct,area);

         D = jPCA.format(rate,t);
         idx = ones(numel(D),1);
      end
      
      % Helper function that returns the formatted rate data for jPCA
      % -- deprecated --
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
      % -- deprecated --
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
      % -- deprecated --
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
         
         close all force;
         Summary = [];
         Projection = [];
         
         [rate,flag_exists,flag_isempty,t] = obj.getRate(align,'Unsuccessful');
         
         if size(rate,1) < 3
            fprintf(1,'-->\tNot enough trials for unsuccessful jPCA on %s.\n',obj.Name);
            return;
         elseif ~flag_exists
            fprintf(1,'-->\tNo rates for unsuccessful jPCA on %s.\n',obj.Name);
            return;
         elseif flag_isempty
            fprintf(1,'-->\tNot enough trials for unsuccessful jPCA on %s.\n',obj.Name);
            return;
         end
         
         if obj.jPCA_check(align,'Successful','Full')
            Summary = [];
            Projection = [];
            fprintf(1,'-->\tNo successful jPCs yet for %s.\n',obj.Name);
            return;
         end
         
         Summary = obj.Data.(align).Successful.jPCA.Full.Summary;
         Summary.outcomes = ones(size(rate,1),1)*2;
         
         allTimes = Summary.allTimes;
         times = Summary.times;
         jPCs_highD = Summary.jPCs_highD;
         PCs = Summary.PCs;
         mu = Summary.preprocessing.meanFReachNeuron;
         norms = Summary.preprocessing.normFactors;
         
         fprintf(1,'-->\tCollecting unsuccessful jPCA data for %s.\n',obj.Name);
         Projection = [];
         for ii = 1:size(rate,1)
            Projection = [Projection, ...
               makeTrialCondition(...
                  squeeze(rate(ii,:,:)),...
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
         Summary.numTrials = size(rate,1);
         
         obj.Data.(align).Unsuccessful.jPCA.Full.Projection = Projection;
         obj.Data.(align).Unsuccessful.jPCA.Full.Summary = Summary;
         
         if nargout < 1
            obj.jPCA_save_previews(align,'Unsuccessful','Full');
         end
      end
      
      % Project all trials onto jPCA plane using jPCs from success only
      % -- deprecated --
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
         


         includeStruct = utils.makeIncludeStruct({'PelletPresent'},[]);
         [x,flag_exists,flag_isempty,t,labels] = obj.getRate(align,'All',area,includeStruct);
         Summary.outcomes = labels;
         if ~flag_exists
            Summary = [];
            Projection = [];
            fprintf(1,'No rates extracted for %s: %s-%s\n',obj.Name,align,area);
            return;
         elseif flag_isempty
            Summary = [];
            Projection = [];
            fprintf(1,'No trials for %s: %s-%s\n',obj.Name,align,area);
            return;
         end
         
         x = obj.removeCrossCondMean(x,align,includeStruct,area);

         
         if size(x,1) < 2
            Summary = [];
            Projection = [];
            fprintf(1,'-->\tNot enough trials for unified jPCA on %s.\n',obj.Name);
            return;
         end

         
         if exist('t','var')==0
            allTimes = Summary.allTimes;
         else
            allTimes = t;
         end
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
      % -- deprecated --
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
      % -- deprecated --
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
            [D,~,t] = obj.jPCA_format(align,'Successful',active_area);
            
            jpca_params = defaults.jPCA('jpca_params',ones(numel(D),1));
            if numel(D) < 3
               fprintf(1,'Too few successful %s trials for %s (%g).\n',...
                  align,obj.Name,numel(D));
               Projection = [];
               Summary = [];
               return;
            end
            
            start_stop_times = defaults.jPCA('jpca_start_stop_times');
            analyze_times = t(t>=start_stop_times(1) & t<=start_stop_times(2));

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
      % -- deprecated --
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
      % -- deprecated --
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
      % -- deprecated --
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
      
       % Load "pellet" dPCA-formatted rates
      % -- deprecated --
      function [X,t,trialNum] = load_dPCA_pellet_present_absent(obj)
         if numel(obj) > 1
            X = cell(numel(obj),1);
            trialNum = cell(numel(obj),1);
            for ii = 1:numels(obj)
               [X{ii},t,trialNum{ii}] = load_dPCA(obj(ii)); % t is always the same
            end
            return;
         end
         p = obj.getPathTo('dPCA');
         f = defaults.dPCA('fname_pell');
         X = [];
         fname = fullfile(p,sprintf(f,obj.Name));
         if exist(fname,'file')==0
            fprintf(1,'Missing dPCA file: %s\n',fname);
            return;
         end
         in = load(fname,'X','t','trialNum');
         if isfield(in,'X')
            X = in.X;
            t = in.t;
            trialNum = in.trialNum;
         else
            fprintf(1,'%s dPCA missing variable: ''X'' (contains spike rates).\n',obj.Name);
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
               ch = [ch; iParent];
               x = [x; x_grid_cfa(ch_grid_cfa == cch)];
               y = [y; y_grid_cfa(ch_grid_cfa == cch)];
            else % RFA
               rch = ch_info(ii).channel;
               iParent = find([obj.Parent.ChannelInfo.probe]==p & ...
                  [obj.Parent.ChannelInfo.channel]==rch,1,'first');
               ch = [ch; iParent];
               x = [x; x_grid_rfa(ch_grid_rfa == rch)];
               y = [y; y_grid_rfa(ch_grid_rfa == rch)];
            end
            Probe = [Probe; p];
            Channel = [Channel; ch_info(ii).channel];
            ICMS = [ICMS; {ch_info(ii).icms}];
         end
         ICMS = categorical(ICMS);
         
         if ~(strcmpi(area,'CFA') || strcmpi(area,'RFA'))
            obj.Electrode = table(Probe,Channel,ICMS,x,y,ch);
         end
         
      end
      
      % Parse the trials to be used, based on includeStruct
      function [idx,labels] = parseTrialIndicesFromIncludeStruct(obj,align,includeStruct,outcome)
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
               switch b.Properties.UserData(ismember(b.Properties.VariableNames,includeStruct.Include{ii}))
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
               switch b.Properties.UserData(ismember(b.Properties.VariableNames,includeStruct.Exclude{ii}))
                  case 1
                     idx = idx & (isinf(b.(includeStruct.Exclude{ii})));
                  case 3
                     idx = idx & ~logical(b.(includeStruct.Exclude{ii}));
                  case 4
                     idx = idx & logical(b.(includeStruct.Exclude{ii}));
                  otherwise
                     continue;
               end

            end
         end

         labels = labels(idx);
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
         
%          t = obj.T * 1e3 + offset;
         for ii = 1:numel(area)
%             x = getAreaRate(obj,area{ii},align,outcome);
%             y = obj.doSmoothNorm(x);
%             z = squeeze(mean(y,1));
            [rate,flag_exists,flag_isempty,t] = getRate(obj,align,outcome,area{ii});
            if (~flag_exists) || (flag_isempty)
               continue;
            end
            z = squeeze(mean(rate,1));
            if (max(abs(t)) < 10)
               t = t * 1e3;
            end
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
      
      % Run dPCA analysis for Rat object or object array
      % -- deprecated --
      function out = run_dPCA_pellet_present_absent(obj)
         % NOTE: code below is adapted from dPCA repository code
         %       dpca_demo.m, which was graciously provided by the
         %       machenslab github at github.com/machenslab/dPCA
         
         if numel(obj) > 1
            out = cell(numel(obj),1);
            for ii = 1:numel(obj)
               out{ii} = run_dPCA_days_are_stimuli(obj(ii));
            end
            return;
         end
         addpath(obj.getPathTo('dPCA-repo'));
         [firingRates,time,trialNum] = load_dPCA_pellet_present_absent(obj);
         firingRatesAverage = nanmean(firingRates,5);
         S = size(firingRatesAverage,2);
         
         combinedParams = defaults.dPCA('combinedParams_pell');
         margNames = defaults.dPCA('margNames_pell');
         margColours = defaults.dPCA('margColours_pell');
         timeEvents = [0,obj.getOffsetLatency('Grasp','Reach')];
         
         %% Step 1: PCA of the dataset
         X = firingRatesAverage(:,:);
         X = bsxfun(@minus, X, mean(X,2));

         [W,~,~] = svd(X, 'econ');
         W = W(:,1:20);

         % computing explained variance
         explVar = dpca_explainedVariance(firingRatesAverage, W, W, ...
             'combinedParams', combinedParams);

         % a bit more informative plotting
         dpca_plot(firingRatesAverage, W, W, @dpca_plot_default, ...
             'explainedVar', explVar, ...
             'time', time,                        ...
             'timeEvents', timeEvents,               ...
             'marginalizationNames', margNames, ...
             'marginalizationColours', margColours,...
             'figName',sprintf('%s: PCA',obj.Name),...
             'figPos',[0.1+0.01*randn(1) 0.1+0.01*randn(1) 0.4 0.8]);
          
         %% Step 4: dPCA with regularization

         % This function takes some minutes to run. It will save the computations 
         % in a .mat file with a given name. Once computed, you can simply load 
         % lambdas out of this file:
         %   load('tmp_optimalLambdas.mat', 'optimalLambda')

         % Please note that this now includes noise covariance matrix Cnoise which
         % tends to provide substantial regularization by itself (even with lambda set
         % to zero).

         optimalLambda = dpca_optimizeLambda(firingRatesAverage, firingRates, trialNum, ...
             'combinedParams', combinedParams, ...
             'simultaneous', true, ...
             'numRep', 2, ...  % increase this number to ~10 for better accuracy
             'filename', 'tmp_optimalLambdas.mat');

         Cnoise = dpca_getNoiseCovariance(firingRatesAverage, ...
             firingRates, trialNum, 'simultaneous', true);

         [W,V,whichMarg] = dpca(firingRatesAverage, 20, ...
             'combinedParams', combinedParams, ...
             'lambda', optimalLambda, ...
             'Cnoise', Cnoise);

         explVar = dpca_explainedVariance(firingRatesAverage, W, V, ...
             'combinedParams', combinedParams, ...
             'Cnoise', Cnoise, 'numOfTrials', trialNum);   
          
%          dpca_plot(firingRatesAverage, W, V, @dpca_plot_default, ...
%              'numCompToShow',15,...
%              'explainedVar', explVar, ...
%              'marginalizationNames', margNames, ...
%              'marginalizationColours', margColours, ...
%              'whichMarg', whichMarg,                 ...
%              'time', time,                        ...
%              'timeEvents', timeEvents,               ...
%              'timeMarginalization', 3, ...
%              'legendSubplot', 16,...
%              'figName',sprintf('%s: dPCA',obj.Name),...
%              'figPos',[0.5+0.01*randn(1) 0.1+0.01*randn(1) 0.4 0.8]);
%         decodingClasses = {...
%            [(1:S)' (1:S)'],...
%            repmat(1:2, [S 1]), ...
%            [], ...
%            [(1:S)' (S+(1:S))']};
%   
%         accuracy = dpca_classificationAccuracy(firingRatesAverage, firingRates, trialNum, ...
%              'lambda', optimalLambda, ...
%              'combinedParams', combinedParams, ...
%              'decodingClasses', [], ...
%              'simultaneous', true, ...
%              'numRep', 5, ...        % increase to 100
%              'filename', 'tmp_classification_accuracy.mat');
% 
%         dpca_classificationPlot(accuracy, [], [], [], decodingClasses)
% 
%         accuracyShuffle = dpca_classificationShuffled(firingRates, trialNum, ...
%              'lambda', optimalLambda, ...
%              'combinedParams', combinedParams, ...
%              'decodingClasses', [], ...
%              'simultaneous', true, ...
%              'numRep', 5, ...        % increase to 100
%              'numShuffles', 20, ...  % increase to 100 (takes a lot of time)
%              'filename', 'tmp_classification_accuracy.mat');
% 
%         dpca_classificationPlot(accuracy, [], accuracyShuffle, [], decodingClasses)
% 
%         componentsSignif = dpca_signifComponents(accuracy, accuracyShuffle, whichMarg);
% 
%         dpca_plot(firingRatesAverage, W, V, @dpca_plot_default, ...
%              'explainedVar', explVar, ...
%              'marginalizationNames', margNames, ...
%              'marginalizationColours', margColours, ...
%              'whichMarg', whichMarg,                 ...
%              'time', time,                        ...
%              'timeEvents', timeEvents,               ...
%              'timeMarginalization', 3,           ...
%              'legendSubplot', 16,                ...
%              'componentsSignif', componentsSignif,...
%              'figName',sprintf('%s: regularized classified dPCA',obj.Name),...
%              'figPos',[0.1+0.01*randn(1) 0.1+0.01*randn(1) 0.8 0.8]);
          
          
         out = struct;
         out.firingRatesAverage = firingRatesAverage;
         out.time = time;
         out.trialNum = trialNum;
         
         out.W = W;
         out.V = V;
         out.whichMarg = whichMarg;
         out.explVar = explVar;
         out.Cnoise = Cnoise;
         out.optimalLambda = optimalLambda;
%          out.accuracy = accuracy;
%          out.accuracyShuffle = accuracyShuffle;
%          out.decodingClasses = decodingClasses;
%          out.componentsSignif = componentsSignif;
         
          
         fprintf(1,'dPCA completed: %s\n',obj.Name);
         
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
      
      % "Snap" frames
      % -- deprecated --
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
      
      % Update values in channel modulation property struct
      function updateChMod(obj,rate,t,alreadyMasked)
         if numel(obj) > 1
            error('UPDATECHMOD method should only be used on scalar BLOCK objects.');
         end
         
         if nargin < 4
            alreadymasked = true;
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
      
      % Update decomposition data relating to profile activity
      % -- deprecated --
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
         
         norm_spike_rate_tag = defaults.block('norm_spike_rate_tag');
         fname_ds_rate = defaults.block('fname_ds_rate');
         r_ds = defaults.block('r_ds');
         
         fname = fullfile(obj.getPathTo('rate'),sprintf(fname_ds_rate,...
            obj.Name,norm_spike_rate_tag,align,outcome,r_ds));
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
      % -- deprecated --
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
   
   % Methods for getting BLOCK object properties
   methods (Access = public)
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
      function [avgRate,channelInfo,t] = getAvgNormRate(obj,align,outcome,ch,updateAreaModulations)
         % avgRate : Rows are channels, columns are timesteps
         if nargin < 5
            updateAreaModulations = false;
         end
         if nargin < 4
            ch = nan;
         end
         if nargin < 3
            outcome = 'Successful'; % 'Successful' or 'Unsuccessful' or 'All'
         else
            if isstruct(outcome) % then it's includeStruct instead of outcome
               includeStruct = outcome;
               if ismember(includeStruct.Include,'Outcome')
                  'Successful';
               elseif ismember(includeStruct.Exclude,'Outcome')
                  'Unsuccessful';
               else
                  outcome = 'All';
               end
            end
         end
         if nargin < 2
            align = 'Grasp'; % 'Grasp' or 'Reach'
         end
         
         if numel(obj) > 1
            avgRate = [];
            channelInfo = [];
            for ii = 1:numel(obj)
               [tmpRate,tmpCI,t] = getAvgNormRate(obj(ii),align,outcome,ch,updateAreaModulations);
               avgRate = [avgRate; tmpRate]; %#ok<*AGROW>
               channelInfo = [channelInfo; tmpCI];
            end
            return;
         end
         
         if isempty(obj.nTrialRecent)
            obj.initRecentTrialCounter;
         end
         obj.nTrialRecent.rate = 0;
         
         if isnan(ch)
            ch = 1:numel(obj.ChannelInfo);
         end
         
         obj.HasAvgNormRate = false; % Reset flag to false each time method is run
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
                  if updateAreaModulations
                     obj.HasAreaModulations = false;
                     obj.chMod = [];
                  end
                  return;
               end
            else
               fprintf('No %s rate extracted for %s alignment for block %s. Extracting...\n',...
                  outcome,align,obj.Name);
               obj.updateSpikeRateData(align,outcome);
               if ~isfield(obj.Data.(align),outcome)
                  fprintf('Invalid field for %s: %s\n',obj.Name,outcome);
                  if updateAreaModulations
                     obj.HasAreaModulations = false;
                     obj.chMod = [];
                  end
                  return;
               end
            end
         else
            obj.updateSpikeRateData(align,outcome);
            if ~isfield(obj.Data,align)
               fprintf('Invalid field for %s: %s\n',obj.Name,align);
               if updateAreaModulations
                  obj.HasAreaModulations = false;
                  obj.chMod = [];
               end
               return;
            elseif ~isfield(obj.Data.(align),outcome)
               fprintf('Invalid field for %s: %s\n',obj.Name,outcome);
               if updateAreaModulations
                  obj.HasAreaModulations = false;
                  obj.chMod = [];
               end
               return;
            else
               t = obj.Data.(align).(outcome).t;
            end
         end
         
         if ~isempty(t)
            if (max(abs(t)) < 10)
               t = t.*1e3; % Scale if it is not already scaled to ms
            end
         end
         

         avgRate = nan(numel(ch),numel(t));
         channelInfo = [];
         idx = 0;
         fs = (1/(defaults.block('spike_bin_w')*1e-3))/defaults.block('r_ds');

         for iCh = ch
            idx = idx + 1;
            channelInfo = [channelInfo; obj.ChannelInfo(iCh)];
            if obj.ChannelMask(iCh)
               x = obj.Data.(align).(outcome).rate(:,:,iCh);
               avgRate(idx,:) = obj.doSmoothOnly(x,fs);
            end
         end
         
         obj.nTrialRecent.rate = size(obj.Data.(align).(outcome).rate,1);         
         obj.HasAvgNormRate = true; % If the method returns successfully, set to true again

         if updateAreaModulations
            obj.updateChMod(avgRate.',t,false);
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
                  obj(ii).getBlockChannelInfo(useMask)];
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
         Name = {obj.Name};
         PostOpDay = obj.PostOpDay;
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
         channelInfo = utils.addStructField(channelInfo,Rat,Name,PostOpDay,Score);
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
         [xcmean,t] = getCrossCondMean(obj,align,includeStruct,'Full');
         if isempty(xcmean)
            % Cross-condition mean doesn't exist for this condition
            return;
         end
         t_idx = (t >= p.t_start) & (t <= p.t_stop);
         xcmean = xcmean(t_idx,:); 
         
         [rate,flag_exists,flag_isempty,t] = obj.getRate(align,'All','Full',includeStruct);
         if (~flag_exists)
            fprintf(1,'No rate for %s: %s\n',obj.Name,utils.parseIncludeStruct(includeStruct));
            return;
         elseif (flag_isempty)
            fprintf(1,'No trials for %s: %s\n',obj.Name,utils.parseIncludeStruct(includeStruct));
            return;
         end
         t_idx = (t >= p.t_start) & (t <= p.t_stop);
         rate = rate(:,t_idx,:);
         
         n = size(rate,1);
         
         fs = 1/(mode(diff(t.*1e-3)));
         f = defaults.conditionResponseCorrelations('f');
         
         for iCh = 1:size(rate,3)
            % Compute Pearson's Correlation Coefficient
            rho = corrcoef([xcmean(:,iCh), rate(:,:,iCh).']);
            rho = rho(1,2:end);
            r(iCh) = nanmean(rho);
            err_r(iCh) = nanstd(rho);
            
            % Compute magnitude-squared coherence
            cxy = mscohere(rate(:,:,iCh).',xcmean(:,iCh),[],[],f,fs);
            cm = nanmean(cxy,1);
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
            Name = repmat({obj.Name},sum(obj.ChannelMask),1);
            chInf = obj.ChannelInfo(obj.ChannelMask);
            Probe = [chInf.probe].';
            Channel = [chInf.channel].';
            ICMS = {chInf.icms}.';
            Area = categorical({chInf.area}.');
            PostOpDay = repmat(obj.PostOpDay,numel(Probe),1);
            N = ones(numel(Probe),1)*n;
            obj.Parent.CR = [obj.Parent.CR; ...
               table(Name,PostOpDay,Probe,Channel,ICMS,Area,r,err_r,c,err_c,f_c,N)];
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
         f = nan(1,numel(obj.Parent.ChannelInfo(obj.Parent.ChannelMask)));
         p = nan(1,numel(obj.Parent.ChannelInfo(obj.Parent.ChannelMask)));
         
         % Get cross-condition mean to recover "dominant" frequency power
         [xcmean,t] = getCrossCondMean(obj,align,includeStruct,'Full');
         fs = 1/(mode(diff(t*1e-3)));
         
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
               poday = [poday,potmp];
            end
            return;
         end
         
         cxy = [];
         f = defaults.conditionResponseCorrelations('f_coh');
         poday = obj.PostOpDay;
         
         [xcmean,t] = getCrossCondMean(obj,align,includeStruct);
         if isempty(xcmean)
            return;
         end
         
         t_idx = (t >= defaults.conditionResponseCorrelations('t_start')) & ...
            (t <= defaults.conditionResponseCorrelations('t_stop'));
         xcmean = xcmean(t_idx,:);
         fs = 1/(mode(diff(t.*1e-3)));
         
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
         
         [rate,t,~,flag] = getMeanRate(obj,align,includeStruct,'Full',false);
         if ~flag
            fprintf(1,'No mean rate for %s.\n',obj.Name);
            return;
         end
         
         fs = 1/(mode(diff(t))*1e-3);
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
      function out = getNumProp(obj,propName)
         if numel(obj) > 1
            out = nan(numel(obj),1);
            for ii = 1:numel(obj)
               out(ii) = getNumProp(obj(ii),propName);
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
               out = [out; obj(ii).(propName)];
            elseif isprop(obj(ii),propName)
               out = [out; {obj(ii).(propName)}];
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
      function [rate,flag_exists,flag_isempty,t,labels] = getRate(obj,align,outcome,area,includeStruct,updateAreaModulations)         
         
         % Parse input
         if nargin < 4
            area = 'Full';
         elseif isempty(area)
            area = 'Full';
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
            rate = cell(numel(obj),1);
            flag_exists = false(numel(obj),1);
            flag_isempty = false(numel(obj),1);
            labels = cell(numel(obj),1);
            for ii = 1:numel(obj)
               switch nargin
                  case 6
                     [rate{ii},flag_exists(ii),flag_isempty(ii),t,labels{ii}] = ...
                        obj(ii).getRate(align,outcome,area,includeStruct,updateAreaModulations);                      
                  case 5
                     [rate{ii},flag_exists(ii),flag_isempty(ii),t,labels{ii}] = ...
                        obj(ii).getRate(align,outcome,area,includeStruct);                    
                  case 4
                     [rate{ii},flag_exists(ii),flag_isempty(ii),t,labels{ii}] = ...
                        obj(ii).getRate(align,outcome,area);
                  case 3
                     [rate{ii},flag_exists(ii),flag_isempty(ii),t,labels{ii}] = ...
                        obj(ii).getRate(align,outcome);
                  case 2
                     [rate{ii},flag_exists(ii),flag_isempty(ii),t,labels{ii}] = ...
                        obj(ii).getRate(align);
                  otherwise
                     error('Invalid number of input arguments (%g).',nargin);
               end
            end
            return;
         end
         
         obj.nTrialRecent.rate = 0;
         
         if obj.IsOutlier
            fprintf(1,'%s has been marked as an outlier point. Skipped.\n',obj.Name);
            labels = [];
            t = [];
            rate = [];
            flag_exists = true;
            flag_isempty= true;
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
         labels = [];
         
         [rate,flag_exists,flag_isempty] = parseStruct(obj.Data,field_expr_rate);
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
            [idx,labels] = obj.parseTrialIndicesFromIncludeStruct(align,includeStruct,outcome);
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
         rate = rate(:,:,obj.ChannelMask);

         % Exclude based on area if 'RFA' or 'CFA' are explicitly specified
         if strcmpi(area,'RFA') || strcmpi(area,'CFA')
            ch_idx = contains({obj.ChannelInfo(obj.ChannelMask).area},area);
            rate = rate(:,:,ch_idx);
         end

         % If asked to update area modulations, do so for the rate
         % structure given default parameters in defaults.block regarding
         % the relevant indexing for time-periods to look at modulations in
         if updateAreaModulations
            obj.updateChMod(rate,t,true);
         end

         
      end
      
      % Alternative way to get/set include struct that's a little more
      % general than the initial methods
      [rate,t] = getSetIncludeStruct(obj,align,includeStruct,rate,t)
      
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
      
   end
   
   % Methods for setting BLOCK object properties
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
   
   methods (Access = private)
      % Initialize a function that counts trials in any recently-retrieved
      % alignment condition average
      function initRecentTrialCounter(obj)
         obj.nTrialRecent = struct('rate',0,'marg',0);
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
      function y = doSmoothNorm(x,idx)
         if nargin < 2
            idx = defaults.block('pre_trial_norm_ds');
         end
         
         filter_order = defaults.block('lpf_order');
         fs = defaults.block('fs');
         cutoff_freq = defaults.block('lpf_fc');
         if ~isnan(cutoff_freq)
            [b,a] = butter(filter_order,cutoff_freq/(fs/2),'low');
         end

         z = sqrt(abs(x)) .* sign(x);
         z = z - mean(z(:,idx,:),2);
         if isnan(cutoff_freq)
            y = z;
         else
            y = nan(size(z));
            for iZ = 1:size(z,3)
               for iT = 1:size(z,1)
                  y(iT,:,iZ) = filtfilt(b,a,z(iT,:,iZ));
               end
            end
         end
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
      
      % Make "probechannel" array from ChannelInfo struct
      function pCh = makeProbeChannel(channelInfo)
         pCh = horzcat(vertcat(channelInfo.probe),vertcat(channelInfo.channel));
      end
      
      % Match probe and channel
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

