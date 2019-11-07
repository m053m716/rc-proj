classdef group < handle
   %GROUP organizes all data for an experimental group in RC project
   
   properties (GetAccess = public, SetAccess = private)
      Name        % Name of this experimental group
      Children    % Child rat objects belonging to this GROUP
      Data        % Struct to hold GROUP-level data
      xPC         % Struct to hold xPCA-related data
      ChannelInfo % Aggregate (masked) channel info
      RecentAlignment   % Most-recent alignment run by a method
      RecentIncludes    % Most-recent "includeStruct" run by a method
   end
   
   properties (GetAccess = public, SetAccess = public)
      CR                % Table of Channel Response correlations
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
   
   % Class constructor and main data-handling methods
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
         
         % Set the channel masks to be consistent across days
         runFun(gData,'unifyChildChannelMask');
         
         % Update the object's channel info for all channels of all child
         % rat objects (that are not masked)
         getChannelInfo(gData,true);
      end
      
      % Redistribute the combined PCA results to child Rat objects 
      % -- deprecated --
      function assignBasisData(obj,coeff,score,mu)
         if numel(obj) > 1
            for ii = 1:numel(obj)
               assignBasisData(obj(ii),coeff,score,mu);
            end
            return;
         end
         ratName = cellstr(vertcat(obj.ChannelInfo.Name));
         for ii = 1:numel(obj.Children)
            idx = ismember(ratName,obj.Children(ii).Name);
            assignBasisData(obj.Children(ii),...
               coeff(idx,:),score(idx,:),mu(idx),...
               obj.ChannelInfo(idx));
         end
      end
      
      % Table of data describing divergence between unsuccessful and
      % successful trials in phase space, for each recording. Created by
      % EXPORTDIVERGENCESTATS 
      % -- deprecated --
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
      
      % Puts a rat skull plot object on current axes
      function [ratSkullObj,ax] = buildRatSkullPlot(obj,ax)
         if nargin < 2
            ax = gca;
         end
         ratSkullObj = ratskull_plot(ax);
         obj.scatterInjectionSites(ratSkullObj);
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
      
      
      % Export "ratskull_plot" type movies to show evolution of a
      % particular rat's spatially-distributed response (for some
      % parameter) against days
      function exportSkullPlotMovie(obj,f)
         if nargin < 2
            f = [];
         end
         if numel(obj) > 1
            for ii = 1:numel(obj)
               obj(ii).exportSkullPlotMovie(f);
            end
            return;
         end
         
         exportSkullPlotMovie(obj.Children,f);
      end
      
      % Export "unified" jPCA trial projections from all days 
      % -- deprecated --
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
      
      % Shortcut for jPCA runFun 
      % -- deprecated --
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
      % -- deprecated --
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
      % -- deprecated --
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
      
      % Parse the mediolateral and anteroposterior coordinates from bregma
      % for a given set of electrodes (returned in millimeters)
      function parseElectrodeCoordinates(obj,area)
         if nargin < 2
            area = 'Full';
         end
         if numel(obj) > 1
            for ii = 1:numel(obj)
               obj(ii).parseElectrodeCoordinates(area);
            end
            return;
         end
         
         parseElectrodeCoordinates(obj.Children,area);
      end
      
      % Concatenate all rate and do decomposition on it 
      % -- deprecated --
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
      % -- deprecated --
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
      
      % Shortcut to save with the appropriate filename
      function ticTimes = saveGroupData(obj,ticTimes)
         if nargin < 2
            ticTimes = struct;
         end
         if numel(obj) > 1
            fprintf(1,'Saving GROUP class object array...');
         else
            fprintf(1,'Saving GROUP class object...');
         end
         saveTic = tic;
         gData = obj; % To keep name consistent with outside variable name
         save(defaults.experiment('group_data_name'),'gData','-v7.3');
         ticTimes.save = round(toc(saveTic));
         fprintf(1,'complete (%g sec elapsed)\n\n\n',ticTimes.save);
         if nargout < 1
            ticTimes = [];
         end
      end
      
      % Add ET-1 (or sham) injection sites to ratSkullObj object
      function scatterInjectionSites(obj,ratSkullObj)
         if strcmpi(obj.Name,'Ischemia')
            scatter(ratSkullObj,defaults.group('skull_et1_x'),...
               defaults.group('skull_et1_y'),'ET-1',...
               'MarkerSize',60,...
               'MarkerFaceColor','k');
         else
            scatter(ratSkullObj,defaults.group('skull_et1_x'),...
               defaults.group('skull_et1_y'),'ET-1',...
               'MarkerSize',60,...
               'MarkerFaceColor','none',...
               'MarkerEdgeColor','k');
         end
      end
      
      % Set the most-recent include and alignment
      function setAlignInclude(obj,align,includeStruct)
         if nargin < 2
            align = defaults.group('align');
         end
         
         if nargin < 3
            includeStruct = defaults.group('include');
         end
         
         if numel(obj) > 1
            for ii = 1:numel(obj)
               obj(ii).setAlignInclude(align,includeStruct);
            end
            return;
         end
         
         obj.RecentAlignment = align;
         obj.RecentIncludes = includeStruct;
      end
      
      % Set cross-condition means for block objects of child rat objects
      function setCrossCondMean(obj,align,outcome,pellet,reach,grasp,support,complete,forceReset)
      
         if nargin < 8
            [align,outcome,pellet,reach,grasp,support,complete] = utils.getCrossCondKeyCombos();
            forceReset = true; % By default, reset if no arguments specified
         else
            if ~iscell(align)
               align = {align};
            end
            if ~iscell(outcome)
               outcome = {outcome};
            end
            if ~iscell(pellet)
               pellet = {pellet};
            end
            if ~iscell(reach)
               reach = {reach};
            end
            if ~iscell(grasp)
               grasp = {grasp};
            end
            if ~iscell(support)
               support = {support};
            end
            if ~iscell(complete)
               complete = {complete};
            end
            if nargin < 9
               forceReset = false;  % By default do not reset if all arguments are already specified
            end
         end
         
         if numel(obj) > 1
            for ii = 1:numel(obj)
               setCrossCondMean(obj(ii),align,outcome,pellet,reach,grasp,support,complete,forceReset);
            end
            return;
         end
         
         setCrossCondMean(obj.Children,align,outcome,pellet,reach,grasp,support,complete,forceReset);
         
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
      
      % Set xPC object
      function setxPCs(obj,xPC)
         if numel(obj) > 1
            for ii = 1:numel(obj)
               setxPCs(obj(ii),xPC);
            end
            return;
         end
         setxPCs(obj.Children,xPC);
      end
      
      % Recover jPCA weights for channels using trials from all days 
      % -- deprecated --
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
      
      % Returns the INTACT group from an array of GROUP objects
      function [obj_out,idx] = Intact(obj)
         obj_out = [];
         for idx = 1:numel(obj)
            if strcmpi(obj(idx).Name,'Intact')
               obj_out = obj(idx);
               return;
            end
         end
         % Otherwise, didn't find it
         idx = [];
         fprintf(1,'No Intact group contained in array (%g GROUP objects passed).\n',numel(obj));
      end
      
      % Returns the ISCHEMIA group from an array of GROUP objects
      function [obj_out,idx] = Ischemia(obj)
         obj_out = [];
         for idx = 1:numel(obj)
            if strcmpi(obj(idx).Name,'Ischemia')
               obj_out = obj(idx);
               return;
            end
         end
         % Otherwise, didn't find it
         idx = [];
         fprintf(1,'No Ischemia group contained in array (%g GROUP objects passed).\n',numel(obj));
      end
   end
   
   % Methods for retrieving data from child objects
   methods (Access = public)
      % Return all BLOCK names contained in this GROUP
      function nameArray = getBlockNames(obj)
         if numel(obj) > 1
            nameArray = cell(numel(obj),1);
            for ii = 1:numel(obj)
               nameArray{ii} = obj(ii).getBlockNames;
            end
            return;
         end
         
         % Flag true: fromChild
         nameArray = getProp(obj.Children,'Name',true);
      end
      
      % Get/update the ChannelInfo property using the masking and 
      % channelInfo of child RAT objects. If doUpdate is not specified,
      % retrieves channelInfo from current GROUP object property.
      function channelInfo = getChannelInfo(obj,doUpdate)
         if nargin < 2
            if nargout < 1 % If no output requested, then update prop
               doUpdate = true;
            else
               doUpdate = false;
            end
         end
         
         if numel(obj) > 1
            channelInfo = [];
            for ii = 1:numel(obj)
               channelInfo = [channelInfo; ...
                  obj(ii).getChannelInfo(doUpdate)]; %#ok<*AGROW>
            end
            return;
         end
         
         if doUpdate
            % Flags: doUpdate (false); useMask (true)
            channelInfo = getChannelInfo(obj.Children,false,true);
            obj.ChannelInfo = channelInfo;
         else
            channelInfo = obj.ChannelInfo;
         end       
         Group = obj.Name;
         channelInfo = utils.addStructField(channelInfo,Group);
         channelInfo = orderfields(channelInfo,[7,1:6]);
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
      
      % Get the individual channel correlations, for each day
      function [r,err_r,c,err_c,n] = getChannelResponseCorrelationsByDay(obj,align,includeStruct)
         if nargin < 2
            align = defaults.group('align');
         end
         
         if nargin < 3
            includeStruct = defaults.group('include');
         end
         
         if numel(obj) > 1
            r = cell(numel(obj),1);
            c = cell(numel(obj),1);
            err_c = cell(numel(obj),1);
            err_r = cell(numel(obj),1);
            n = cell(numel(obj),1);
            for ii = 1:numel(obj)
               [r{ii},err_r{ii},c{ii},err_c{ii},n{ii}] = getChannelResponseCorrelationsByDay(obj(ii),align,includeStruct);
            end
            return;
         end
         obj.setAlignInclude(align,includeStruct);
         obj.CR = []; % Clear previous table
         [r,err_r,c,err_c,n] = getChannelResponseCorrelationsByDay(obj.Children,align,includeStruct);
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
      % -- deprecated --
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
      % -- deprecated --
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
      
      % Return all RAT names contained in this GROUP
      function nameArray = getRatNames(obj)
         if numel(obj) > 1
            nameArray = cell(numel(obj),1);
            for ii = 1:numel(obj)
               nameArray{ii} = obj(ii).getRatNames;
            end
            return;
         end
         
         % Flag false: fromChild
         nameArray = getProp(obj.Children,'Name',false);
      end
      
      % Get or Set struct fields based on includeStruct format
      function [rate,t] = getSetIncludeStruct(obj,align,includeStruct,rate,t)
         if (nargout > 0) && (nargin > 3)
            error('Number of inputs suggests a SET call, but number of outputs suggests a GET call.');
         end

         if (nargout < 1) && (nargin < 4)
            error('Number of inputs suggests a GET call, but number of outputs suggests a SET call.');
         end
         if numel(obj) > 1
            if nargin < 4
               rate = cell(numel(obj),1);
            end
            for ii = 1:numel(obj)
               if nargout > 1
                  [rate{ii},t] = getSetIncludeStruct(obj(ii),align,includeStruct);
               else
                  if ~iscell(rate)
                     error('For setting multiple input objects at once, specify rate as a cell with one cell per RAT object');
                  end
                  getSetIncludeStruct(obj(ii),align,includeStruct,rate{ii},t);
               end
            end
            return;
         end
         
         if nargin > 3
            getSetIncludeStruct(obj.Children,align,includeStruct,rate,t);
         else
            [rate,t] = getSetIncludeStruct(obj.Children,align,includeStruct);
         end
      end
   end
   
   % Methods for plotting data
   methods (Access = public)
      % Plot average rate profiles across days by group 
      % -- deprecated --
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
      
      % Plot average rate profiles across days by group. Can accept object
      % arrays, cell arrays of 'align' arguments (e.g. {'Grasp','Reach'}),
      % and cell arrays of 'outcome' arguments, which can either be a char
      % vector (e.g. 'Successful' or {'Successful','Unsuccessful','All'})
      % or the includeStruct that is more general for including different
      % kinds of metadata from the BEHAVIORDATA table constructed from
      % appending video metadata to each behavioral/neurophysiological
      % recording. For details about includeStruct, see
      % utils.MAKEINCLUDESTRUCT. In that case, outcome can be an
      % includeStruct or a cell array of such structs 
      % (e.g. {utils.makeIncludeStruct; utils.makeIncludeStruct([],[])}
      % etc.)
      function fig = plotNormAverages(obj,align,outcome)
         % Parse input arguments
         if nargin < 2
            align = defaults.block('all_events');
         end
         
         if nargin < 3
            outcome = defaults.block('outcome');
         end
         
         % Iterate on object array
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
         
         % Iterate on alignments
         if iscell(align)
            if nargout > 0
               fig = [];
               for ii = 1:numel(align)
                  fig = [fig; plotNormAverages(obj,align{ii},outcome)];
               end
               return;
            else
               for ii = 1:numel(align)
                  plotNormAverages(obj,align{ii},outcome)
               end
               return;
            end
         end
            
         % Iterate on all outcomes (or cell arrays of includeStructs) 
         if iscell(outcome)
            if nargout > 0
               fig = [];
               for ii = 1:numel(outcome)
                  fig = [fig; plotNormAverages(obj,align,outcome{ii})];
               end
               return;
            else
               for ii = 1:numel(outcome)
                  plotNormAverages(obj,align,outcome{ii})
               end
               return;
            end
         end
         
         % Run method on child RAT objects of this GROUP object. Make sure
         % to handle differently depending on if nargout is specified, as
         % that determines whether there is batch save/delete or not.
         if nargout > 0
            fig = plotNormAverages(obj.Children,align,outcome);
         else
            plotNormAverages(obj.Children,align,outcome);
         end
         return;

      end
      
      % Plot average rate profiles marginalized by various conditions. If
      % no figure handle is requested as an output, then it automatically
      % saves figures and deletes them (for batch processing).
      function fig = plotMargAverages(obj,align,includeStruct,includeStructMarg)
         % Parse input
         if nargin < 2
            align = defaults.block('alignment');
         end
         
         if nargin < 3
            includeStruct = utils.makeIncludeStruct;
         end
         
         if nargin < 4
            includeStructMarg = utils.makeIncludeStruct;
         end
         
         % Handle array object input
         if numel(obj) > 1
            if nargout < 1
               for ii = 1:numel(obj)
                  plotMargAverages(obj(ii),align,includeStruct,includeStructMarg);
               end
            else
               fig = [];
               for ii = 1:numel(obj)
                  fig = [fig; plotMargAverages(obj(ii),align,includeStruct,includeStructMarg)];
               end
            end
            return;
         end
         
         % Handle batch marginalizations for cell arrays of includeStruct
         if iscell(includeStruct)
            if ~iscell(includeStructMarg)
               error('If includeStruct is a cell array, includeStructMarg must also be.');
            end
            if numel(includeStruct) ~= numel(includeStructMarg)
               error('As a cell array, includeStruct and includeStructMarg must have same number of elements.');
            end
            if nargout < 1
               for ii = 1:numel(includeStruct)
                  plotMargAverages(obj,align,includeStruct{ii},includeStructMarg{ii});
               end
               return;
            else
               fig = [];
               for ii = 1:numel(includeStruct)
                  fig = [fig; plotMargAverages(obj,align,includeStruct{ii},includeStructMarg{ii})];
               end
               return;
            end
         end
         
         % Handle batch marginalizations for cell arrays of alignments
         if iscell(align)
            if nargout < 1
               for ii = 1:numel(align)
                  plotMargAverages(obj,align{ii},includeStruct,includeStructMarg);
               end
               return;
            else
               fig = [];
               for ii = 1:numel(align)
                  fig = [fig; plotMargAverages(obj,align{ii},includeStruct,includeStructMarg)];
               end
               return;
            end
         end
         
         strIn = utils.parseIncludeStruct(includeStruct);
         strMarg = utils.parseIncludeStruct(includeStructMarg);
         
         % Make figure and tabgroup container. Then loop through and make a
         % tab for each RAT object, each of which contains the method to
         % fill out the tab's contents with plots.
         fig = figure('Name',sprintf('%s -- %s vs %s-ByDay',obj.Name,strIn,strMarg),...
            'Color','w',...
            'Units','Normalized',...
            'Position',[0.1+0.01*randn,0.1+0.01*randn,0.8,0.8]);
         tg = uitabgroup(fig);
         pt = [];
         for ii = 1:numel(obj.Children)
            pt = [pt; uitab(tg,'Title',obj.Children(ii).Name)];
            obj.Children(ii).addToTab_PlotMarginalRateByDay(pt(ii),...
               align,includeStruct,includeStructMarg);
         end
         
         % Parse output (do batch saving if no figure handle requested)
         if nargout < 1
            pname = fullfile(pwd,defaults.group('marg_fig_loc'));
            if exist(pname,'dir')==0
               mkdir(pname);
            end
            
            fname = fullfile(pname,sprintf(defaults.group('marg_fig_name'),...
               obj.Name,align,strIn,strMarg,'.fig'));
            savefig(fig,fname);
            for ii = 1:numel(pt)
               fname = fullfile(pname,sprintf(defaults.group('marg_fig_name'),...
                  obj.Children(ii).Name,align,strIn,strMarg,'.png'));
               tg.SelectedTab = pt(ii);
               saveas(fig,fname);
            end
            delete(fig);
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
      
      % Plot channelwise cross-day condition response correlations
      function fig = plotCR(obj,rc)
         if nargin < 2
            rc = 'c';
         end
         
         if numel(obj) > 1
            if nargout > 0
               fig = [];
               for ii = 1:numel(obj)
                  fig = [fig; plotCR(obj(ii),rc)];
               end
               return;
            else
               for ii = 1:numel(obj)
                  plotCR(obj(ii),rc);
               end
               return;
            end
         end
         
         if nargout < 1
            plotCR(obj.Children,obj.Name,rc);
         else
            fig = plotCR(obj.Children,obj.Name,rc);
         end
      end
      
      % Plot mean by-day coherences
      function fig = plotMeanCoherence(obj) 
         if numel(obj) > 1
            if nargout < 1
               for ii = 1:numel(obj)
                  plotMeanCoherence(obj(ii));
               end
               return;
            else
               fig = [];
               for ii = 1:numel(obj)
                  fig = [fig; plotMeanCoherence(obj(ii))];
               end
               return;
            end
         end
         
         if nargout < 1
            plotMeanCoherence(obj.Children,...
               obj.RecentAlignment,obj.RecentIncludes,obj.Name);
         else
            fig = plotMeanCoherence(obj.Children,...
               obj.RecentAlignment,obj.RecentIncludes,obj.Name);
         end
      end
      
      % Make scatter plots accounting for channel type etc 
      % -- deprecated --
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
      
      % Make skull plot for each rat
      function [fig,tstr] = plotSkullLayout(obj,mSizeData,f_min_max,poday_min_max)         
         % Parse inputs
         if nargin < 3
            f_lb = defaults.group('skull_lf_lb');
            f_ub = defaults.group('skull_lf_ub');
         else
            f_lb = min(f_min_max);
            f_ub = max(f_min_max);
         end
         
         if nargin < 4
            poday_lb = defaults.group('skull_poday_lb');
            poday_ub = defaults.group('skull_poday_ub');
         else
            poday_lb = min(poday_min_max);
            poday_ub = max(poday_min_max);
         end
         
         % Parse "title" string from "frequency" string, "post-op" string
         fstr = group.parseParamString(f_lb,f_ub,'f');
         pstr = group.parseParamString(poday_lb,poday_ub,'poday');
         
         tstr = sprintf('%s-%s',fstr,pstr);
         
         fig = figure('Name',sprintf('Rat Electrode Layouts (%s)',tstr),...
            'Units','Normalized',...
            'Color','w',...
            'Position',defaults.group('big_fig_pos'));
         n = -inf;
         for ii = 1:numel(obj)
            n = max(n,numel(obj(ii).Children));
         end
         
         % Import a struct where each field corresponds to an ICMS field
         % representation acronym ('DF' - distal forelimb, 'PF' - proximal 
         % forelimb, 'DFPF' - distal/proximal forelimb boundary,
         % 'O' - other, 'NR' - non-responsive). 
         iPlot = 0;
         
         % For both the lesion and intact groupos
         for ii = 1:numel(obj)
            % Loop through all the rats and make a skull plot for each
            for ij = 1:numel(obj(ii).Children)
               iPlot = iPlot + 1;
               subplot(4,3,iPlot);
               ratSkullObj = obj.buildRatSkullPlot(gca);
               
               % Figure out what is in mSizeData in order to correctly
               % scale the size of the electrode scatter markers to
               % visually co-register the magnitude of the response of
               % whatever is being plotted spatially.
               ratObj = obj(ii).Children(ij);
               E = ratObj.Electrode;
               if nargin < 2
                  sizeData = ones(size(E,1),1) .* 15;
               else
                  if ischar(mSizeData)
                     switch mSizeData
                        case 'coh'
                           c = ratObj.getMeanBandCoherence(f_lb,f_ub,...
                              poday_lb,poday_ub);
                           
                           % One option: normalize to a subset of channels
                           %             in a consistent way
                           c_all = ratObj.getMeanBandCoherence;
