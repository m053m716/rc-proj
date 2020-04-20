classdef group < matlab.mixin.Copyable
   %GROUP organizes all data for an experimental group in RC project
   
   % Public properties that are set in the class constructor upon object
   % creation
   properties (GetAccess = public, SetAccess = immutable, Hidden = false)
      Name        % Name of this experimental group
   end
   
   % Properties that can be retrieved publically but only set by class
   % methods.
   properties (GetAccess = public, SetAccess = private, Hidden = false)
      Parent      % Handle to SPIKEDATA parent object (if set)
      Data        % Struct to hold GROUP-level data
      xPC         % Struct to hold xPCA-related data
      ChannelInfo % Aggregate (masked) channel info
      RecentAlignment   % Most-recent alignment run by a method
      RecentIncludes    % Most-recent "includeStruct" run by a method
   end
   
   % Properties that can both be retrieved and set publicly
   properties (GetAccess = public, SetAccess = public, Hidden = false)
      CR                % Table of Channel Response correlations
      Children    % Child rat objects belonging to this GROUP
   end
   
   % Hidden properties that must be set using class methods but can be
   % retrieved publicly
   properties (GetAccess = public, SetAccess = private, Hidden = true)
      HasData = false;  % Do any of the rats have data associated?
      
      % Flags for concatenated stats tables
      HasTrialStats = false;
      HasChannelStats = false;
      HasRatStats = false;
      HasSessionStats = false;
   end
   
   % Hidden public properties (probably deprecated)
   properties (Access = public, Hidden = true)
      pct
      p
   end
   
   % Class constructor and main data-handling methods
   methods (Access = public)
      % Group object constructor
      function obj = group(name,ratArray)
         if nargin < 2
            if isnumeric(name) && isscalar(name)
               nGroup = name;
               obj = repmat(obj,nGroup,1);
               return;
            end
         end
         
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
         
         subGroupArray = group(numel(groupIndices));
         for ii = 1:numel(groupIndices)
            subGroupArray = group(groupNameArray{ii},obj.Children(groupIndices{ii}));
            subGroupArray(ii).p = obj.p;
            subGroupArray(ii).pct = obj.pct;
         end
         
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
   
   % "PROPERTY" methods (shortcuts for getting indexed GROUP objects)
   methods (Access = public)
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
   
   % "GET" methods
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
         nameArray = cellstr(getProp(obj.Children,'Name',true));
      end
      
      % Return a numeric property from the BLOCK level
      function propValArray = getBlockNumProp(obj,propName,byChannel)
         if nargin < 2
            error('Must specify property name as a character array.');
         end
         
         if nargin < 3
            byChannel = false;
         end
         
         if numel(obj) > 1
            propValArray = [];
            for i = 1:numel(obj)
               propValArray = [propValArray; obj(i).getBlockNumProp(propName,byChannel)];
            end
            return;
         end
         
         propValArray = [];
         for i = 1:numel(obj.Children)
            propValArray = [propValArray; getNumProp(obj.Children(i).Children,propName,byChannel)];
         end
      end
      
      % Return summary of BLOCK objects in record
      function S = getBlockSummary(obj,output_score)
         if nargin < 2
            output_score = defaults.group('output_score');
         end
         
         if numel(obj) > 1
            S = [];
            for i = 1:numel(obj)
               S = [S; getBlockSummary(obj(i),output_score)];
            end
            return;
         end
         
         % Extract summary variables
         Name = getBlockNames(obj); %#ok<*PROP>
         Rat = cellfun(@(x){x(1:5)},Name,'UniformOutput',true);
         Group = repmat(categorical({obj.Name}),numel(Rat),1);
         Score = getBlockNumProp(obj,output_score);
         PostOpDay = getBlockNumProp(obj,'PostOpDay');
         
         ReachToGrasp_All = getOffsetLatency(obj,'Grasp','Reach',[0,1],1);
         ReachToComplete_All = getOffsetLatency(obj,'Complete','Reach',[0,1],1);
         GraspToComplete_All = getOffsetLatency(obj,'Complete','Grasp',[0,1],1);
         GraspToSupport_All = getOffsetLatency(obj,'Support','Grasp',[0,1],1);
         
         ReachToGrasp_Successful = getOffsetLatency(obj,'Grasp','Reach',1,1);
         ReachToComplete_Successful = getOffsetLatency(obj,'Complete','Reach',1,1);
         GraspToComplete_Successful = getOffsetLatency(obj,'Complete','Grasp',1,1);
         GraspToSupport_Successful = getOffsetLatency(obj,'Support','Grasp',1,1);
         
         S = table(Rat,Group,Name,PostOpDay,Score,...
            ReachToGrasp_All,ReachToComplete_All,GraspToComplete_All,GraspToSupport_All,...
            ReachToGrasp_Successful,ReachToComplete_Successful,GraspToComplete_Successful,GraspToSupport_Successful);
         
         % Append descriptions
         S.Properties.Description = 'Block Summary Table';
         S.Properties.VariableDescriptions = ...
            {'Name of Rat', ...
            'Experimental Group (Ischemia or Intact)', ...
            'Name of Recording Block',...
            'Day relative to implant/injection surgery date',...
            sprintf('%s - retrieval success rate',output_score),...
            'Time from reach onset to digit flexion (All trials with pellet present)',...
            'Time from reach onset to trial completion (All trials with pellet present)',...
            'Time from digit flexion to trial completion (All trials with pellet present)',...
            'Time from digit flexion to support limb movement (All trials with pellet present)',...
            'Time from reach onset to digit flexion (Successful trials with pellet present)',...
            'Time from reach onset to trial completion (Successful trials with pellet present)',...
            'Time from digit flexion to trial completion (Successful trials with pellet present)',...
            'Time from digit flexion to support limb movement (Successful trials with pellet present)'};
         S.Properties.VariableUnits = ...
            {'', ...
            '', ...
            '',...
            'days',...
            'nSuccessful/nAttempt',...
            'milliseconds',...
            'milliseconds',...
            'milliseconds',...
            'milliseconds',...
            'milliseconds',...
            'milliseconds',...
            'milliseconds',...
            'milliseconds'};
         
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
         
         % Flags: doUpdate (false); useMask (true)
         channelInfo = getChannelInfo(obj.Children,false,true);
         
         if doUpdate
            obj.ChannelInfo = channelInfo;
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
            stats.Rat = categorical(stats.Rat);
            stats.Name = categorical(stats.Name);
            stats.Group = categorical(stats.Group);
            stats.ml = categorical(stats.ml);
            stats.icms = categorical(stats.icms);
            stats.area = categorical(stats.area);
            stats.Properties.UserData = struct(...
               'align',align,...
               'outcome',outcome);
         end
      end
      
      % Get median offset latency (ms) between two behaviors
      %     align1 : "Later" alignment   (grasp, in reach-grasp pair)
      %     align2 : "Earlier" alignment (reach, in reach-grasp pair)
      %     offset : Positive value indicates that align1 occurs after
      %                 align2
      function offset = getOffsetLatency(obj,align1,align2,outcome,pellet,mustInclude,mustExclude)         
         if nargin < 3
            error('Must specify two alignment points (''Reach'', ''Grasp'', ''Support'', or ''Complete'')');
         end
         
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
         
         if ~ismember(align1,{'Reach','Grasp','Support','Complete'}) || ...
               ~ismember(align2,{'Reach','Grasp','Support','Complete'})
            error('Invalid alignment. Must specify from: (Reach, Grasp, Support, Complete)');
         end
         
         if numel(obj) > 1
            offset = [];
            for i = 1:numel(obj)
               offset = [offset; getOffsetLatency(obj(i),align1,align2,outcome,pellet,mustInclude,mustExclude)];
            end
            return;
         end
         
         offset = getOffsetLatency(obj.Children,align1,align2,outcome,pellet,mustInclude,mustExclude);
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
      
      % Get or Set XC-MEAN struct fields based on includeStruct format
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
      
      % Get subset of array using groupName
      % out = gData.getSubsetByGroup('Intact');
      % out = gData.getSubsetByGroup({'Intact','Ischemia'});
      function out = getSubGroup(obj,groupName)
         names = {obj.Name};
         idx = ismember(lower(names),lower(groupName));
         if sum(idx) < 1
            fprintf(1,'No group in array with that name.\n');
            if iscell(groupName)
               fprintf(1,'-->\t%s\n',groupName{:});
            else
               fprintf(1,'-->\t%s\n',groupName);
            end
            error('Invalid groupName');
         end
         out = obj(idx);
      end      
      
      % Return rate data as a tensor of [nTrial x nTimesteps x nChannels],
      % corresponding time values (milliseconds) in t, and corresponding
      % channel/trial metadata in meta
      function [rate,t,meta] = getTrialData(obj,includeStruct,align,area,icms)
         % GETTRIALDATA    Return trial-aligned spike rates and metadata
         %
         %  [rate,t,meta] = GETTRIALDATA(obj);
         %  [rate,t,meta] = GETTRIALDATA(obj,includeStruct);
         %  [rate,t,meta] = GETTRIALDATA(obj,includeStruct,align);
         %  [rate,t,meta] = GETTRIALDATA(obj,includeStruct,align,area);
         %  [rate,t,meta] = GETTRIALDATA(obj,includeStruct,align,area,icms);
         %
         %  in- 
         %  includeStruct : Returned by utils.makeIncludeStruct
         %  align : 'Grasp', 'Reach', 'Support', or 'Complete'
         %  area : 'CFA', 'RFA', or 'Full'
         %  icms : 'DF' or {'DF','PF','DF-PF','O',...} (to include those)
         %
         %  out-
         %  rate : [nTrial x nTimesteps x nChannels] tensor of rates
         %  t : [1 x nTimesteps] vector it times (milliseconds)
         %  meta : Struct containing metadata fields --
         %     --> .behaviorData : Table of all trial times, corresponds to
         %              rows of 'rate'
         %     --> .channelInfo : Struct of all channel info, corresponds
         %              to 3rd dim of 'rate'
         
         if nargin < 5
            icms = defaults.group('icms');
         elseif isempty(icms)
            icms = defaults.group('icms');
         end
         
         if nargin < 4
            area = defaults.group('area');
         elseif isempty(area)
            area = defaults.group('area');
         end
         
         if nargin < 3
            align = defaults.group('align');
         elseif isempty(align)
            align = defaults.group('align');
         end
         
         if nargin < 2
            includeStruct = defaults.group('include');
         elseif isempty(includeStruct)
            includeStruct = defaults.group('include');
         end
         
         % Handle input array
         if numel(obj) > 1
            [rate,meta] = utils.initEmpty;
            t = utils.initCellArray(numel(obj),1);
            for i = 1:numel(obj)
               [tmprate,t{i},tmpmeta] = obj(i).getTrialData(includeStruct,align,area,icms);
               rate = [rate; tmprate];
               meta = [meta; tmpmeta];
            end
            t = utils.getFirstNonEmptyCell(t);
            return;
         end
         
         [rate,t,meta] = getTrialData(obj.Children,includeStruct,align,area,icms);
         for i = 1:numel(meta)
            meta{i}.channelInfo = group.cleanChannelInfo(meta{i}.channelInfo,{obj.Name});
         end
      end
   end
   
   % "SET" methods
   methods (Access = public)
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
      
      % Set parent spikeData object
      function setParent(obj,p)
         if ~isa(p,'spikeData')
            error('Parent must be a spikeData class object.');
         end
         if numel(obj) > 1
            for i = 1:numel(obj)
               obj(i).setParent(p);
            end
            return;
         end
         obj.Parent = p;
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
      
   end
   
   % "GRAPHICS" methods
   methods (Access = public)
      % Puts a rat skull plot object on current axes
      function [ratSkullObj,ax] = buildRatSkullPlot(obj,ax)
         if nargin < 2
            ax = gca;
         end
         ratSkullObj = ratskull_plot(ax);
         obj.scatterInjectionSites(ratSkullObj);
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
         hg = gobjects(numel(obj),1);
         plotDayVec = 4:28;
         data = cell(numel(obj),numel(plotDayVec));
         
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

            
            groupScore = nan(size(plotDayVec));
            groupStd = nan(size(plotDayVec));
            for ik = 1:numel(plotDayVec)
               for ii = 1:numel(obj(iG).Children)
                  if ismember(plotDayVec(ik),allDays{ii})
                     data{iG,ik} = [data{iG,ik}; smoothedData{ii}(allDays{ii}==plotDayVec(ik))];
                  end
               end
               if ~isempty(data{iG,ik})
                  groupScore(ik) = mean(data{iG,ik});
                  groupStd(ik) = std(data{iG,ik});
               end
            end
            
            subplot(3,6,1:6);
            hold on;
