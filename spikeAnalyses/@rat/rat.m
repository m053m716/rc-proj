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
            obj.ChannelMask = obj.Children(1).ChannelMask;
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
      function [Projection,Summary] = jPCA_suppress(obj,suppressed_area,active_area,align,outcome,doReProject)
         if nargin < 6
            doReProject = false;
         end
         
         if nargin < 5
            outcome = 'All';
         end
         
         if nargin < 4
            align = 'Grasp';
         end
         
         if numel(obj) > 1
            if nargout > 1
               Projection = cell(numel(obj),1);
               Summary = cell(numel(obj),1);
               for ii = 1:numel(obj)
                  [Projection{ii},Summary{ii}] = jPCA_suppress(obj(ii),suppressed_area,active_area,align,outcome,doReProject);
               end
            else
               for ii = 1:numel(obj)
                  jPCA_suppress(obj(ii),suppressed_area,active_area,align,outcome,doReProject);
               end
            end
            return;
         end
         
         if nargout > 1
            [Projection,Summary] = jPCA_suppress(obj.Children,suppressed_area,active_area,align,outcome,doReProject);
         else
            jPCA_suppress(obj.Children,suppressed_area,active_area,align,outcome,doReProject);
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
         
         cm = defaults.load_cm;
         idx = round(linspace(1,size(cm,1),numel(obj.Children)));
         
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
            
            filter_order = defaults.rat('lpf_order');
            fs = defaults.rat('fs');
            cutoff_freq = defaults.rat('lpf_fc');
            if ~isnan(cutoff_freq)
               [b,a] = butter(filter_order,cutoff_freq/(fs/2),'low');
            end
            
            % Superimpose FILTERED rate traces on the channel axes
            legText = [];
            for ii = 1:numel(obj.Children)
               ch = obj.Children(ii).matchChannel(iCh);
               if isempty(ch)
                  continue;
               end
               x = getAvgSpikeRate(obj.Children(ii),align,outcome);
               legText = [legText;...
                  {sprintf('D%02g',obj.Children(ii).PostOpDay)}];
               if ~isnan(cutoff_freq)
                  y = filtfilt(b,a,x);
               else
                  y = x;
               end
               plot(ax(iCh),...
                  obj.Children(ii).T*1e3,... % convert to ms
                  y,...                      % plot filtered trace
                  'Color',cm(idx(ii),:),...  % color by day
                  'LineWidth',2.25-(ii/numel(obj.Children)),...
                  'UserData',[iCh,ii]);
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
            legend(ax(iCh),legText,'Location','NorthWest');
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
      function path = uiPathDialog()
         path = uigetdir('P:\Extracted_Data_To_Move\Rat\TDTRat',...
            'Select RAT folder');
      end
   end
   
end

