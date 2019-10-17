classdef rat < handle
   %RAT  Object to organize data for an individual rat from RC project
   
   properties (GetAccess = public, SetAccess = private)
      Name           % Name of this rat
      Parent         % Parent GROUP object
      ChannelInfo    % Channel information struct
      Children       % Children BLOCK objects
      Data           % Struct to hold RAT-level data
   end
   
   properties (Access = private)
      Folder         % Location of TANK that holds rat folders
      ChannelMask    % Masking of channels for this rat
   end
   
   properties (Access = public, Hidden = true)
      ScreeningUI       % Figure UI for screening data channels
      HasData = false;  % Flag for whether any blocks have data for rat
   end
   
   methods (Access = public)
      % Rat class constructor
      function obj = rat(path,align,extractSpikeRate,runJPCA)
         if nargin < 1
            path = obj.uiPathDialog;
         elseif isempty(path)
            path = obj.uiPathDialog;
         end
         
         if path == 0
            fprintf(1,'No rat selected. Rat object not created.');
            obj = [];
            return;
         end
         
         if nargin < 2
            align = defaults.rat('batch_align');
         end
         
         if nargin < 3
            extractSpikeRate = defaults.rat('do_spike_rate_extraction');
         end
         
         if nargin < 4
            runJPCA = defaults.rat('run_jpca_on_construction');
         end
         
         if exist(path,'dir')==0
            error('Invalid path: %s',path);
         else
            pathInfo = strsplit(path,filesep);
            obj.Name = pathInfo{end};
            obj.Folder = strjoin(pathInfo(1:(end-1)),filesep);
         end
         obj.ChannelInfo = getChannelInfo(obj.Name,...
            defaults.rat('icms_file'));         
         ratTic = tic;
         fprintf(1,'-------------------------------------------------\n');
         fprintf(1,'\t\t%s\n',obj.Name);
         fprintf(1,'-------------------------------------------------\n');
         findChildren(obj,align,extractSpikeRate,runJPCA);
         if (defaults.rat('suppress_data_curation'))