%             errorbar(plotDayVec,groupScore*100,groupStd*100,...
%                'Color',mean(rat_color.(obj(iG).Name),1),'LineWidth',3);
            % Plot shading as 1 SD for confidence interval
            hg(iG) = gfx.plotWithShadedError(plotDayVec,...
               groupScore*100,...
               groupStd*100,...
               'LineWidth',3,...
               'Color',max(rat_color.(obj(iG).Name),[],1),...
               'DisplayName',obj(iG).Name,...
               'FaceColor',min(rat_color.(obj(iG).Name),[],1));
            set(gca,'XColor','k');
            set(gca,'YColor','k');
            set(gca,'FontName','Arial');
            set(gca,'LineWidth',1);
            xlabel('Post-Op Day','FontName','Arial','Color','k','FontSize',12);
            ylabel('% Successful','FontName','Arial','Color','k','FontSize',12);
            title('Group Mean Score','FontName','Arial','Color','k','FontSize',14);
            ylim([0 100]);
%             legText = [legText; {obj(iG).Name}];
%             legend(legText,'Location','NorthWest');
         end
         legend(hg);
         xlim([min(plotDayVec)-0.25,max(plotDayVec)+0.25]);
         
         startFlag = true;
         endFlag = false;
         
         % Append whether it was significant or not using a line above the
         % plot
