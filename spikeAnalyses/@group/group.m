classdef group < handle
   %GROUP organizes all data for an experimental group in RC project
   
   properties (GetAccess = public, SetAccess = private)
      Name        % Name of this experimental group
      Children    % Child rat objects belonging to this GROUP
      Data        % Struct to hold GROUP-level data
   end
   
   properties (GetAccess = public, SetAccess = private, Hidden = true)
      HasData = false;  % Do any of the rats have data associated?
      
      % Flags for concatenated stats tables
      HasTrialStats = false;
      HasChannelStats = false;
      HasRatStats = false;
      HasSessionStats = false;
   end
   
   properties (Access = public, Hidden = true)
      pct
      p
   end
   
   methods (Access = public)
      % Group object constructor
      function obj = group(name,ratArray)
         obj.Name = name;
         for ii = 1:numel(ratArray)
            if ratArray(ii).HasData
               ratArray(ii).setParent(obj);
               obj.Children = [obj.Children; ratArray(ii)];
               obj.HasData = true;
            end
         end
%          obj.unifyjPCA(defaults.jPCA('jpca_align'));
      end
      
      % Redistribute the combined PCA results to child Rat objects
      function assignBasisData(obj,coeff,score,x,pc_idx,p,channelInfo)
         name = {channelInfo.file}.';
         ratName = cellfun(@(x)x(1:5),name,'UniformOutput',false);
         for ii = 1:numel(obj.Children)
            idx = ismember(ratName,obj.Children(ii).Name);
            assignBasisData(obj.Children(ii),coeff,score(idx,:),x(idx,:),pc_idx,p,channelInfo(idx));
         end
      end
      
      % Table of data describing divergence between unsuccessful and
      % successful trials in phase space, for each recording. Created by
      % EXPORTDIVERGENCESTATS
      function assignDivergenceData(obj,T)
         % Parse array
         if numel(obj) > 1
            for ii = 1:numel(obj)
               Tsub = T(ismember(T.Group,obj(ii).Name),:);
               assignDivergenceData(obj(ii),Tsub);
            end
            return;
         end
         
         assignDivergenceData(obj.Children,T);
      end
      
      % Export statistics (as a spreadsheet) for individual channels.  Each
      % row of output spreadsheet (name in defaults.group) corresponds to
      % statistics for a single recording channel, for a single recording
      % session. Only exports spreadsheet if no output argument is 
      % specified.
      function T = exportChannelStats(obj)
         if numel(obj) > 1
            T = [];
            for ii = 1:numel(obj)
               obj(ii).Data.ChannelStats = exportChannelStats(obj(ii));
               obj(ii).HasChannelStats = true;
               T = [T; obj(ii).Data.ChannelStats];
            end
            if nargout < 1
               fname = defaults.group('channel_export_spreadsheet');
               writetable(T,fname);
            end
            return;
         end
      end
      
      % Export down-sampled rate data for dPCA. If no output argument is
      % specified, then files are saved in the default location from
      % defaults.dPCA. In this version, days are stimuli and successful or
      % unsuccessful outcome is the decision.
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
         
         if nargout < 1
            export_dPCA_days_are_stimuli(obj.Children);
         else
            [X,t,trialNum] = export_dPCA_days_are_stimuli(obj.Children);
         end
      end
      
      % Export down-sampled rate data for dPCA. If no output argument is
      % specified, then files are saved in the default location from
      % defaults.dPCA. In this version, pellet presence or absence is the
      % stimulus and the decision is to complete or continue a second
      % reach.
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
         
         if nargout < 1
            export_dPCA_pellet_present_absent(obj.Children);
         else
            [X,t,trialNum] = export_dPCA_pellet_present_absent(obj.Children);
         end
      end
      
      % Export statistics (as a spreadsheet) for individual trials. Each
      % row of output spreadsheet (name in defaults.group) corresponds to
      % statistics for a single reaching trial. Only exports spreadsheet
      % if no output argument is specified.
      function T = exportTrialStats(obj)
         if numel(obj) > 1
            T = [];
            for ii = 1:numel(obj)
               T = [T; exportTrialStats(obj(ii))];
               obj(ii).HasTrialStats = true;
            end
            if nargout < 1
               fname = defaults.group('trial_export_spreadsheet');
               writetable(T,fname);
            end
            return;
         end
         
         T = exportTrialStats(obj.Children);
         
         % Extend variable descriptors to an additional metadata field
         ud = T.Properties.UserData;
         vd = T.Properties.VariableDescriptions;
         Group = repmat(categorical({obj.Name}),size(T,1),1);
         
         T = [table(Group), T];
         T.Properties.Description = 'Concatenated Trial Metadata';
         T.Properties.UserData = [nan(1,1), ud];
         T.Properties.VariableDescriptions = ['experimental group', vd];
         obj.Data.TrialStats = T;
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
         
         exportUnifiedjPCA_movie(obj.Children,align,area);
      end
      
      % Return property as an array for all electrodes of child rats
      function T = getChannelProp(obj,propName,align,outcome,area)
         Rat = [];
         Group = [];
         Name = [];
         Score = [];
         PostOpDay = [];
         out = [];
         for ii = 1:numel(obj)
            for ij = 1:numel(obj(ii).Children)
               if nargin < 5
                  [tmp_out,tmp_rat] = getChannelProp(obj(ii).Children(ij),propName);
               else
                  [tmp_out,tmp_rat,tmp_Day,tmp_Score,tmp_Name] = getChannelProp(obj(ii).Children(ij),propName,align,outcome,area);
               end
               if isempty(tmp_out) && ~isempty(propName)
                  fprintf(1,'Invalid property: %s\n',propName);
                  T = [];
                  return;
               end
               Rat = [Rat; tmp_rat];
               if ~isempty(propName)
                  out = [out; tmp_out];
               end
               if nargin == 5
                  Name = [Name; tmp_Name];
                  PostOpDay = [PostOpDay; tmp_Day];
                  Score = [Score; tmp_Score];
                  Group = [Group;repmat({obj(ii).Name},numel(tmp_rat),1)];
               end
            end
         end
         if ~isempty(propName)
            T = table(Rat,Name,Group,PostOpDay,Score,out);
            T.Properties.VariableNames{end} = propName;
         else % With no property, just get "standard header"
            T = table(Rat,Name,Group,PostOpDay,Score);
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
      
      % Returns table with Data variable containing jPCA Projection and
      % Summmary fields
      function J = getjPCA(obj,align,outcome,area)
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
            J = [];
            for ii = 1:numel(obj)
               J = [J; getjPCA(obj(ii),align,outcome,area)];
            end
            return;
         end
         
         J = [];
         THRESH = defaults.group('w_avg_dp_thresh');
         field_expr = sprintf('Data.%s.%s.jPCA.%s',align,outcome,area);
         for ii = 1:numel(obj.Children)
            ratObj = obj.Children(ii);
            for ik = 1:numel(ratObj.Children)
               blockObj = ratObj.Children(ik);
               Rat = {ratObj.Name};
               Name = {blockObj.Name};
               Group = {obj.Name};
               PostOpDay = blockObj.PostOpDay;
               Score = blockObj.(defaults.group('output_score'));
               Align = {align};
               ChannelInfo = {blockObj.ChannelInfo(blockObj.ChannelMask)};
               [Projection,Summary] = getjPCA(blockObj,field_expr);
               if isempty(Projection)
                  continue;
               end
               phaseData = jPCA.getPhase(Projection,Summary.sortIndices(1),Summary.outcomes);
               idx = abs([phaseData.wAvgDPWithPiOver2]) > THRESH;
               nAttempts = numel(phaseData);
               outcomes = [phaseData.label].';
               outcomes = outcomes(idx);
               Projection = Projection(idx);
               Summary.outcomes = outcomes;
               Data.Projection = Projection;
               Data.Summary = Summary;
               J = [J; table(Rat,Name,Group,PostOpDay,Score,nAttempts,Align,ChannelInfo,Data)];
            end
         end
      end
      
      % Return phase data for jPCA analyses
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
               phaseData = [phaseData; getPhase(obj(ii),align,outcome,area)];
            end
            return;
         end

         fprintf(1,'\n%s group:\n',obj.Name);
         phaseData = getPhase(obj.Children,align,outcome,area);
      end
      
      % Return some property as an array for all child objects
      function T = getProp(obj,propName)
         T = [];
         for ii = 1:numel(obj)
            Name = getBlockNames(obj(ii)); %#ok<*PROPLC>
            Rat = cellfun(@(x)x(1:5),Name,'UniformOutput',false);
            out = getProp(obj(ii).Children,propName);
            if isempty(out)
               fprintf(1,'Invalid property: %s\n',propName);
               T = [];
               return;
            end
            PostOpDay = getProp(obj(ii).Children,'PostOpDay'); 
            output_score = defaults.group('output_score');
            Score = getProp(obj(ii).Children,output_score);
            Group = repmat({obj(ii).Name},numel(PostOpDay),1);
            ChannelInfo = [];
            for ik = 1:numel(obj(ii).Children)
               for ij = 1:numel(obj(ii).Children(ik).Children)
                  ChannelInfo = [ChannelInfo; ...
                     {obj(ii).Children(ik).Children(ij).ChannelInfo(...
                      obj(ii).Children(ik).Children(ij).ChannelMask)}];
               end
            end
            
            T_tmp = table(Rat,Name,Group,PostOpDay,Score,ChannelInfo,out);
            T_tmp.Properties.VariableNames{end} = propName;
            T = [T; T_tmp];
         end
      end
      
      % Shortcut for jPCA runFun
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
      
      % Shortcut for jPCA_project runFun
      function jPCA_All(obj,align,area)
         if nargin < 2
            align = defaults.jPCA('jpca_align');
         end
         
         if nargin < 3
            area = 'Full';
         end
         
         if numel(obj) > 1
            for ii = 1:numel(obj)
               jPCA_All(obj(ii),align,area);
            end
            return;
         end
         
         for ii = 1:numel(obj.Children)
            for ik = 1:numel(obj.Children(ii).Children)
               if isfield(obj.Children(ii).Children(ik).Data.(align).Successful,'jPCA')
                  if isfield(obj.Children(ii).Children(ik).Data.(align).Successful.jPCA,area)
                     fprintf(1,'-->\t%s: projecting all trials\n',obj.Children(ii).Children(ik).Name);
                     jPCA_project(obj.Children(ii).Children(ik),align,[],nan,area);
                  else
                     fprintf(1,'\t-->\t%s: missing successful jPCA for AREA (%s)\n',obj.Children(ii).Children(ik).Name,area);   
                  end                  
               else
                  fprintf(1,'\t-->\t%s: missing successful jPCA\n',obj.Children(ii).Children(ik).Name);                  
               end
            end
         end
         
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
      
      % Load channel mask for child rat objects
      function loadChannelMask(obj)
         if numel(obj) > 1
            for ii = 1:numel(obj)
               loadChannelMask(obj(ii));
            end
            return;
         end
         
         loadChannelMask(obj.Children);
      end
      
      % Concatenate all rate and do decomposition on it
      function [x,coeff,score,latent,channelInfo,pc_idx] = pca(obj,doPlots)
         if nargin < 2
            doPlots = false;
         end
         
         decimation_factor = defaults.group('decimation_factor');
         
         tic;
         fprintf(1,'Gathering average rates...');
         [avgRate,channelInfo] = getAvgSpikeRate(obj.Children);
         fprintf(1,'complete.\n');
         
         fprintf(1,'Doing decimation...');
         x = nan(size(avgRate,1),round(size(avgRate,2)/decimation_factor));
         for ii = 1:size(avgRate,1)
            x(ii,:) = decimate(avgRate(ii,:),decimation_factor);
         end
         fprintf(1,'complete.\n');
         
         fprintf(1,'Doing PCA...');
         [coeff,score,latent] = pca(x,...
            'Rows','all');
         fprintf(1,'complete.\n');
         toc;
         
         p = cumsum(latent)/sum(latent)*100;
         min_pca_var = defaults.group('min_pca_var');
         pc_idx = find(p>=min_pca_var,1,'first');
         
         obj.pct = latent/sum(latent)*100;
         obj.p = p;
         
         if (doPlots) || (nargout < 1)
            figure('Name',sprintf('Group: %s - PCA',obj.Name),...
               'Units','Normalized',...
               'Position',[0.3 0.3 0.4 0.4],...
               'Color','w');
            
            subplot(2,1,1);
            
            c = get(gca,'ColorOrder');
            for ii = 1:pc_idx
               stem(gca,ii,p(ii),...
                  'Color',c(ii,:),...
                  'LineWidth',2,...
                  'MarkerFaceColor',c(ii,:));
               hold on;
            end
            stem(gca,(pc_idx+1):numel(p),p((pc_idx+1):end),...
               'Color',[0.8 0.8 0.8],'LineWidth',1.5);
            xlabel('PC #',...
               'FontName','Arial','FontSize',14,'Color','k');
            ylabel('Cumulative %',...
               'FontName','Arial','FontSize',14,'Color','k');
            title('% Data Explained',...
               'FontName','Arial','FontSize',16,'Color','k');
            
            line([0 numel(p)+1],[min_pca_var min_pca_var],...
               'Color','k','LineWidth',2,'LineStyle','--');
            xlim([0.5 pc_idx+round(0.5*pc_idx)+1.5]);   
            ylim([p(1)-5 103]);
            
            subplot(2,1,2);
            t = defaults.experiment('t');
            t = decimate(t,decimation_factor);
            plot(t,coeff(:,1:pc_idx),'LineWidth',2);
            xlabel('Time (sec)',...
               'FontName','Arial','FontSize',14,'Color','k');
            ylabel('PC Amplitude (a.u.)',...
               'FontName','Arial','FontSize',14,'Color','k');
            title(sprintf('Top %g PCs (>=%g%% explained)',pc_idx,min_pca_var),...
               'FontName','Arial','FontSize',16,'Color','k');
         end
      end
      
      % Plot average rate profiles across days by group
      function fig = plotRateAverages(obj,align,outcome)
         if nargin < 2
            align = defaults.block('all_events');
         end
         
         if nargin < 3
            outcome = defaults.block('outcome');
         end
         
         if numel(obj) > 1
            if nargout > 0
               fig = [];
               for ii = 1:numel(obj)
                  fig = [fig; plotRateAverages(obj(ii),align,outcome)];
               end
               return;
            else
               for ii = 1:numel(obj)
                  plotRateAverages(obj(ii),align,outcome);
               end
               return;
            end
         end
         
         if iscell(align)
            if nargout > 0
               fig = [];
               for ik = 1:numel(align)
                  fig = [fig; plotRateAverages(obj.Children,align{ik},outcome)];
               end
               return;
            else
               for ik = 1:numel(align)
                  plotRateAverages(obj.Children,align{ik},outcome)
               end
               return;
            end
            
         else
            if nargout > 0
               fig = plotRateAverages(obj.Children,align,outcome);
            else
               plotRateAverages(obj.Children,align,outcome);
            end
            return;
         end
      end
      
      % Plot average rate profiles across days by group
      function fig = plotNormAverages(obj,align,outcome)
         if nargin < 2
            align = defaults.block('all_events');
         end
         
         if nargin < 3
            outcome = defaults.block('outcome');
         end
         
         if numel(obj) > 1
            if nargout > 0
               fig = [];
               for ii = 1:numel(obj)
                  fig = [fig; plotNormAverages(obj(ii),align,outcome)];
               end
               return;
            else
               for ii = 1:numel(obj)
                  plotNormAverages(obj(ii),align,outcome);
               end
               return;
            end
         end
         
         if iscell(align)
            if nargout > 0
               fig = [];
               for ik = 1:numel(align)
                  fig = [fig; plotNormAverages(obj.Children,align{ik},outcome)];
               end
               return;
            else
               for ik = 1:numel(align)
                  plotNormAverages(obj.Children,align{ik},outcome)
               end
               return;
            end
            
         else
            if nargout > 0
               fig = plotNormAverages(obj.Children,align,outcome);
            else
               plotNormAverages(obj.Children,align,outcome);
            end
            return;
         end
      end
      
      % Plot behavioral performance by day
      function fig = plotBehavior(obj,scoreType,fig)
         if nargin < 2
            scoreType = defaults.group('output_score');
         end
         
         if nargin < 3
            fig = figure('Name','Daily Behavioral Performance',...
               'Units','Normalized',...
               'Color','w',...
               'Position',[0.25+0.05*randn(1) 0.25+0.05*randn(1) 0.55 0.45]);
         end
         
         if ~ismember(scoreType,{'TrueScore','NeurophysScore','BehaviorScore'})
            error('scoreType must be: ''TrueScore'', ''NeurophysScore'', or ''BehaviorScore''');
         end         
         
         legText = [];
         rat_marker = defaults.group('rat_marker');
         rat_color = defaults.group('rat_color');
         for iG = 1:numel(obj)
            poDay = cell(numel(obj(iG).Children),1);
            score = cell(numel(obj(iG).Children),1);
            smoothedData = cell(numel(obj(iG).Children),1);
            allDays = cell(numel(obj(iG).Children),1);
            for ii = 1:numel(obj(iG).Children)
               poDay{ii} = obj(iG).Children(ii).getProp('PostOpDay');
               score{ii} = obj(iG).Children(ii).getProp(scoreType);

               [smoothedData{ii},allDays{ii}] = smoothFitDays(score{ii},poDay{ii});
               subplot(3,6,ii+(6 * iG));
               stem(poDay{ii},score{ii}*100,...
                  'Color','k','LineWidth',1.5,'Marker',rat_marker{ii});
               hold on;
               plot(allDays{ii},smoothedData{ii}*100,...
                  'Color',rat_color.(obj(iG).Name)(ii,:),'LineWidth',2);
               set(gca,'XColor','k');
               set(gca,'YColor','k');
               set(gca,'FontName','Arial');
               set(gca,'LineWidth',1);
               xlabel('Post-Op Day','FontName','Arial','Color','k','FontSize',12);
               ylabel('% Successful','FontName','Arial','Color','k','FontSize',12);
               title(obj(iG).Children(ii).Name,'FontName','Arial','Color','k','FontSize',14);
               ylim([0 100]);
               xlim([0 30]);
               
               % Associate the smoothed "AllDaysScore" with each block
               tmp_score = smoothedData{ii}(ismember(allDays{ii},poDay{ii}));
               obj(iG).Children(ii).setAllDaysScore(tmp_score);
            end

            plotDayVec = 4:28;
            groupScore = nan(size(plotDayVec));
            groupStd = nan(size(plotDayVec));
            for ik = 1:numel(plotDayVec)
               tmp = [];
               for ii = 1:numel(obj(iG).Children)
                  if ismember(plotDayVec(ik),allDays{ii})
                     tmp = [tmp; smoothedData{ii}(allDays{ii}==plotDayVec(ik))];
                  end
               end
               if ~isempty(tmp)
                  groupScore(ik) = mean(tmp);
                  groupStd(ik) = std(tmp);
               end
            end
            
            subplot(3,6,1:6);
            hold on;
            errorbar(plotDayVec,groupScore*100,groupStd*100,...
               'Color',mean(rat_color.(obj(iG).Name),1),'LineWidth',3);
            set(gca,'XColor','k');
            set(gca,'YColor','k');
            set(gca,'FontName','Arial');
            set(gca,'LineWidth',1);
            xlabel('Post-Op Day','FontName','Arial','Color','k','FontSize',12);
            ylabel('% Successful','FontName','Arial','Color','k','FontSize',12);
            title('Group Mean Score','FontName','Arial','Color','k','FontSize',14);
            ylim([0 100]);
            legText = [legText; {obj(iG).Name}];
            legend(legText,'Location','NorthWest');
         end
      end
      
      % Make scatter plots accounting for channel type etc
      function fig = plotScatter(obj,pc_indices)
         % Parse input
         if nargin < 2
            pc_indices = 1:3;
         end
         
         % Handle multiple input objects
         if numel(obj) > 1
            if nargout < 1
               for ii = 1:numel(obj)
                  plotScatter(obj(ii),pc_indices);
               end
            else
               fig = [];
               for ii = 1:numel(obj)
                  fig = [fig; plotScatter(obj(ii),pc_indices)];
               end
            end
            return;
         end
         
         fig = figure('Name',sprintf('%s: ICMS-Scatter',obj.Name),...
            'Units','Normalized',...
            'Color','w',...
            'Position',[0.2 0.2 0.6 0.6]);
         icms_opts = defaults.group('icms_opts');
         nCol = numel(icms_opts)+1;
         area_opts = defaults.group('area_opts');
         nRow = numel(area_opts);
         rat_marker = defaults.group('rat_marker');
         rat_color = defaults.group('rat_color');
         col = rat_color.(obj.Name);
         for iPlot = 1:(nRow * nCol)
            subplot(nRow,nCol,iPlot);
            icms_idx = rem(iPlot-1,nCol)+1;
            area_idx = ceil(iPlot/nCol);
            for ii = 1:numel(obj.Children)
               for ik = 1:numel(obj.Children(ii).Children)
                  b = obj.Children(ii).Children(ik); % block
                  x = b.score(:,pc_indices(1));
                  y = b.score(:,pc_indices(2));
                  z = b.score(:,pc_indices(3));
                  chInf = b.ChannelInfo(b.score_ch_idx);
                  
                  site_icms = {chInf.icms}.';
                  site_area = {chInf.area}.';
                  
                  
                  if icms_idx > numel(icms_opts)
                     idx = (~contains(site_icms,icms_opts{1})) & ...
                           (~contains(site_icms,icms_opts{2})) & ...
                     	   (contains(site_area,area_opts{area_idx}));
                  else
                     idx = (contains(site_icms,icms_opts{icms_idx})) & ...
                        (contains(site_area,area_opts{area_idx}));
                  end
                  
                  
                  
                  mrk_idx = rem(ii-1,numel(rat_marker))+1;
                  scatter3(x(idx),y(idx),z(idx),30,'filled','k',...
                     'MarkerFaceColor',col(ii,:),...
                     'MarkerEdgeColor',col(ii,:),...
                     'Marker',rat_marker{mrk_idx},...
                     'MarkerFaceAlpha',0.5,'MarkerEdgeAlpha',0.75);
                  hold on;
               end
            end
            if icms_idx > numel(icms_opts)
               t_str = sprintf('%s-Other',area_opts{area_idx});
            else
               t_str = sprintf('%s-%s',area_opts{area_idx},icms_opts{icms_idx});
            end
            xlabel(sprintf('PC-%g',pc_indices(1)),...
               'FontName','Arial','FontSize',14,'Color','k');
            ylabel(sprintf('PC-%g',pc_indices(2)),...
               'FontName','Arial','FontSize',14,'Color','k');
            zlabel(sprintf('PC-%g',pc_indices(3)),...
               'FontName','Arial','FontSize',14,'Color','k');
            title(t_str,'FontName','Arial','FontSize',16,'Color','k');
            xlim([-75 75]);
            ylim([-50 50]);
            zlim([-25 25]);
         end
         pct_explained = sum(obj.pct(pc_indices));
         t_str = sprintf('%s: PCs explain %2.4g%% var',obj.Name,pct_explained);
         suptitle(t_str);
         
         % Save and delete if no output prompted
         if nargout < 1
            out_dir = defaults.group('somatotopy_pca_behavior_fig_dir');
            out_dir = fullfile(pwd,out_dir);
            if exist(out_dir,'dir')==0
               mkdir(out_dir);
            end
            savefig(fig,fullfile(out_dir,...
               sprintf('%s_ICMS-Scatter_PC-%g-%g-%g.fig',obj.Name,...
               pc_indices(1),pc_indices(2),pc_indices(3))));
            saveas(fig,fullfile(out_dir,...
               sprintf('%s_ICMS-Scatter_PC-%g-%g-%g.png',obj.Name,...
               pc_indices(1),pc_indices(2),pc_indices(3))));
            delete(fig);
         end
      end
      
      % Run function on children Rat objects
      function runFun(obj,f)
         % Parse function handle input
         if isa(f,'function_handle')
            f = char(f); 
         end
         
         % Handle array input
         if numel(obj) > 1
            for ii = 1:numel(obj)
               runFun(obj(ii),f);
            end
            return;
         end
         
         for ii = 1:numel(obj.Children)
            if ismethod(obj.Children(ii),f)
               obj.Children(ii).(f);
            else
               obj.Children(ii).runFun(f);
            end
         end
      end
      
      % Run dPCA analysis for all children Rat objects
      function out = run_dPCA_days_are_stimuli(obj)
         if numel(obj) > 1
            out = struct;
            maintic = tic;
            for ii = 1:numel(obj)
               out.(obj(ii).Name) = obj(ii).run_dPCA_days_are_stimuli;
            end
            toc(maintic);
            return;
         end
         out = run_dPCA_days_are_stimuli(obj.Children);
      end
      
      % Break into subgroups
      function subGroupArray = splitSubGroups(obj,groupNameArray,groupIndices)
         if nargin < 2
            groupNameArray = inputdlg(repmat({'Group Names:'},4,1),...
               'Set Group Name(s)',1,...
               {'Ischemia';'Intact';'';''});
            groupNameArray = groupNameArray(~cellfun(@isempty,groupNameArray));
            if isempty(groupNameArray)
               subGroupArray = [];
               return;
            end
         end
         if nargin < 3
            groupIndices = cell(size(groupNameArray));
            str = getRatNames(obj);
            indices = 1:numel(str);
            for ii = 1:numel(groupIndices)
               [idx,clickedOK] = listdlg('PromptString',...
                   sprintf('Select group %g (%s)',ii,groupNameArray{ii}),...
                   'SelectionMode','multiple',...
                   'ListString',str);
               if clickedOK==0
                  disp('Subgroup creation canceled.');
                  subGroupArray = [];
                  return;
               end
               str(idx) = [];
               groupIndices{ii} = indices(idx);
               indices(idx) = [];
            end
         end
         
         subGroupArray = [];
         for ii = 1:numel(groupIndices)
            subGroupArray = [subGroupArray; group(groupNameArray{ii},...
               obj.Children(groupIndices{ii}))];
            subGroupArray(ii).p = obj.p;
            subGroupArray(ii).pct = obj.pct;
         end
         
      end
      
      % Recover jPCA weights for channels using trials from all days
      function unifyjPCA(obj,align,area)
         % Parse alignment
         if nargin < 2
            align = defaults.jPCA('jpca_align');
         end
         
         % Parse area for unification ('Full', 'RFA', or 'CFA')
         if nargin < 3
            area = 'Full'; % default
         end
            
         % Parse array
         if numel(obj) > 1
            for ii = 1:numel(obj)
               unifyjPCA(obj(ii),align,area);
            end
            return;
         end
         unifyjPCA(obj.Children,align,area);
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
         
         % Update all ratObj Children
         updateFolder(obj.Children,newFolder);
      end
      
      % Update all child rate data
      function updateSpikeRateData(obj,align,outcome)
         if nargin < 3
            outcome = 'All';
         end
         
         if nargin < 2
            align = defaults.jPCA('jpca_align');
         end
         
         if numel(obj) > 1
            for ii = 1:numel(obj)
               updateSpikeRateData(obj(ii),align,outcome);
            end
            return;
         end
         
         for ii = 1:numel(obj.Children)
            updateSpikeRateData(obj.Children(ii).Children,align,outcome);
         end
      end
   end
   
   methods (Access = private)
      % Return all RAT names contained in this GROUP
      function nameArray = getRatNames(obj)
         nameArray = cell(size(obj.Children));
         for ii = 1:numel(nameArray)
            nameArray{ii} = obj.Children(ii).Name;
         end
      end
      
      % Return all BLOCK names contained in this GROUP
      function nameArray = getBlockNames(obj)
         nameArray = [];
         for ii = 1:numel(obj.Children)
            nameArray = [nameArray; getBlockNames(obj.Children(ii))]; %#ok<*AGROW>
         end
      end
   end
   
end