%             obj.ChannelMask = obj.Children(1).ChannelMask;
            obj.loadChannelMask;
         else
            fig = dataScreeningUI(obj);
            waitfor(fig);
         end
         
         fprintf(1,'-------------------------------------------------\n');
         fprintf(1,'\t\t\t\t\t%s --> %g sec\n\n',obj.Name,round(toc(ratTic)));
      end
      
      % Assign data from PCA re-basis to child block objects
      function assignBasisData(obj,coeff,score,x,pc_idx,p,channelInfo)
         name = {channelInfo.file}.';
         blockName = cellfun(@(x)x(1:16),name,'UniformOutput',false);
         for ii = 1:numel(obj.Children)
            idx = ismember(blockName,obj.Children(ii).Name);
            assignBasisData(obj.Children(ii),coeff,score(idx,:),x(idx,:),pc_idx,p,channelInfo(idx));
         end
      end
      
      % Assign divergence data relating divergence of jPCA successful &
      % unsuccessful trajectories in primary jPCA plane
      function assignDivergenceData(obj,T)
         if numel(obj) > 1
            for ii = 1:numel(obj)
               Tsub = T(ismember(T.Rat,obj(ii).Name),:);
               if isempty(Tsub)
                  fprintf(1,'No divergence data for %s.\n',obj(ii).Name);
                  continue;
               else
                  assignDivergenceData(obj(ii),Tsub);
               end
            end
            return;
         end
         setDivergenceData(obj.Children,T);
      end
      
      % Make a "screening" UI for marking channel masking
      function fig = dataScreeningUI(obj)
         if isempty(obj.ScreeningUI)
         
            fig = figure('Name',...
               sprintf('%s: Data Screening UI',obj.Name),...
               'Units','Normalized',...
               'Position',[0.1 0.1 0.8 0.8],...
               'Color','w');
            obj.ScreeningUI = fig;
         else
            if ~isvalid(obj.ScreeningUI)
               fig = figure('Name',...
                  sprintf('%s: Data Screening UI',obj.Name),...
                  'Units','Normalized',...
                  'Position',[0.1 0.1 0.8 0.8],...
                  'Color','w');
               obj.ScreeningUI = fig;
            else
               fig = obj.ScreeningUI;
            end
         end
         
         if isempty(obj.ChannelMask)
            obj.ChannelMask = true(size(obj.ChannelInfo));
         end
         
         align = defaults.jPCA('jpca_align');
         
         nAxes = numel(obj.ChannelInfo);
         ax = uiPanelizeAxes(fig,nAxes);
         
         cm = defaults.load_cm;
         idx = round(linspace(1,size(cm,1),numel(obj.Children)));
         
         % Make a separate axes for each channel
         for iCh = 1:nAxes
            ax(iCh).NextPlot = 'add';
            ax(iCh).UserData = iCh;
            ax(iCh).ButtonDownFcn = @obj.toggleMaskForChannel;
            
            if obj.ChannelMask(iCh)
               ax(iCh).Color = 'w';
               ax(iCh).XColor = 'k';
               ax(iCh).YColor = 'k';
            else
               ax(iCh).Color = 'k';
               ax(iCh).XColor = 'w';
               ax(iCh).YColor = 'w';               
            end
            
            filter_order = defaults.rat('lpf_order');
            fs = defaults.rat('fs');
            cutoff_freq = defaults.rat('lpf_fc');
            if ~isnan(cutoff_freq)
               [b,a] = butter(filter_order,cutoff_freq/(fs/2),'low');
            end
            
            % Superimpose FILTERED rate traces on the channel axes
            for ii = 1:numel(obj.Children)
               ch = obj.Children(ii).matchChannel(iCh);
               if isempty(ch)
                  continue;
               end
               x = getAvgSpikeRate(obj.Children(ii),align,'Successful',ch);
               
               if ~isnan(cutoff_freq) && ~isnan(x(1))
                  y = filtfilt(b,a,x);
               else
                  y = x;
               end
               plot(ax(iCh),...
                  obj.Children(ii).T*1e3,... % convert to ms
                  y,...                      % plot filtered trace
                  'Color',cm(idx(ii),:),...  % color by day
                  'LineWidth',2.25-(ii/numel(obj.Children)),...
                  'UserData',[iCh,ii],...
                  'ButtonDownFcn',@obj.toggleMaskForChannel);
            end   
            ax(iCh).XLim = defaults.rat('x_lim_screening');
            ax(iCh).YLim = defaults.rat('y_lim_screening');
         end
         
      end
      
      % Export down-sampled rate data for dPCA. If no output argument is
      % specified, then files are saved in the default location from
      % defaults.dPCA. In this version, days are stimuli and successful or
      % unsuccessful retrieval are the decision.
      function [X,t,trialNum] = export_dPCA_days_are_stimuli(obj)
         % Parse array input
         if numel(obj) > 1
            if nargout < 1
               for ii = 1:numel(obj)
                  export_dPCA_days_are_stimuli(obj(ii));
               end
            else
               X = cell(numel(obj),1);
               trialNum = cell(numel(obj),1);
               for ii = 1:numel(obj)
                  [X{ii},t,trialNum{ii}] = export_dPCA_days_are_stimuli(obj(ii)); % t always the same
               end
            end
            return;
         end
         
         p = defaults.dPCA;
         addpath(p.local_repo_loc);
         
         [normRatesCell,t,trialNum] = format_dPCA_days_are_stimuli(obj.Children);
         removeBlock = cellfun(@(x)isempty(x),normRatesCell,'UniformOutput',true);
         normRatesCell(removeBlock) = [];
         trialNum(:,removeBlock,:) = [];
         setProp(obj.Children,'dPCA_include',removeBlock);
         
         nTrialMax = max(cellfun(@(x)size(x,5),normRatesCell,...
                           'UniformOutput',true));
         nChannel = sum(obj.ChannelMask);
         nDay = numel(normRatesCell);               
         nTs = numel(t);
         
         X = nan(nChannel,nDay,3,nTs,nTrialMax);
         for ii = 1:nDay
            X(:,ii,:,:,1:size(normRatesCell{ii},5)) = normRatesCell{ii};            
         end       
         
         % If no output argument, save data in array X
         if nargout < 1
            fname = fullfile(p.path,sprintf(p.fname,obj.Name));
            save(fname,'X','t','trialNum','-v7.3');
         end
      end
      
      % Export down-sampled rate data for dPCA. If no output argument is
      % specified, then files are saved in the default location from
      % defaults.dPCA. in this version, pellet presence is the stimulus and
      % the decision is whether to do a secondary reach or not.
      function [X,t,trialNum] = export_dPCA_pellet_present_absent(obj)
         % Parse array input
         if numel(obj) > 1
            if nargout < 1
               for ii = 1:numel(obj)
                  export_dPCA_pellet_present_absent(obj(ii));
               end
            else
               X = cell(numel(obj),1);
               trialNum = cell(numel(obj),1);
               for ii = 1:numel(obj)
                  [X{ii},t,trialNum{ii}] = export_dPCA_pellet_present_absent(obj(ii)); % t always the same
               end
            end
            return;
         end
         
         [X,t,trialNum] = format_dPCA_pellet_present_absent(obj.Children);
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
         
         T = exportTrialStats(obj.Children);
         
         % Extend variable descriptors to an additional metadata field
         ud = T.Properties.UserData;
         vd = T.Properties.VariableDescriptions;
         Rat = repmat(categorical({obj.Name}),size(T,1),1);
         
         T = [table(Rat), T];
         T.Properties.Description = 'Concatenated Trial Metadata';
         T.Properties.UserData = [nan(1,1), ud];
         T.Properties.VariableDescriptions = ['rat name', vd];
      end
      
      % Export "unified" jPCA trial projections from all days
      function exportUnifiedjPCA_movie(obj,align,area)
         if nargin < 2
            align = defaults.jPCA('jpca_align');
         end
         
         if nargin < 3
            area = 'Full';
         end
         
         % Parse array
         if numel(obj) > 1
            for ii = 1:numel(obj)
               obj(ii).exportUnifiedjPCA_movie(align,area);
            end
            return;
         end
         
         if ~isfield(obj.Data,area)
            obj.unifyjPCA(align,area);
         end
         
         vid_folder = fullfile(defaults.jPCA('video_export_base'),...
            'Successful',area);
         output_score = defaults.group('output_score');
         score = mean(getProp(obj,output_score));
         movie_params = defaults.jPCA('movie_params',...
            obj.Data.Summary.outcomes+2,score);
         
         t = defaults.jPCA('analyze_times');
         lpf_fc = defaults.block('lpf_fc');
         moviename = sprintf('%s_%s_allDays_%gms_to_%gms_%gHzFc',...
            obj.Name,align,t(1),t(end),lpf_fc);
         movie_params.movieName = moviename;
         
         
         if ~isempty(obj.Parent)
            moviename = fullfile(pwd,...
               vid_folder,obj.Parent.Name,obj.Name,moviename);
         else
            moviename = fullfile(pwd,...
               vid_folder,obj.Name,moviename);
         end

         vidTic = tic;
         
         fprintf(1,'Exporting video:\n-->\t\t%s\n',moviename);
         if ~isempty(obj.Data.(area).Projection)
            jPCA.export_jPCA_movie(jPCA.phaseMovie(...
               obj.Data.(area).Projection,...
               obj.Data.(area).Summary, ...
               movie_params),...
               moviename);
         else
            fprintf('\t-->\t(Unsuccessful)\n');
         end
         toc(vidTic);
      end
      
      % Find children blocks associated with this rat
      function findChildren(obj,align,extractSpikeRate,runJPCA)
         if nargin < 2
            align = defaults.rat('batch_align');
         end
         
         if nargin < 3
            extractSpikeRate = defaults.rat('do_spike_rate_extraction');
         end
         
         if nargin < 4
            runJPCA = defaults.rat('run_jpca_on_construction');
         end
         
         path = fullfile(obj.Folder,obj.Name);
         F = dir(fullfile(path,[obj.Name '_2*']));
         for iF = 1:numel(F)
            maintic = tic;
            h = block(fullfile(F(iF).folder,F(iF).name),...
               align,extractSpikeRate,runJPCA);
            if h.HasData
               obj.addChild(h,maintic);
            else
               fprintf(1,'-->\tNo data in %s. Skipped.\t\t(%g sec)\n',...
                  h.Name,round(toc(maintic)+3));
            end
         end
      end
      
      % Return average rates of children
      function [avgRate,channelInfo] = getAvgSpikeRate(obj,align,outcome)
         if nargin < 3
            outcome = defaults.rat('batch_outcome');
         end
         
         if nargin < 2
            align = defaults.rat('batch_align');
         end
         
         if numel(obj) > 1
            c = vertcat(obj.Children);
         else
            c = obj.Children;
         end
         [avgRate,channelInfo] = getAvgSpikeRate(c,align,outcome);
      end
      
      % Returns the names of all block children objects
      function names = getBlockNames(obj)
         names = cell(size(obj.Children));
         for ii = 1:numel(obj.Children)
            names{ii} = obj.Children(ii).Name;
         end
      end
      
      % Return property pertaining to channels across days
      function [out,ratName,postOpDay,Score,blockName] = getChannelProp(obj,propName,align,outcome,area)
         if (nargin < 5) && (numel(obj) == 1)
            if isprop(obj,propName)
               out = obj.(propName)(obj.ChannelMask,:);
               ratName = repmat({obj.Name},size(out,1),1);
            elseif isempty(propName)
               out = [];
               ratName = repmat({obj.Name},numel(obj.Children),1);
            else
               out = [];
               ratName = [];
               return;
            end
         else
            out = []; ratName = [];
            output_score = defaults.group('output_score');
            if numel(obj) > 1
               for ii = 1:numel(obj)
                  [tmp,name,day,score,blockname] = getChannelProp(obj(ii),propName,align,outcome,area);
                  ratName = [ratName; name];
                  out = [out; tmp];
                  postOpDay = [postOpDay; day];
                  Score = [Score; score];
                  blockName = [blockName; blockname];
               end
               return;
            end
            
            if ~isempty(propName)
               postOpDay = [];
               Score = [];
               blockName = [];
               for ii = 1:numel(obj.Children)
                  [flag,jP] = getChecker(obj.Children(ii),align,outcome,area);
                  if flag
                     continue;
                  else
                     tmp = jP.Summary.(propName);
                     out = [out; tmp];
                     ratName = [ratName; repmat({obj.Name},size(tmp,1),1)];
                     postOpDay = [postOpDay; ...
                        getPropForEachChannel(obj.Children(ii),'PostOpDay')];
                     Score = [Score; ...
                        getPropForEachChannel(obj.Children(ii),output_score)];
                     blockName = [blockName; ...
                        getPropForEachChannel(obj.Children(ii),'Name')];
                  end
               end
            else
               out = [];
               postOpDay = [];
               Score = [];
               blockName = [];
               for ii = 1:numel(obj.Children)               
                  postOpDay = [postOpDay; ...
                     getPropForEachChannel(obj.Children(ii),'PostOpDay')];
                  Score = [Score; ...
                     getPropForEachChannel(obj.Children(ii),output_score)];
                  blockName = [blockName; ...
                     getPropForEachChannel(obj.Children(ii),'Name')];
               end
               ratName = repmat({obj.Name},numel(postOpDay),1);
            end
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
         
         if nargout < 1
            getChannelwiseRateStats(obj.Children,align,outcome);
         else
            stats = getChannelwiseRateStats(obj.Children,align,outcome);
         end
      end
      
      % Return the path to rat-related folder
      function path = getPathTo(obj,dataType)
         if numel(obj) > 1
            error('This method only applies to scalar Rat objects.');
         end
         switch dataType
            case {'dPCA','dpca'}
               path = defaults.dPCA('path');
            case {'Rat','rat','home','Home'}
               path = obj.Folder;
            case {'analysis','analyses','Analysis','Analyses','output','Output'}   
               path = fullfile(obj.Folder,sprintf('%s_analyses',obj.Name));
            otherwise
               path = [];
               fprintf(1,'%s is an unknown value for ''dataType'' input.\n',dataType);
         end
      end
      
      % Return phase information for jPCA
      function phaseData = getPhase(obj,align,outcome,area)
         if nargin < 4
            area = 'Full';
         end
         if nargin < 3
            outcome = 'All';
         end
         if nargin < 2
            align = defaults.jPCA('jpca_align');
         end
         
         if numel(obj) > 1
            phaseData = [];
            for ii = 1:numel(obj)
               phaseData = [phaseData; obj(ii).getPhase(align,outcome,area)];
            end
            return;
         end
         fprintf(1,'-->\tGetting phase data for %s...\n',obj.Name);
         phaseData = getPhase(obj.Children,align,outcome,area);
      end
      
      % Return some property of children blocks if it exists
      function out = getProp(obj,propName)
         out = [];
         
         if numel(obj) > 1
            for ii = 1:numel(obj)
               out = [out; getProp(obj(ii),propName)];
            end
            return;
         end
         
         for ii = 1:numel(obj)
            if isfield(obj.Data,propName)
               out = [out; obj.Data.(propName)];
            elseif isprop(obj,propName) && ~ismember(propName,{'Data'})
               out = [out; obj.(propName)];
            else
               out = [out; getProp(obj.Children,propName)];
            end
         end
      end
      
      % Shortcut to run jPCA on all children objects
      function jPCA(obj,align)
         if nargin < 2
            align = defaults.jPCA('jpca_align');
         end
         
         if numel(obj) > 1
            for ii = 1:numel(obj)
               jPCA(obj(ii),align);
            end
            return;
         end
         jPCA(obj.Children,align);
      end
      
      % Shortcut to export jPCA movie for all children objects
      function jPCA_movie(obj,align,outcome,area)
         if nargin < 4
            area = defaults.rat('batch_area');
         end
         
         if nargin < 3
            outcome = defaults.rat('batch_outcome');
         end
         
         if nargin < 2
            align = defaults.rat('batch_align');
         end
         
         if numel(obj) > 1
            for ii = 1:numel(obj)
               jPCA_movie(obj(ii),align,outcome,area);
            end
            return;
         end
         
         jPCA_movie(obj.Children,align,outcome,area);
         
      end
      
      % Shortcut for jPCA_suppress runFun
      function [Projection,Summary] = jPCA_suppress(obj,active_area,align,outcome,doReProject)
         if nargin < 5
            doReProject = false;
         end
         
         if nargin < 4
            outcome = 'All';
         end
         
         if nargin < 3
            align = 'Grasp';
         end
         
         if numel(obj) > 1
            if nargout > 1
               Projection = cell(numel(obj),1);
               Summary = cell(numel(obj),1);
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
         
         if nargout > 1
            [Projection,Summary] = jPCA_suppress(obj.Children,active_area,align,outcome,doReProject);
         else
            jPCA_suppress(obj.Children,active_area,align,outcome,doReProject);
         end
      end
      
      % Load "by-day" dPCA-formatted rates
      function [X,t,trialNum] = load_dPCA(obj)
         if numel(obj) > 1
            X = cell(numel(obj),1);
            trialNum = cell(numel(obj),1);
            for ii = 1:numel(obj)
               [X{ii},t,trialNum{ii}] = load_dPCA(obj(ii)); % t is always the same
            end
            return;
         end
         p = obj.getPathTo('dPCA');
         f = defaults.dPCA('fname');
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
      
      % Plot the relevant PCA data for a given channel across days
      function fig = plotChannelPC(obj,ch)
         if ~obj.HasData
            fprintf(1,'No data in %s.\n',obj.Name);
            return;
         end
         
         if nargin < 2
            fig = [];
            for ii = 1:size(obj.ChannelInfo,1)
               fig = [fig; obj.plotChannelPC(ii)]; %#ok<*AGROW>
            end
            return;
         end
         
         fig = figure('Name',sprintf('Rat %s Probe %g Channel %g PCA',...
            obj.Name,obj.ChannelInfo(ch).probe,obj.ChannelInfo(ch).channel),...
            'Units','Normalized',...
            'Color','w',....
            'Position',[0.1 0.1 0.75 0.75]);
         
         [pcScore,pcCoeff,t,postOpDay] = queryChannelPC(obj,ch);
         nRow = floor(sqrt(numel(pcCoeff)));
         nCol = ceil(numel(pcCoeff)/nRow);
         
         for ii = 1:numel(pcCoeff)
            subplot(nRow,nCol,ii);
            vec = ((ii-1)*3+1):(ii*3);
            plot(t,pcScore(:,vec),'LineWidth',2);
            xlabel('Time (s)','FontName','Arial','FontSize',14);
            ylabel('PC Amplitude','FontName','Arial','FontSize',14);
            title(sprintf('PO-Day: %02g',postOpDay(vec(1))),...
               'FontName','Arial','FontSize',16);
            ylim([-200 300]);
            xlim([min(t) max(t)]);
         end
         
      end
      
      % Plot rate averages across days for all channels
      function fig = plotRateAverages(obj,align,outcome)
         if nargin < 3
            outcome = defaults.rat('batch_outcome');
         end
         
         if nargin < 2
            align = defaults.rat('batch_align');
         end
         
         if numel(obj)>1
            if nargout < 1
               for ii = 1:numel(obj)
                  plotRateAverages(obj(ii),align,outcome);
               end
            else
               fig = [];
               for ii = 1:numel(obj)
                  fig = [fig; plotRateAverages(obj(ii),align,outcome)];
               end
            end
            return;
         end
            
         fig = figure('Name',...
                  sprintf('%s: %s-%s Average Rates',obj.Name,align,outcome),...
                  'Units','Normalized',...
                  'Position',[0.1 0.1 0.8 0.8],...
                  'Color','w');
         
         nAxes = numel(obj.ChannelInfo);
         ax = uiPanelizeAxes(fig,nAxes);
         
         
         % Parse parameters for coloring lines, smoothing plots
         cm = defaults.load_cm;
         idx = round(linspace(1,size(cm,1),numel(obj.Children)));
         filter_order = defaults.rat('lpf_order');
         fs = defaults.rat('fs');
         cutoff_freq = defaults.rat('lpf_fc');
         if ~isnan(cutoff_freq)
            [b,a] = butter(filter_order,cutoff_freq/(fs/2),'low');
         end
         
         
         % Make a separate axes for each channel
         
         
         
         for iCh = 1:nAxes
            ax(iCh).NextPlot = 'add';
            ax(iCh).UserData = iCh;
            
            if obj.ChannelMask(iCh)
               ax(iCh).Color = 'w';
               ax(iCh).XColor = 'k';
               ax(iCh).YColor = 'k';
            else
               ax(iCh).Color = 'k';
               ax(iCh).XColor = 'w';
               ax(iCh).YColor = 'w';               
            end
            
            str = sprintf('%s-%s-%s',obj.ChannelInfo(iCh).ml,...
               obj.ChannelInfo(iCh).icms,...
               obj.ChannelInfo(iCh).area);
            ax(iCh).Title.String = str;
            ax(iCh).Title.FontName = 'Arial';
            ax(iCh).Title.FontSize = 14;
            ax(iCh).Title.Color = 'k';
            ax(iCh).XLim = defaults.rat('x_lim_screening');
            ax(iCh).YLim = defaults.rat('y_lim_screening');