%          sigGroup = hggroup(gca,...
%             'DisplayName','Significant (\alpha = 0.05)');
%          for i = 1:numel(plotDayVec)
%             d = plotDayVec(i);
%             
%             if ttest2(data{1,i},data{2,i},'Alpha',0.05,'Vartype','unequal')
%                if startFlag
%                   line([d,d],[75 90],'Color','k','LineWidth',2.5,...
%                      'Parent',sigGroup);
%                   startFlag = false;
%                   endFlag = true;
%                end
%                line([d,d+1],[90 90],'Color','k','LineWidth',2.5,...
%                      'Parent',sigGroup);
%             else
%                if endFlag
%                   line([d,d],[90 75],'Color','k','LineWidth',2.5,...
%                      'Parent',sigGroup);
%                   startFlag = true;
%                   endFlag = false;
%                end
%             end
%          end
         sigGroup = gfx.addSignificanceLine(gca,plotDayVec,data(2,:),data(1,:),0.05);
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
   
   % "STATS" (export) methods
   methods (Access = public)
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
      
      function channelInfo = cleanChannelInfo(channelInfo,Group)
         channelInfo = utils.addStructField(channelInfo,Group);
         channelInfo = orderfields(channelInfo,[1,7,2:6]);
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
               pname = defaults.filenames('local_repo_name');
            case {'skullplots','ratskullplots','maps','skullmaps','map','skull','skullmap'}
               pname = defaults.conditionResponseCorrelations('save_path');
            case {'conditionresponsecorrelations','crossday','crossdayresponses','crossdaycorrelations'}
               pname = defaults.conditionResponseCorrelations('save_path');
            otherwise
               fprintf(1,'Unrecognized ''dataType'': %s\n',dataType);
         end
               
         
      end
      
      % Helper function to load and time the loading of group data object
      function [gData,ticTimes,pcFitObj,xPC] = loadGroupData
         ticTimes = struct;
         loadTic = tic;
         fprintf(1,'Loading gData object...');
         fname = defaults.files('group_data_name');
         if exist(fname,'file')==0
            fprintf(1,'The file ''%s'' does not exist. Try running main.m\n\n',fname);
            return;
         else
            switch nargout
               case 0
                  load(fname,'gData','pcFitObj','xPC');
                  ticTimes.load = round(toc(loadTic));
                  utils.mtb(gData);
                  utils.mtb(pcFitObj);
                  utils.mtb(xPC);
                  utils.mtb(ticTimes);
               case 1
                  in = load(fname,'gData');
                  ticTimes.load = round(toc(loadTic));
                  gData = in.gData;
               case 2
                  in = load(fname,'gData');
                  ticTimes.load = round(toc(loadTic));
                  gData = in.gData;
               case 3
                  in = load(fname,'gData','pcFitObj');
                  ticTimes.load = round(toc(loadTic));
                  gData = in.gData;
                  pcFitObj = in.pcFitObj;
               case 4
                  in = load(fname,'gData','pcFitObj','xPC');
                  ticTimes.load = round(toc(loadTic));
                  gData = in.gData;
                  pcFitObj = in.pcFitObj;
                  xPC = in.xPCObj;
               otherwise
                  error('Invalid number of outputs (%g) requested.',...
                     nargout);
            end
         end
         utils.addHelperRepos();
         fprintf(1,'complete (%g sec elapsed)\n',ticTimes.load);
         
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