%                            cfa_idx = ratObj.getAreaIndices('CFA',true);
%                            cmu = nanmean(c(cfa_idx));
%                            cstd = nanstd(c(cfa_idx));
                           cmu = nanmean(c);
                           cstd = nanstd(c);
                           sizeData = group.c2sizeData(c,cmu,cstd);

%                            % Second option: pick an empirically-determined
%                            %                value that is an approximate
%                            %                average for the coherence
%                            %                value, and use that instead
%                            %                (probably slightly faster)
%                            sizeData = group.c2sizeData(c);
                        otherwise
                           sizeData = ones(size(E,1),1).*15;
                           fprintf(1,'Unrecognized mSizeData: %s\n',mSizeData);
                           fprintf(1,'->\tUsing default value (%g) for all\n',sizeData(1));
                     end
                  else
                     sizeData = mSizeData;
                  end
               end
               
               % For each row of E (each electrode), add a scatter marker
               % that is colored based on its ICMS representation, at the
               % corresponding stereotaxic location on the skull cartoon
               x = E.x; 
               y = E.y; 
               ICMS = E.ICMS;
               ratSkullObj.addScatterGroup(x,y,ICMS);
               
               % Figure out the average score for that rat in that
               % time-period
               [score_avg,score_sd,score_n] = getAvgProp(...
                  ratObj,'TrueScore',poday_lb,poday_ub);
               score_avg = round(score_avg * 100); % Percentages
               score_sem = round(score_sd / sqrt(score_n) * 100);
               
               title(ratSkullObj.Axes,...
                  sprintf('%s (%s): %g%% \\pm %g%%',...
                  ratObj.Name,obj(ii).Name,score_avg,score_sem),...
                  'FontName','Arial','Color','k');
            end
         end
         
      end
      
      % Plots the reprojection fit for each channel in the Ischemia group
      function fig = xPCA_reprojectionErrorBarGraph(obj)
         g = obj.Ischemia;
         if isempty(g)
            error('obj or obj array must contain the ISCHEMIA group.');
         end
         
         if isempty(g.xPC)
            fprintf(1,'Running xPCA on input array first...');
            xPCA(obj);
            fprintf(1,'complete.\n');
         end
         
         fig = figure('Name','xPCA reprojection fit',...
            'Units','Normalized',...
            'Color','w',...
            'Position',defaults.group('big_fig_pos'));
         
         col = defaults.group('rat_color');
         col = col.Ischemia;
         % Get all unique rat names, and get the corresponding lookup array
         % for each channel to be plotted
         ratNames = cellstr(getRatNames(g));
         ratChannelArray = cellstr(vertcat(g.ChannelInfo.Name)); 
         ratAreaArray = {g.ChannelInfo.area}.';
         [avgScore,sdScore,nScore] = getAvgProp(g.Children,'TrueScore');
         avgScore = round(avgScore * 100);
         semScore = round(sdScore./sqrt(nScore) * 100);
         
         axTop = subplot(2,1,1);
         axTop.NextPlot = 'add';
         axBot = subplot(2,1,2);
         axBot.NextPlot = 'add';
         
         % Add different colored bars by group
         for iR = 1:numel(ratNames)
            vec = find(ismember(ratChannelArray,ratNames{iR}));
            iRFA = contains(ratAreaArray(vec),'RFA');
            iCFA = ~iRFA;
            bar(axTop,vec(iRFA),g.xPC.varcapt(vec(iRFA)),1,...
               'FaceColor',col(iR,:),...
               'EdgeColor','k',...
               'LineWidth',2);
            bar(axBot,vec(iRFA),g.xPC.varcapt_red(vec(iRFA)),1,...
               'FaceColor',col(iR,:),...
               'EdgeColor','k',...
               'LineWidth',2);
            bar(axTop,vec(iCFA),g.xPC.varcapt(vec(iCFA)),1,...
               'FaceColor',col(iR,:),...
               'EdgeColor','none');
            bar(axBot,vec(iCFA),g.xPC.varcapt_red(vec(iCFA)),1,...
               'FaceColor',col(iR,:),...
               'EdgeColor','none');
            str = sprintf('%s: %g%% (\\pm%g%%)',...
               ratNames{iR},avgScore(iR),semScore(iR));
            text(axTop,mean(vec)-4,1.15,str,...
               'FontName','Arial',...
               'Color',col(iR,:),...
               'FontSize',13,...
               'FontWeight','bold');
            text(axTop,mean(vec(iRFA))-2,0.975,'RFA',...
               'FontName','Arial',...
               'Color','k',...
               'FontSize',12);
            text(axTop,mean(vec(iCFA))-2,0.975,'CFA',...
               'FontName','Arial',...
               'Color',col(iR,:),...
               'FontSize',12);
            text(axBot,mean(vec)-4,1.15,str,...
               'FontName','Arial',...
               'Color','k',...
               'FontSize',13,...
               'FontWeight','bold');
            text(axBot,mean(vec(iRFA))-2,0.975,'RFA',...
               'FontName','Arial',...
               'Color','k',...
               'FontSize',12);
            text(axBot,mean(vec(iCFA))-2,0.975,'CFA',...
               'FontName','Arial',...
               'Color',col(iR,:),...
               'FontSize',12);
         end
         
         % Set axes labels
         title(axTop,...
            'Variance captured: all Intact PCs',...
            'FontName','Arial','Color','k','FontSize',16);
         xlabel(axTop,...
            'Channel',...
            'Color','k','FontSize',14,'FontName','Arial');
         ylim(axTop,[-0.5 1.25]);
 
         title(axBot,...
            'Variance captured: top Intact PCs',...
            'FontName','Arial','Color','k','FontSize',16);
         xlabel(axBot,...
            'Channel',...
            'Color','k','FontSize',14,'FontName','Arial');
         ylim(axBot,[-0.5 1.25]);
      end
      
   end
   
   % Static GROUP methods (such as loading the default 'gData' variable)
   methods (Static = true)
      % Scale the values in c to appropriate values of sizeData to give
      % them a striking visual contrast that corresponds roughly with their
      % z-score, based on the value of cmu and an empirically-set
      % standard-deviation (defaults.group('skull_cstd_size'))
      function sizeData = c2sizeData(c,cmu,cstd)
         % Load config params from defaults.group
         if nargin < 2
            cmu = defaults.group('skull_cmu_size');
         end
         if nargin < 3
            cstd = defaults.group('skull_cstd_size');
         end
         mu = defaults.group('skull_mu_size');
         sd = defaults.group('skull_std_size');
         
         minsize = defaults.group('skull_min_size');
         maxsize = defaults.group('skull_max_size');
         