%             legText = [];
%             legText = [legText;...
%                   {sprintf('D%02g',obj.Children(ii).PostOpDay)}];            
%             legend(ax(iCh),legText,'Location','NorthWest');
            
         end
            
         
         for ii = 1:numel(obj.Children)
          
            % Superimpose FILTERED rate traces on the channel axes
            x = getAvgSpikeRate(obj.Children(ii),align,outcome);
            % Here, add option to filter using parameters from RAT
            if ~isnan(cutoff_freq)
               y = filtfilt(b,a,x); 
            else
               y = x; % default
            end
            
            for iCh = 1:nAxes  
               ch = obj.Children(ii).matchChannel(iCh);
               if isempty(ch)
                  continue;
               end
               plot(ax(iCh),...
                  obj.Children(ii).T*1e3,... % convert to ms
                  y(ch,:),...                % plot filtered trace
                  'Color',cm(idx(ii),:),...  % color by day
                  'LineWidth',2.25-(ii/numel(obj.Children)),...
                  'UserData',[iCh,ii]);
            end
            

         end
         
         if nargout < 1
            rate_avg_fig_dir = fullfile(pwd,...
               defaults.rat('rate_avg_fig_dir'));
            if exist(rate_avg_fig_dir,'dir')==0
               mkdir(rate_avg_fig_dir);
            end
            savefig(fig,fullfile(rate_avg_fig_dir,...
               sprintf('%s_%s-%s_Average-Spike-Rates.fig',obj.Name,...
                  align,outcome)));
            saveas(fig,fullfile(rate_avg_fig_dir,...
               sprintf('%s_%s-%s_Average-Spike-Rates.png',obj.Name,...
                  align,outcome)));
            delete(fig);
         end
         
      end
      
      % Plot rate averages across days for all channels
      function fig = plotNormAverages(obj,align,outcome)
         if nargin < 3
            outcome = defaults.rat('batch_outcome');
         end
         
         if nargin < 2
            align = defaults.rat('batch_align');
         end
         
         if numel(obj)>1
            if nargout < 1
               for ii = 1:numel(obj)
                  plotNormAverages(obj(ii),align,outcome);
               end
            else
               fig = [];
               for ii = 1:numel(obj)
                  fig = [fig; plotNormAverages(obj(ii),align,outcome)];
               end
            end
            return;
         end
            
         fig = figure('Name',...
                  sprintf('%s: %s-%s Normalized Average Rates',obj.Name,align,outcome),...
                  'Units','Normalized',...
                  'Position',[0.1 0.1 0.8 0.8],...
                  'Color','w');
         
         nAxes = numel(obj.ChannelInfo);
         nDays = numel(obj.Children);
         total_rate_avg_subplots = defaults.rat('total_rate_avg_subplots');
         legPlot = defaults.rat('rate_avg_leg_subplot');
         
         ax = uiPanelizeAxes(fig,total_rate_avg_subplots);
         
         % Assumption is that there is a maximum of 32 channels to plot
         % Assume that legend subplot goes on the last axes
         for iCh = (nAxes+1):(total_rate_avg_subplots-1)
            delete(ax(iCh));
         end
         
         
         % Parse parameters for coloring lines, smoothing plots
         [cm,nColorOpts] = defaults.load_cm;
         
         idx = round(linspace(1,size(cm,1),nColorOpts));        
         
         % Make a separate axes for each channel
         for iCh = 1:nAxes
            ax(iCh) = obj.createRateAxes(obj.ChannelMask(iCh),...
               obj.ChannelInfo(iCh),ax(iCh));           
         end   
         
         ax(legPlot).NextPlot = 'add';
         ax(legPlot).XLim = [0 nColorOpts+1];
         ax(legPlot).YLim = [0 2.5];
         ax(legPlot).XColor = 'k';
         ax(legPlot).YColor = 'w';
         ax(legPlot).FontName = 'Arial';  
         ax(legPlot).FontSize = 10;
         ax(legPlot).LineWidth = 1.5;
         ax(legPlot).YAxisLocation = 'right';
         
         % Shift legend axes over a little bit and make it wider while
         % squishing it slightly in the vertical direction:
         p = ax(legPlot).Position;
         ax(legPlot).Position = p + [-2.75 * p(3),  0.33 * p(4),...
                                      2.5 * p(3), -0.33 * p(4)];
         xlabel(ax(legPlot),'Post-Op Day',...
            'FontSize',14,'Color','k',...
            'FontName','Arial','FontWeight','bold');
         ylabel(ax(legPlot),'Relative Modulation',...
            'FontSize',12,'Color','k',...
            'FontName','Arial');
         
         for ii = 1:nDays
            % Superimpose FILTERED rate traces on the channel axes
            [x,~,t] = getAvgNormRate(obj.Children(ii),align,outcome);
            if isempty(t)
               continue;
            end
            poDay = obj.Children(ii).PostOpDay;
            
            % Get average "peak modulation" across channels for the legend
            chMod = nanmean(max(abs(x),[],2));
            for iCh = 1:nAxes  
               ch = obj.Children(ii).matchChannel(iCh);
               if isempty(ch)
                  continue;
               end
               plot(ax(iCh),...
                  t,...                      
                  x(ch,:),...                   % plot filtered trace
                  'Color',cm(idx(poDay),:),...  % color by day
                  'LineWidth',2.25-(poDay/numel(idx)),...
                  'UserData',[iCh,ii]);
            end
            str = sprintf('D%02g',poDay);
%             plot(ax(legPlot),[-0.5 0.5]+poDay,[1 1],...
%                'Color',cm(idx(poDay),:),...  % color by day
%                'LineWidth',2.25-(poDay/numel(idx)),...
%                'Tag',str,...
%                'UserData',[legPlot,ii]);
            bar(ax(legPlot),poDay,chMod,1,...
               'EdgeColor','none',...
               'FaceColor',cm(idx(poDay),:),...
               'Tag',str,...
               'UserData',[legPlot,ii]);
            
         end
         
%          lgd = legend(ax(legPlot),legText,...
%             'Location','north',...
%             'Orientation','horizontal');
%          title(lgd,'Post-Operative Day','Color','k','FontName','Arial');
%          lgd.FontSize = 10;
%          lgd.TextColor = 'black';
         
         if nargout < 1
            norm_avg_fig_dir = fullfile(pwd,...
               defaults.rat('norm_avg_fig_dir'));
            if exist(norm_avg_fig_dir,'dir')==0
               mkdir(norm_avg_fig_dir);
            end
            savefig(fig,fullfile(norm_avg_fig_dir,...
               sprintf('%s_%s-%s_Average-Normalized-Spike-Rates.fig',obj.Name,...
                  align,outcome)));
            saveas(fig,fullfile(norm_avg_fig_dir,...
               sprintf('%s_%s-%s_Average-Normalized-Spike-Rates.png',obj.Name,...
                  align,outcome)));
            delete(fig);
         end
         
      end
      
      % Queries the PCs of a given channel across days
      function [pcScore,pcCoeff,t,postOpDay] = queryChannelPC(obj,ch)
         if ~obj.HasData
            pcScore = [];
            pcCoeff = [];
            t = [];
            postOpDay = [];
            fprintf(1,'No data in %s.\n',obj.Name);
            return;
         end
         
         t = obj.Children(1).Data.pc{ch}.t;
         
         pcScore = nan(numel(t),numel(obj.Children)*3);
         pcCoeff = cell(numel(obj.Children),1);
         postOpDay = nan(1,numel(obj.Children)*3);
         
         for ii = 1:numel(obj.Children)
            vec = ((ii-1)*3+1):(ii*3);
            postOpDay(vec) = obj.Children(ii).PostOpDay;
            iCh = obj.Children(ii).matchChannel(ch);
            if ~isempty(iCh)
               pcScore(:,vec) = obj.Children(ii).Data.pc{iCh}.score;
               pcCoeff{ii} = obj.Children(ii).Data.pc{iCh}.coeff;
            end
         end
      end
      
      % Run dPCA analysis for Rat object or object array
      function out = run_dPCA_days_are_stimuli(obj)
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
         addpath(defaults.dPCA('local_repo_loc'));
         [firingRates,time,trialNum] = load_dPCA(obj);
         firingRatesAverage = nanmean(firingRates,5);
         S = size(firingRatesAverage,2);
         
         combinedParams = defaults.dPCA('combinedParams');
         margNames = defaults.dPCA('margNames');
         margColours = defaults.dPCA('margColours');
         timeEvents = 0;
         
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
          