%          % Set discrete values that sizes can take, based on a logarithmic
%          % scaling.
%          n = defaults.group('skull_n_size_levels');
%          lb = minsize - 1e-2;
%          ub = maxsize - lb;
%          size_vals = logspace(-2,0,n)*ub + lb; 
%          size_edges = linspace(-2.5,2.5,n-3);
%          size_edges = [-inf, size_edges, 3.5, 5, inf];
         
         % Normalize based on old empirical params
         z = (c - cmu)./cstd;

         % Scale to new empirical params
         sizeData = (z * sd) + mu;
         sizeData = max(sizeData,ones(size(sizeData))*minsize);
         sizeData = min(sizeData,ones(size(sizeData))*maxsize);
         
%          zi = discretize(z,size_edges);
%          sizeData = size_vals(zi);
         
         
      end
      
      % Helper function to get paths consistently because I forget where
      % things are all the time
      function pname = getPathTo(dataType)
         pname = [];
         if nargin < 1
            dataType = 'localrepo';
         end
                 
         
         switch lower(dataType)
            case {'local','localrepo','repo'}
               pname = defaults.group('local_repo_name');
            case {'skullplots','ratskullplots','maps','skullmaps','map','skull','skullmap'}
               pname = defaults.conditionResponseCorrelations('save_path');
            case {'conditionresponsecorrelations','crossday','crossdayresponses','crossdaycorrelations'}
               pname = defaults.conditionResponseCorrelations('save_path');
            otherwise
               fprintf(1,'Unrecognized ''dataType'': %s\n',dataType);
         end
               
         
      end
      
      % Helper function to load and time the loading of group data object
      function loadGroupData
         ticTimes = struct;
         loadTic = tic;
         fprintf(1,'Loading gData object...');
         fname = defaults.experiment('group_data_name');
         if exist(fname,'file')==0
            fprintf(1,'The file ''%s'' does not exist. Try running main.m\n\n',fname);
            return;
         else
            load(defaults.experiment('group_data_name'),'gData');
         end
         ticTimes.load = round(toc(loadTic));
         fprintf(1,'complete (%g sec elapsed)\n',ticTimes.load);
         mtb(ticTimes);
         mtb(gData);
      end
      
      % Helper function to parse labeling strings based on
      % parameterizations
      function str = parseParamString(param_lb,param_ub,param_name)
         switch lower(param_name)
            % Parse post-operative day ranges
            case {'poday','po-day','post-op day','postopday','postop day'}
               if (param_lb >= 4) && (param_ub <= 10) 
                  str = 'Week1';
               elseif (param_lb >= 11) && (param_ub <= 17) 
                  str = 'Week2';
               elseif (param_lb >= 18) && (param_ub <= 24)
                  str = 'Week3';
               else
                  str = 'AllWeeks';
               end
            
            % Parse frequency range "bands"
            case {'f','freq','freqs','frange','freq_range'}
               if (param_lb >= 1.5) && (param_ub <= 5)
                  str = 'LFO';
               elseif (param_lb >= 7) && (param_ub <= 12)
                  str = 'HFO';
               else
                  str = 'AllFreqs';
               end
               
            % Catch-all
            otherwise
               error('Unrecognized parameter name: %s',lower(param_name));
         end
      end
      
      
   end
   
end