%          %% Step 2: PCA in each marginalization separately
%          dpca_perMarginalization(firingRatesAverage, @dpca_plot_default, ...
%             'combinedParams', combinedParams);
%          
%          %% Step 3: dPCA without regularization and ignoring noise covariance
% 
%          % This is the core function.
%          % W is the decoder, V is the encoder (ordered by explained variance),
%          % whichMarg is an array that tells you which component comes from which
%          % marginalization
% 
%          [W,V,whichMarg] = dpca(firingRatesAverage, 20, ...
%              'combinedParams', combinedParams);
% 
%          explVar = dpca_explainedVariance(firingRatesAverage, W, V, ...
%              'combinedParams', combinedParams);
% 
%          dpca_plot(firingRatesAverage, W, V, @dpca_plot_default, ...
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
%           
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
%              'explainedVar', explVar, ...
%              'marginalizationNames', margNames, ...
%              'marginalizationColours', margColours, ...
%              'whichMarg', whichMarg,                 ...
%              'time', time,                        ...
%              'timeEvents', timeEvents,               ...
%              'timeMarginalization', 3,           ...
%              'legendSubplot', 16,...
%              'figName',sprintf('%s: regularized dPCA',obj.Name),...
%              'figPos',[0.1+0.01*randn(1) 0.1+0.01*randn(1) 0.8 0.8]);
         
          
          
        decodingClasses = {...
           [(1:S)' (1:S)' (1:S)'],...
           repmat(1:3, [S 1]), ...
           [], ...
           [(1:S)' (S+(1:S))' (2*S+(1:S))']};
  
        accuracy = dpca_classificationAccuracy(firingRatesAverage, firingRates, trialNum, ...
             'lambda', optimalLambda, ...
             'combinedParams', combinedParams, ...
             'decodingClasses', decodingClasses, ...
             'simultaneous', true, ...
             'numRep', 5, ...        % increase to 100
             'filename', 'tmp_classification_accuracy.mat');

        dpca_classificationPlot(accuracy, [], [], [], decodingClasses)

        accuracyShuffle = dpca_classificationShuffled(firingRates, trialNum, ...
             'lambda', optimalLambda, ...
             'combinedParams', combinedParams, ...
             'decodingClasses', decodingClasses, ...
             'simultaneous', true, ...
             'numRep', 5, ...        % increase to 100
             'numShuffles', 20, ...  % increase to 100 (takes a lot of time)
             'filename', 'tmp_classification_accuracy.mat');

        dpca_classificationPlot(accuracy, [], accuracyShuffle, [], decodingClasses)

        componentsSignif = dpca_signifComponents(accuracy, accuracyShuffle, whichMarg);

        dpca_plot(firingRatesAverage, W, V, @dpca_plot_default, ...
             'explainedVar', explVar, ...
             'marginalizationNames', margNames, ...
             'marginalizationColours', margColours, ...
             'whichMarg', whichMarg,                 ...
             'time', time,                        ...
             'timeEvents', timeEvents,               ...
             'timeMarginalization', 3,           ...
             'legendSubplot', 16,                ...
             'componentsSignif', componentsSignif,...
             'figName',sprintf('%s: regularized classified dPCA',obj.Name),...
             'figPos',[0.1+0.01*randn(1) 0.1+0.01*randn(1) 0.8 0.8]);
          
          
         out = struct;
         out.W = W;
         out.V = V;
         out.whichMarg = whichMarg;
         out.explVar = explVar;
         out.accuracy = accuracy;
         out.accuracyShuffle = accuracyShuffle;
         out.decodingClasses = decodingClasses;
         out.componentsSignif = componentsSignif;
         
          
         fprintf(1,'dPCA completed: %s\n',obj.Name);
         
      end
      
      % Run function on children Block objects
      function runFun(obj,f)
         if isa(f,'function_handle')
            f = char(f); 
         end
         
         for ii = 1:numel(obj.Children)
            if ismethod(obj.Children(ii),f)
               obj.Children(ii).(f);
            else
               fprintf(1,'%s is not a method of %s BLOCK object.\n',...
                  f,obj.Children(ii).Name);
            end
         end
      end
      
      % Set "AllDaysScore" for child Block ojects
      function setAllDaysScore(obj,score)
         if numel(obj) > 1
            error('This method is only for scalar Rat objects.');
         end
         
         if numel(score) ~= numel(obj.Children)
            error('Must have an element of score for each child block object.');
         end
         
         setAllDaysScore(obj.Children,score);
      end
      
      % Set Parent group
      function setParent(obj,p)
         if isa(p,'group')
            obj.Parent = p;
         else
            fprintf(1,'Parent of ''rat'' class must be ''group'' class.\n');
         end
      end
      
      % Update stats re: point of max. variance
      function updateMaxVarData(obj,align,outcome)
         if nargin < 2
            align = defaults.rat('batch_align');
         end
         
         if nargin < 3
            outcome = defaults.rat('batch_outcome');
         end
         
         if numel(obj) > 1
            for ii = 1:numel(obj)
               updateMaxVarData(obj(ii),align,outcome);
            end
            return;
         end
         
         [avgRate,channelInfo] = getAvgSpikeRate(obj,align,outcome);
         obj.Data.VarData = [];
         t = obj(1).Children(1).T;
         t_var_interest = defaults.rat('t_var_interest');
         t_idx = (t>=t_var_interest(1)) & (t<=t_var_interest(2));
         t = t(t_idx);
         for iCh = 1:size(obj.ChannelInfo,1)
            idx = ([channelInfo.probe]==obj.ChannelInfo(iCh).probe) &...
                  ([channelInfo.channel]==obj.ChannelInfo(iCh).channel);
            x = avgRate(idx,t_idx);
            v = var(x,[],1);
            [val,v_idx] = max(v);
            obj.Data.(align).(outcome).varData = ...
               [obj.Data.(align).(outcome).varData;...
                val,t(v_idx)];
         end
         
      end
      
      % Load channel mask
      function loadChannelMask(obj)
         
         % Iterate if object is an array
         if numel(obj) > 1
            for ii = 1:numel(obj)
               loadChannelMask(obj(ii));
            end
            return;
         end
         
         % Parse path and filename
         channel_mask_loc = defaults.rat('channel_mask_loc');
         pname = fullfile(pwd,channel_mask_loc);
         if exist(pname,'dir')==0
            error('Invalid Channel Mask path (%s does not exist)',channel_mask_loc);
         end
         fname = fullfile(pname,sprintf('%s_ChannelMask.mat',obj.Name));
         if exist(fname,'file')==0
            fprintf(1,'Rat Channel Mask file not found. Parsing from first child BLOCK (%s).\n',...
               obj.Children(1).Name);
            ChannelMask = parseChannelMaskFromChild(obj);
            save(fname,'ChannelMask');
         else
            in = load(fullfile(fname),'ChannelMask');
            ChannelMask = in.ChannelMask; %#ok<*PROP>
         end
         
         obj.unifyChildChannelMask(ChannelMask);
      end
      
      % Parse channel mask from an indexed child rat object
      function ChannelMask = parseChannelMaskFromChild(obj,idx)
         if nargin < 2
            idx = 1;
         end
         
         if numel(obj) > 1
            error('Can only parse channel mask for one rat object at a time.');
         end
         
         info = obj.Children(idx).ChannelInfo;
         if isempty(info)
            error('ChannelInfo not yet set for %s.',obj.Children(idx).Name);
         end
         mask = obj.Children(idx).ChannelMask;
         if isempty(mask)
            obj.Children(idx).loadChannelMask;
            mask = obj.Children(idx).ChannelMask;
            if isempty(mask)
               error('ChannelMask not yet set for %s.',obj.Children(idx).Name);
            end
         end
         
         chIdx = [[info.probe].',[info.channel].'];
         ChannelMask = false(size(obj.ChannelInfo,1),1);
         iSmallMask = 0;
         for ii = 1:size(obj.ChannelInfo,1)
            ChannelMask(ii) = ismember([obj.ChannelInfo(ii).probe,obj.ChannelInfo(ii).channel],chIdx,'rows');
            if ChannelMask(ii)
               iSmallMask = iSmallMask + 1;
               ChannelMask(ii) = ChannelMask(ii) && mask(iSmallMask);
            end               
         end
         
         
      end
      
      % Set the channel mask for all child BLOCK objects
      function unifyChildChannelMask(obj,channelMask)
         if nargin < 2
            channelMask = obj.ChannelMask;
         else
            obj.ChannelMask = channelMask;
         end
         
         for ii = 1:numel(obj.Children)
            for ch = 1:numel(obj.ChannelInfo)
               iCh = matchChannel(obj.Children(ii),ch);
               if ~isempty(iCh)
                  setChannelMask(obj.Children(ii),iCh,channelMask(ch));
               end
            end
         end
      end
      
      % Recover jPCA weights for channels using trials from all days
      function unifyjPCA(obj,align,area)
         % Parse alignment
         if nargin < 2
            align = defaults.jPCA('jpca_align');
         end
         
         % Parse area ('Full', 'RFA', or 'CFA')
         if nargin < 3
            area = 'Full'; % default
         end
         
         % Parse array
         if numel(obj) > 1
            clc;
            for ii = 1:numel(obj)
               unifyjPCA(obj(ii),align,area);
            end
            return;
         end
         
         % Get all the formatted trials from child objects
         fprintf(1,'\nCollecting jPCs from all %s successful %s trials (%s).\n',...
            obj.Name,align,area);
         [D,idx] = jPCA_format(obj.Children,align,'Successful',area);
         [Projection, Summary] = jPCA.jPCA(D);
         Summary.outcomes = idx;
         
         % Store the unified data
         obj.Data.(area).Projection = Projection;
         obj.Data.(area).Summary = Summary;
         
         fprintf(1,'-->\tRe-projecting jPCs for %g child BLOCK objects...\n\n',...
            numel(obj.Children));
         % Project data for children BLOCK objects
         jPCA_unified_project(obj.Children,align,area,Summary);
      end
      
      % Update Folder property of this and children objects
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
         
         % Update all Child blocks as well
         updateFolder(obj.Children,putative_objloc);
      end
   end
   
   methods (Access = private)
      % Add a child block object to this rat object
      function addChild(obj,h,tic_start)
         if nargin < 3
            tic_start = tic;
         end
         
         if isa(h,'block')
            names = obj.getBlockNames;
            if ~ismember(h.Name,names)
               h.setParent(obj);
               obj.Children = [obj.Children; h];
               obj.HasData = true;
               fprintf(1,'%s added block %s \t\t (%g sec)\n',...
                  obj.Name,h.Name,round(toc(tic_start)+2)); % add 2s for approx delay
            else
               fprintf(1,'%s is already a child of %s.\n',h.Name,obj.Name);
            end
         else
            fprintf(1,'Children of rat object must be of class ''block''.\n');
         end
      end
      
      % Callback to toggle Mask for a particular channel
      function toggleMaskForChannel(obj,src,~)
         if ~isa(src,'matlab.graphics.axis.Axes')
            src = src.Parent;
         end
         iCh = src.UserData;
         tf = false; % If no matches, then it must be false
         for ii = 1:numel(obj.Children)
            ch = matchChannel(obj.Children(ii),iCh);
            if isempty(ch)
               continue;
            end
            tf = setChannelMask(obj.Children(ii),ch);
         end
         obj.ChannelMask(iCh) = tf;
         if tf
            src.Color = 'w';
            src.XColor = 'k';
            src.YColor = 'k';
         else
            src.Color = 'k';
            src.XColor = 'w';
            src.YColor = 'w';               
         end
      end
      
   end
   
   methods (Static = true, Access = private)
      % Brings up the dialog box for selecting path to rat
      function path = uiPathDialog()
         path = uigetdir('P:\Extracted_Data_To_Move\Rat\TDTRat',...
            'Select RAT folder');
      end
      
      % Sets properties for a given axes for plotting rates
      function ax = createRateAxes(channelmask,channelinfo,ax,xLim,yLim)
         if nargin < 3
            ax = gca;
         end
         
         if nargin < 4
            xLim = defaults.rat('x_lim_norm');
         end
         
         if nargin < 5
            yLim = defaults.rat('y_lim_norm');
         end
         
         ax.NextPlot = 'add';
         ax.UserData = channelinfo;

         if channelmask
            ax.Color = 'w';
            ax.XColor = 'k';
            ax.YColor = 'k';
         else
            ax.Color = 'k';
            ax.XColor = 'w';
            ax.YColor = 'w';               
         end

         str = sprintf('%s-%s-%s',channelinfo.ml,...
            channelinfo.icms,...
            channelinfo.area);
         
         ax.Title.String = str;
         ax.Title.FontName = 'Arial';
         ax.Title.FontSize = 14;
         ax.Title.Color = 'k';
         
         ax.XLim = xLim;
         ax.YLim = yLim;
      end
   end
   
end

