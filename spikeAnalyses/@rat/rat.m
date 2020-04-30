classdef rat < handle
   %RAT  Object to organize data for an individual rat from RC project
   
   properties (GetAccess = public, SetAccess = private)
      Name           % Name of this rat
      Parent         % Parent GROUP object
      ChannelInfo    % Channel information struct
      ChannelMask    % Masking of channels for this rat
      Children       % Children BLOCK objects
      Data           % Struct to hold RAT-level data
      XCMean         % Cross-condition mean struct
      xPC            % "Cross-day" PCA object
      Electrode      % Table of electrode site stereotaxic coordinates
      
      dominant       % Struct 1 x nChannel "dominant" frequencies
      coh            % Struct of nPoDay x nFreq x nChannel(masked) coherence data
   end
   
   properties (Access = private)
      Folder         % Location of TANK that holds rat folders
   end
   
   properties (Access = public, Hidden = true)
      ScreeningUI       % Figure UI for screening data channels
      HasData = false;  % Flag for whether any blocks have data for rat
      chMod  % Channel-wise modulations (a temporary variable for plotting)
      
      RecentAlignment      % Most-recent alignment
      RecentIncludes       % Most-recent include struct
      
      HasCrossDayCorrelations = false % Flag: GETCHANNELRESPONSECORRELATIONSBYDAY
   end
   
   properties (Access = public)
      CR                % Channel response correlations
   end
   
   % Class constructor and data-handling methods
   methods (Access = public)
      % Rat class constructor
      function obj = rat(path,extractSpikeRate)
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
            extractSpikeRate = defaults.rat('do_spike_rate_extraction');
         end
         
         if exist(path,'dir')==0
            error('Invalid path: %s',path);
         else
            pathInfo = strsplit(path,filesep);
            obj.Name = pathInfo{end};
            obj.Folder = strjoin(pathInfo(1:(end-1)),filesep);
         end
         % Set ChannelInfo property as well (true flag)
         obj.getChannelInfo(true);
                
         ratTic = tic;
         fprintf(1,'-------------------------------------------------\n');
         fprintf(1,'\t\t%s\n',obj.Name);
         fprintf(1,'-------------------------------------------------\n');
         findChildren(obj,extractSpikeRate);
         if (defaults.rat('suppress_data_curation'))
            obj.loadChannelMask;
         else
            fig = dataScreeningUI(obj);
            waitfor(fig);
         end
         
         fprintf(1,'-------------------------------------------------\n');
         fprintf(1,'\t\t\t\t\t%s --> %g sec\n\n',obj.Name,round(toc(ratTic)));
      end
      % Function to convert child array from cell format to array format,
      % where columns are channels and each row of the array corresponds to
      % a child BLOCK object.
      function Y = childCell2ChannelArray(obj,X)
         if numel(obj) > 1
            error('CHILDCELL2CHANNELARRAY is a method for scalar RAT objects only.');
         end
         Y = nan(numel(X),sum(obj.ChannelMask));
         for ii = 1:numel(X)
            ch = getParentChannel(obj.Children(ii));
            idx = ~isnan(ch);
            if ~isempty(X{ii})
               Y(ii,ch(idx)) = X{ii}(idx);
            end
         end
      end
      
      % Concatenate rates for a given condition across all children BLOCK
      % objects, along time-axis (concatenating trials together), through
      % days. Results in a 2D matrix.
      X = concatChildRate(obj,align,includeStruct,area,tIdx);
      
      % Same as CONCATCHILDRATE but appends along trials axis as opposed to
      % along time-axis (so that trials are maintained as a 3D tensor).
      [X,t] = concatChildRate_trials(obj,align,includeStruct,area,tIdx);
      
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
      
      % Find children blocks associated with this rat
      function findChildren(obj,extractSpikeRate)         
         if nargin < 2
            extractSpikeRate = defaults.rat('do_spike_rate_extraction');
         end
         
         path = fullfile(obj.Folder,obj.Name);
         F = dir(fullfile(path,[obj.Name '_2*']));
         for iF = 1:numel(F)
            maintic = tic;
            h = block(fullfile(F(iF).folder,F(iF).name),extractSpikeRate);
            if h.HasData
               obj.addChild(h,maintic);
            else
               fprintf(1,'-->\tNo data in %s. Skipped.\t\t(%g sec)\n',...
                  h.Name,round(toc(maintic)+3));
            end
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
      
      % From parent array where channels are columns and rows are recording
      % blocks, return a cell array where each cell is a recording block
      % and each 1 x nChannel array matches the masked channel indexing of
      % that corresponding child block object.
      function X = parentChannelArray2ChildCell(obj,Y)
         if numel(obj) > 1
            error('PARENTCHANNELARRAY2CHILDCELL is a method for scalar RAT objects only.');
         end
         X = cell(numel(obj.Children),1);
         if numel(Y) == 1
            Y = repmat(Y,numel(obj.Children),sum(obj.ChannelMask));
         end
         for ii = 1:numel(X)
            ch = obj.Children(ii).getParentChannel;
            X{ii} = Y(ii,ch);
         end
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
      
      % Parse the mediolateral and anteroposterior coordinates from bregma
      % for a given set of electrodes (returned in millimeters)
      function [x,y] = parseElectrodeCoordinates(obj,area)
         if nargin < 2
            area = 'Full';
         end
         if numel(obj) > 1
            if nargout > 0
               x = cell(numel(obj),1); 
               y = cell(numel(obj),1);
               for ii = 1:numel(obj)
                  [x{ii},y{ii}] = parseElectrodeCoordinates(obj(ii),area);
               end
            else
               for ii = 1:numel(obj)
                  parseElectrodeCoordinates(obj(ii),area);
               end
            end
            return;
         end
         x = []; y = []; ch = []; %#ok<NASGU>
         
         E = readtable(defaults.block('elec_info_xlsx'));
         E = E(ismember(E.Rat,obj.Name),:);
         if isempty(E)
            fprintf(1,'Could not match rat name: %s. Can''t parse electrode info.\n',obj.Name);
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

            [x_grid_cfa,y_grid_cfa,ch_grid_cfa] = rat.parseElectrodeOrientation(ch_CFA);
            x_grid_cfa = x_grid_cfa + loc.CFA.x;
            y_grid_cfa = y_grid_cfa + loc.CFA.y;
%             Probe = [Probe; [ch_CFA.probe].'];
%             Channel = [Channel; [ch_CFA.channel].'];
%             ICMS = [ICMS; {ch_CFA.icms}.'];
         end
         
         if ~strcmpi(area,'CFA')
            % Get RFA arrangement
            ch_RFA = ch_info(contains({ch_info.area},'RFA'));

            [x_grid_rfa,y_grid_rfa,ch_grid_rfa] = rat.parseElectrodeOrientation(ch_RFA);
            x_grid_rfa = x_grid_rfa + loc.RFA.x;
            y_grid_rfa = -(y_grid_rfa + loc.RFA.y); % make RFA on "bottom" of plot
%             Probe = [Probe; [ch_RFA.probe].'];
%             Channel = [Channel; [ch_RFA.channel].'];
%             ICMS = categorical([ICMS; {ch_RFA.icms}.']);
         end
         
         if (strcmpi(area,'CFA') || strcmpi(area,'RFA'))
            ch_info = ch_info(contains({ch_info.area},area));
         end
         
         for ii = 1:numel(ch_info)
            if contains(ch_info(ii).area,'CFA')
               cch = ch_info(ii).channel;
               x = [x; x_grid_cfa(ch_grid_cfa == cch)];
               y = [y; y_grid_cfa(ch_grid_cfa == cch)];
               
            else % RFA
               rch = ch_info(ii).channel;
               x = [x; x_grid_rfa(ch_grid_rfa == rch)];
               y = [y; y_grid_rfa(ch_grid_rfa == rch)];
            end
            Probe = [Probe; ch_info(ii).probe];
            Channel = [Channel; ch_info(ii).channel];
            ICMS = [ICMS; {ch_info(ii).icms}];
         end
         ICMS = categorical(ICMS);
         
         if ~(strcmpi(area,'CFA') || strcmpi(area,'RFA'))
            obj.Electrode = table(Probe,Channel,ICMS,x,y);
         end
         
      end
      
      % Run function on children Block objects
      function runFun(obj,f,varargin)
         %RUNFUN  Run function on children blocks
         %
         %  runFun(ratObj,'function');
         %  runFun(ratObj,'function',arg1,arg2,...,argk);
         
         if numel(obj) > 1
            for i = 1:numel(obj)
               runFun(obj(i),f,varargin{:});
            end
            return;
         end
         
         for ii = 1:numel(obj.Children)
            feval(f,obj.Children(ii),varargin{:});
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
      % -- deprecated --
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
      
      % "Cross" PCA
      xPCA(obj);
   end
   
   % "GET" and "SET" methods
   methods (Access = public)
      % Returns the channel indices corresponding to a subset by area
      function idx = getAreaIndices(obj,area,useMask)
         if nargin < 3
            useMask = true;
         end
         
         if nargin < 2
            area = 'Full'; % Basically just returns all the channel indices
         end
         
         % Get an array of 'area' for each channel
         if useMask
            a = {obj.ChannelInfo(obj.ChannelMask).area};
         else
            a = {obj.ChannelInfo.area};
         end
         
         % If area is invalid, just return an empty array
         if isempty(a)
            idx = [];
            return;
         end
         
         % Return the area
         idx = find(contains(a,area));
         
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
      
      % Return property average from all children bounded by post-op days
      function [avg,sd,n] = getAvgProp(obj,propName,poday_lb,poday_ub)
         % If poday_ub/lb not specified, then 
         if nargin < 4
            poday_ub = defaults.experiment('poday_max');
         elseif isnan(poday_ub) || isempty(poday_ub)
            poday_ub = defaults.experiment('poday_max');
         end
         
         if nargin < 3
            poday_lb = defaults.experiment('poday_min');
         elseif isnan(poday_lb) || isempty(poday_lb)
            poday_lb = defaults.experiment('poday_min');
         end
         
         % Handle array inputs
         if numel(obj) > 1
            avg = nan(numel(obj),1);
            sd = nan(numel(obj),1);
            n = nan(numel(obj),1);
            for ii = 1:numel(obj)
               [avg(ii),sd(ii),n(ii)] = ...
                  getAvgProp(obj(ii),propName,poday_lb,poday_ub);
            end
            return;            
         end
         
         % Restrict the recordings based on post-op day
         poday = getNumProp(obj.Children,'PostOpDay');
         idx = (poday>=poday_lb) & (poday<=poday_ub);
         
         % Get stats of property value
         val = getNumProp(obj.Children(idx),propName);
         avg = nanmean(val);
         sd = nanstd(val);
         n = numel(val);
      end
      
      % Returns the names of all block children objects
      function names = getBlockNames(obj)
         names = cell(size(obj.Children));
         for ii = 1:numel(obj.Children)
            names{ii} = obj.Children(ii).Name;
         end
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
               propValArray = [propValArray; ...
                  obj(i).getBlockNumProp(propName,byChannel)];
            end
            return;
         end
         propValArray = getNumProp(obj.Children,propName,byChannel);

      end
      
      % Returns the corresponding Electrode table row indices for a channel 
      % index that is ordered by the (masked) channelInfo order
      function e_idx = getChannelElectrodeIndex(obj,ci_idx)
         if numel(obj) > 1
            error('GETCHANNELEELCTRODEINDEX is a scalar method.');
         end
         if nargin < 2
            ci_idx = 1:sum(obj.ChannelMask);
         end
         e_idx = nan(size(ci_idx));
         ci = obj.ChannelInfo(obj.ChannelMask);
         for ii = 1:numel(ci_idx)
            p = ci(ci_idx(ii)).probe;
            c = ci(ci_idx(ii)).channel;
            tmp = find((obj.Electrode.Probe == p) & (obj.Electrode.Channel == c),1,'first');
            if isempty(tmp)
               continue;
            else
               e_idx(ii) = tmp;
            end
         end
      end
      
      % Returns the channel info for all electrodes implanted on a given
      % rat. If obj is an array, returns a concatenated channelInfo struct
      % array. If doUpdate is set to true, then updates the associated
      % object ChannelInfo property.
      function channelInfo = getChannelInfo(obj,doUpdate,useMask,icms_file)
         if nargin < 2 % Parse whether to update ChannelInfo property
            if nargout < 1
               doUpdate = true;
            else
               doUpdate = false;
            end
         end
         
         % By default, return the masked version (this doesn't apply to
         % updating the channelInfo property).
         if nargin < 3
            useMask = true;
         end
         
         if nargin < 4
            icms_file = defaults.rat('icms_file');
         end
         
         if numel(obj) > 1
            channelInfo = [];
            for ii = 1:numel(obj)
               channelInfo = [channelInfo; ...
                  obj(ii).getChannelInfo(doUpdate,useMask,icms_file)];
            end
            return;
         end
         
         channelInfo = getChannelInfo(obj.Name,icms_file);  
         if doUpdate
            obj.ChannelInfo = channelInfo;
         end
         
         % If no output requested, end here
         if nargout < 1
            return;
         end
         
         % Otherwise, append 'Name' property and return it
         Name = {obj.Name}; %#ok<*PROPLC>
         channelInfo = utils.addStructField(channelInfo,Name);
         channelInfo = orderfields(channelInfo,[6,1:5]);
         if useMask
            channelInfo = channelInfo(obj.ChannelMask);
         end
         
      end
      
      % Returns array of TOP PC Fits (A) as well as MSE for fit and the
      % corresponding post-op day. Rows of A/mse correspond to ChannelInfo
      % (without mask).
      function [A,mse,poday] = getChannelPCFits(obj)
         if numel(obj) > 1
            A = cell(numel(obj),1);
            mse = cell(numel(obj),1);
            poday = cell(numel(obj),1);
            for ii = 1:numel(obj)
               [A{ii},mse{ii},poday{ii}] = getChannelPCFits(obj(ii));
            end
            return;
         end
         
         A = nan(numel(obj.ChannelInfo),obj.Children(1).pcFit(1).xPC.li,numel(obj.Children));
         mse = nan(size(A,1),size(A,3));
         poday = nan(size(A,3),1);
         for ii = 1:numel(obj.Children)
            if ~isa(obj.Children(ii).pcFit,'double')
               [A(:,:,ii),mse(:,ii),poday(ii)] = getChannelCoeffs(obj.Children(ii).pcFit);
            end
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
      
      % Get the individual channel correlations, for each day
      function [r,err_r,c,err_c,n] = getChannelResponseCorrelationsByDay(obj,align,includeStruct)
         if nargin < 2
            align = defaults.rat('alignment');
         end
         
         if nargin < 3
            includeStruct = defaults.rat('include');
         end
         
         if numel(obj) > 1
            r = cell(numel(obj),1);
            err_r = cell(numel(obj),1);
            c = cell(numel(obj),1);
            err_c = cell(numel(obj),1);
            n = cell(numel(obj),1);
            for ii = 1:numel(obj)
               [r{ii},err_r{ii},c{ii},err_c{ii},n{ii}] = getChannelResponseCorrelationsByDay(obj(ii),align,includeStruct);
            end
            return;
         end
         obj.HasCrossDayCorrelations = true;
         obj.setAlignInclude(align,includeStruct);
         
         obj.CR = []; % Clear previous table
         [r,err_r,c,err_c,n] = getChannelResponseCorrelations(obj.Children,align,includeStruct);
         
         if (~isempty(obj.Parent)) && (~isempty(obj.CR))
            Rat = repmat(categorical({obj.Name}),size(obj.CR,1),1);
            obj.Parent.CR = [obj.Parent.CR; [table(Rat),obj.CR]];
         end
      end
      
      % Return the channel-wise spike rate statistics for all recordings of
      % this rat
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
      
      % Returns the channel info for all child BLOCK objects of this RAT
      % object, or a concatenated array for all RAT objects in an input
      % array argument.
      function chChannelInfo = getChildChannelInfo(obj)
         if numel(obj) > 1
            chChannelInfo = [];
            for ii = 1:numel(obj)
               chChannelInfo = [chChannelInfo; ...
                  obj(ii).getChildChannelInfo;];
            end
            return;
         end
         % Return MASKED child channel infos
         chChannelInfo = getBlockChannelInfo(obj.Children,true);
      end
      
      % Get cross-condition mean for this rat
      function [xcmean,t] = getCrossCondMean(obj,align,includeStruct)
         if nargin < 2
            align = defaults.rat('align');
         end
         
         if nargin < 3
            includeStruct = defaults.rat('include');
         end
         
         if numel(obj) > 1
            xcmean = cell(numel(obj),1);
            for ii = 1:numel(obj)
               [xcmean{ii},t] = getCrossCondMean(obj(ii),align,includeStruct);
            end
            return;
         end
         
         [xcmean,t] = getSetIncludeStruct(obj,align,includeStruct);
         if isempty(xcmean)
            fprintf(1,'Missing cross-condition mean for %s: %s\n',obj.Name,...
               utils.parseIncludeStruct(includeStruct));
         end
      end
      
      % Get average coherence for mean spike rates on a given alignment to
      % the cross-day mean spike rates
      function [cxy,f,poday] = getMeanCoherence(obj,align,includeStruct)
         if nargin < 3
            includeStruct = defaults.block('include');
         end
         
         if nargin < 2
            align = defaults.block('align');
         end
         
         if numel(obj) > 1
            cxy = cell(numel(obj),1);
            poday = cell(numel(obj),1);
            for ii = 1:numel(obj)
               [cxy{ii},f,poday{ii}] = getMeanCoherence(obj(ii),align,includeStruct);
            end
            return;
         end
         
         [c,f,poday] = getMeanCoherence(obj.Children,align,includeStruct);
         cxy = zeros(numel(poday),numel(f),numel(obj.ChannelInfo));
         all_ch = 1:numel(obj.ChannelInfo);
         
         for ii = 1:numel(obj.Children)
            if isempty(c{ii})
               % Could not get coherence that day. Skip it.
               continue;
            end
            ch = all_ch(obj.ChannelMask);
            iCh = matchChannel(obj.Children(ii),ch,true);
            iremove = isnan(iCh);
            iCh(iremove) = [];
            ch(iremove) = [];
            for cc = 1:numel(iCh)
               cxy(ii,:,ch(cc)) = c{ii}(:,iCh(cc));
            end
         end
         
         obj.coh.poday = poday;
         obj.coh.f = f;
         obj.coh.xy = cxy(:,:,obj.ChannelMask);
         
      end
      
      % Get the average cross-day coherence in the range [f_lb,f_ub] for
      % post-op days in the range [poday_lb,poday_ub]
      function c = getMeanBandCoherence(obj,f_lb,f_ub,poday_lb,poday_ub)
         % Check if post-op day specified, if not use all
         if nargin < 5
            poday_lb = min(obj.coh.poday);
            poday_ub = max(obj.coh.poday);
         end
         
         % Check if frequencies are specified, if not use all
         if nargin < 3
            f_lb = min(obj.coh.f);
            f_ub = max(obj.coh.f);
         end
         
         % Range of frequencies
         freq_Idx = (obj.coh.f >= f_lb) & ...
                    (obj.coh.f <= f_ub);
                 
         % Range of post-op days
         day_Idx = (obj.coh.poday >= poday_lb) & ...
                   (obj.coh.poday <= poday_ub);
                
         % Return max coherence for each channel, relative to the total
         % average coherence on a given day, averaged across all days.
         cf = nanmax(obj.coh.xy(day_Idx,freq_Idx,:),[],2);
         ct = nanmean(obj.coh.xy(day_Idx,:,:),2);
         c = squeeze(nanmean(cf ./ ct,1));
      end
      
      % Get average rate from blocks within a post-op day range
      function [rate,t,n,iKeep] = getMeanRateByDay(obj,align,includeStruct,poDayStart,poDayStop)
         if nargin < 5
            error('Must include all 5 input arguments.');
         end
         
         if numel(obj) > 1
            rate = cell(numel(obj),1);
            tFlag = true;
            n = zeros(1,numel(obj));
            iKeep = cell(size(rate));
            for i = 1:numel(obj)
               [rate{i},ttmp,n(i),iKeep{i}] = getMeanRateByDay(obj(i),align,includeStruct,poDayStart,poDayStop);
               if (~isempty(ttmp) && tFlag)
                  t = ttmp;
                  tFlag = false;
               end
            end
            if tFlag % then t was never assigned
               t = [];
            end
            return;
         end
         
         [rate,t,n,iKeep] = getMeanRateByDay(obj.Children,align,includeStruct,poDayStart,poDayStop);         
      end
      
      % Count total number of blocks within a single RAT object, or in all
      % the RAT objects of an array.
      function n = getNumBlocks(obj)
         if numel(obj) > 1
            n = 0;
            for i = 1:numel(obj)
               n = n + getNumBlocks(obj(i));
            end
            return;
         end
         n = numel(obj.Children);
      end
      
      % Get median offset latency (ms) between two behaviors
      %     align1 : "Later" alignment   (grasp, in reach-grasp pair)
      %     align2 : "Earlier" alignment (reach, in reach-grasp pair)
      %     offset : Positive value indicates that align1 occurs after
      %                 align2
      function offset = getOffsetLatency(obj,align1,align2,outcome,pellet,mustInclude,mustExclude)         
         if nargin < 3
            align2 = defaults.block('alignment');
         end
         
         if nargin < 2
            error('Must specify a comparator alignment: (Reach, Grasp, Support, Complete)');
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
            offset = nan(getNumBlocks(obj),1);
            iStart = 1;
            for i = 1:numel(obj)
               n = getNumBlocks(obj(i));
               vec = iStart:(iStart + n - 1);
               offset(vec) = getOffsetLatency(obj(i),align1,align2,outcome,pellet,mustInclude,mustExclude);
               iStart = iStart + n;
            end
            return;
         end
         
         offset = getOffsetLatency(obj.Children,align1,align2,outcome,pellet,mustInclude,mustExclude);
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
      function out = getProp(obj,propName,fromChild)
         out = [];
         if nargin < 3
            fromChild = false;
         end
         
         if numel(obj) > 1
            for ii = 1:numel(obj)
               out = vertcat(out,getProp(obj(ii),propName,fromChild));
            end
            return;
         end

         if fromChild
            out = getProp(obj.Children,propName);
         else
            if isfield(obj.Data,propName)
               out = obj.Data.(propName);
            elseif isprop(obj,propName) && ~ismember(propName,{'Data'})
               out = obj.(propName);
            else
               if defaults.rat('verbose')
                  warning('No property ''%s'' of RAT %s. Returning BLOCK property values.',...
                     propName,obj.Name);
               end
               out = getProp(obj.Children,propName);
            end
         end

      end
      
      function T = getRateTable(obj,align,includeStruct,area)
         %GETRATETABLE  Returns table of per-trial rate trajectories
         %
         %  T = getRateTable(obj);
         %  * Note: Default behavior is to construct FULL table of
         %     alignments. Specify optional arguments in case you want to
         %     save space or speed up pulling a subset of the table.
         %
         %  T = getRateTable(obj,align,includeStruct,area);
         %
         %  -- Inputs --
         %  obj : `rat` class object
         %
         %  align :  'Reach','Grasp','Complete','Support' or cell
         %           combination of some of those options
         %  -> Default is {'Reach','Grasp'}
         %
         %  includeStruct: see: `utils.makeIncludeStruct` 
         %  -> Default (if not specified) is
         %     {utils.makeIncludeStruct({'Reach','Grasp','Complete','Outcome'},[]);
         %      utils.makeIncludeStruct({'Reach','Grasp','Complete'},{'Outcome'})}
         %
         %  area : 'RFA', 'CFA', or {'RFA','CFA'} (which areas to pull)
         %  -> Default is {'RFA','CFA'} (pulls channels from both areas)
         
         if nargin < 4
            area = {'RFA','CFA'};
         elseif ~iscell(area)
            area = {area};
         end
         
         if nargin < 3
            includeStruct = ...
             {utils.makeIncludeStruct({'Reach','Grasp','Complete','Outcome'},[]); ...
              utils.makeIncludeStruct({'Reach','Grasp','Complete'},{'Outcome'})};
         elseif ~iscell(includeStruct)
            includeStruct = {includeStruct};
         end
         
         if nargin < 2
            align = {'Reach','Grasp'};
         elseif ~iscell(align)
            align = {align};
         end
         
         if numel(obj) > 1
            T = table.empty;
            for i = 1:numel(obj)
               fprintf(1,'Parsing %s...',obj(i).Name);
               T = [T; getRateTable(obj(i),align,includeStruct,area)];
               fprintf(1,'complete\n');
            end
            return;
         end
         
         hasTime = false;
         t = [];
         
         nChild = numel(obj.Children);
         nAlign = numel(align);
         nArea = numel(area);
         nInclude = numel(includeStruct);
         
         id = strsplit(obj.Name,'-');
         id = str2double(id{end});
         
         [rat_ids,rat_names,icms_all,area_all,ml_all,align_all] = ...
            defaults.experiment(...
               'rat_id','rat',...
               'icms_opts','area_opts','ml_opts','event_opts'...
               );
         
         PostOpDay = [];
         BlockID = [];
         ML = [];
         ICMS = [];
         Area = [];
         Alignment = [];
         Rate = [];
         Probe = [];
         Channel = [];
         BehaviorData = table.empty;
         for ii = 1:nChild
            for iAlign = 1:nAlign
               for iArea = 1:nArea
                  for iInc = 1:nInclude
                     if ~hasTime
                        [rate,flag_exists,flag_isempty,t,~,...
                           b,channelInfo] = getRate(obj.Children(ii),...
                           align{iAlign},'All',area{iArea},includeStruct{iInc});
                        if flag_exists && ~flag_isempty
                           hasTime = true;
                        end
                     else
                        [rate,~,~,~,~,b,channelInfo] = getRate(obj.Children(ii),...
                              align{iAlign},'All',area{iArea},includeStruct{iInc});
                     end
                     nCh = size(rate,3);
                     nTrial = size(rate,1);
                     nRow = nTrial * nCh;
                     if nRow == 0
                        continue;
                     end
                     PostOpDay = [PostOpDay; repmat(obj.Children(ii).PostOpDay,nRow,1)];
                     BlockID = [BlockID; repmat(30*id+ii,nRow,1)];
                     ml = {channelInfo.ml};
                     ml = repmat(ml,nTrial,1);
                     ML = [ML; ml(:)];
                     icms = {channelInfo.icms};
                     icms = repmat(icms,nTrial,1);
                     ICMS = [ICMS; icms(:)];
                     channel = [channelInfo.channel];
                     channel = repmat(channel,nTrial,1);
                     Channel = [Channel; channel(:)];
                     probe = [channelInfo.probe];
                     probe = repmat(probe,nTrial,1);
                     Probe = [Probe; probe(:)];
                     trialID = b.Properties.RowNames;
                     b.Trial_ID = trialID;
                     b.Properties.RowNames = {};
                     BehaviorData = [BehaviorData; repmat(b,nCh,1)];
                     Area = [Area; repmat(area(iArea),nRow,1)];
                     Alignment = [Alignment; repmat(align(iAlign),nRow,1)];
                     % Concatenate so columns are timesteps, rows are
                     % channel/trial combinations.
                     r = permute(rate,[3 1 2]);
                     Rate = [Rate; reshape(r(:),nTrial*nCh,size(rate,2))];
                  end
               end
            end
         end
         % Get unique channel ID for each animal
         ChannelID = Channel + (Probe - 1).*16 + (32*id); 
         % Get unique probe ID for each animal
         ProbeID = Probe + 2*id; 
         AnimalID = repmat(id,numel(BlockID),1);
         AnimalID = categorical(AnimalID,rat_ids,rat_names);
         ICMS = categorical(ICMS,icms_all);
         ML = categorical(ML,ml_all);
         Area = categorical(Area,area_all);
         Alignment = categorical(Alignment,align_all);
         T = [table(AnimalID,BlockID,PostOpDay,Alignment,...
                     ML,ICMS,Area,ProbeID,Probe,ChannelID,Channel),...
               BehaviorData(:,[1:5,7,9,11]), ...
               table(Rate)];
         T.Properties.UserData = struct('t',t);
         
      end
      
      % Get or set the cross-condition mean based on align and
      % includeStruct inputs (basically a way to parse that quickly).
      [rate,t] = getSetIncludeStruct(obj,align,includeStruct,rate,t);
      
      % Return subset based on valid names of rat
      %  If 'names' is [] or 'All' then returns full array.
      %
      %  s = getSubsetByName(ratObjArray,{'RC-02','RC-05'}); % Get 2 rats
      %  s = getSubsetByName(ratObjArray,'RC-02'); % Gets one rat
      function s = getSubsetByName(obj,names)
         allNames = {obj.Name};
         idx = ismember(allNames,names);
         if sum(idx) < 1
            error('Invalid names. Check second input argument.');
         end
         s = obj(idx);
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
            icms = defaults.rat('icms');
         elseif isempty(icms)
            icms = defaults.rat('icms');
         end
         
         if nargin < 4
            area = defaults.rat('area');
         elseif isempty(area)
            area = defaults.rat('area');
         end
         
         if nargin < 3
            align = defaults.rat('align');
         elseif isempty(align)
            align = defaults.rat('align');
         end
         
         if nargin < 2
            includeStruct = defaults.rat('include');
         elseif isempty(includeStruct)
            includeStruct = defaults.rat('include');
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
            meta{i}.channelInfo = rat.cleanChannelInfo(meta{i}.channelInfo,{obj.Name});
         end
      end
      
      % Set the most-recent include and alignment
      function setAlignInclude(obj,align,includeStruct)
         if nargin < 2
            align = defaults.rat('align');
         end
         
         if nargin < 3
            includeStruct = defaults.rat('include');
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
      
      % Set "dominant" frequency for grasp-aligned successful reaches, as
      % well as corresponding (normalized) power of said frequency.
      function setDominantFreq(obj,ch,f,p)
         if nargin < 4
            error('Must specify all input arguments.');
         end
         
         if numel(obj) > 1 % Then other elements must be corresponding cell arrays
            for ii = 1:numel(obj)
               setDominantFreq(obj(ii),ch{ii},f{ii},p{ii});
            end
            return;
         end
         
         if numel(ch) ~= numel(f)
            error('ch, f, and p input arguments must have same number of elements (here: %g, %g, and %g)',...
               numel(ch),numel(f),numel(p));
         end
         if numel(ch) ~= numel(p)
            error('ch, f, and p input arguments must have same number of elements (here: %g, %g, and %g)',...
               numel(ch),numel(f),numel(p));
         end
         
         % Initialize (if empty)
         if isempty(obj.dominant)
            obj.dominant = struct('f',cell(numel(obj.ChannelInfo(obj.ChannelMask)),1),...
               'p',cell(numel(obj.ChannelInfo(obj.ChannelMask)),1));
         end
         
         % Set fields
         idx = ~isnan(ch);
         ch = ch(idx); f = f(idx); p = p(idx);
         for ii = 1:numel(ch)
            obj.dominant(ch(ii)).f = f(ii);
            obj.dominant(ch(ii)).p = p(ii);
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
      
      % Set cross condition mean for a given condition
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
               forceReset = false; % By default do not reset if all arguments are already specified
            end
         end
         
         if numel(obj) > 1
            for ii = 1:numel(obj)
               setCrossCondMean(obj(ii),align,outcome,pellet,reach,grasp,support,complete,forceReset);
            end
            return;
         end
         
         fprintf(1,'Setting cross-condition means for %s...\n',obj.Name);
         fprintf(1,'---------------------------------------------------\n');
         % Initialize RAT XCMean property if not already set
         if isempty(obj.XCMean) || forceReset
            obj.XCMean = struct;
            obj.XCMean.key = '(align).(outcome).(pellet).(reach).(grasp).(support).(complete)';
         end
         
         if forceReset
            resetXCmean(obj.Children);
         end
         
         for iA = 1:numel(align)
            for iO = 1:numel(outcome)
               for iP = 1:numel(pellet)
                  for iR = 1:numel(reach)
                     for iG = 1:numel(grasp)
                        for iS = 1:numel(support)
                           for iC = 1:numel(complete)
                              fprintf(1,'\n%s:\n',align{iA});
                              includeStruct = utils.parseIncludeStruct(outcome{iO},...
                                 pellet{iP},reach{iR},grasp{iG},...
                                 support{iS},complete{iC});   
                              obj.printCrossCondMeanStatus(includeStruct);
                              [X,t] = obj.concatChildRate_trials(align{iA},includeStruct,'Full');  
                              if isempty(X)
                                 continue;
                              end
                              xcmean = squeeze(mean(X,1));
                              obj.XCMean.(align{iA}).(outcome{iO}).(pellet{iP}).(reach{iR}).(grasp{iG}).(support{iS}).(complete{iC}) = struct;
                              obj.XCMean.(align{iA}).(outcome{iO}).(pellet{iP}).(reach{iR}).(grasp{iG}).(support{iS}).(complete{iC}).rate = xcmean;
                              obj.XCMean.(align{iA}).(outcome{iO}).(pellet{iP}).(reach{iR}).(grasp{iG}).(support{iS}).(complete{iC}).t = t;
                              setCrossCondMean(obj.Children,xcmean,t,...
                                 align{iA},outcome{iO},...
                                 pellet{iP},reach{iR},grasp{iG},...
                                 support{iS},complete{iC});  
                           end
                        end
                     end
                  end
               end
            end
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
         obj.xPC = xPC;
         setxPCs(obj.Children,xPC);
      end
      
   end
   
   % "GRAPHICS" methods
   methods (Access = public)
      % Function to add common plot axes
      ax = addToAx_PlotScoreByDay(obj,ax,do_not_modify_properties,legOpts);
      ax = basicScorePlot(obj,ax);
      
      % Function to add common plots to a panel container
      p = addToTab_PlotMarginalRateByDay(obj,p,align,includeStructPlot,includeStructMarg);
      
      % Export a movie of the evolution of some value through time, for a
      % single rat (over all the recording blocks).
      function exportSkullPlotMovie(obj,f)
         if nargin < 2
            f = [];
         end
         
         if numel(obj) > 1
            for ii = 1:numel(obj)
               exportSkullPlotMovie(obj(ii),f);
            end
            return;
         end
         
         align = defaults.rat('align');
         includeStruct = defaults.rat('include');
         
         score = getNumProp(obj.Children,'TrueScore');
         t = getNumProp(obj.Children,'PostOpDay');
         fprintf(1,'Estimating mean aligned frequency power for %s.\n',obj.Name);
         
         if isempty(f)
            pCell = getMeanAlignedFreqPower(obj.Children,align,includeStruct);
         else
            fch = obj.parentChannelArray2ChildCell(f);
            pCell = getMeanAlignedFreqPower(obj.Children,align,includeStruct,fch);
         end
         pArray = obj.childCell2ChannelArray(pCell);
         
         % q - "queried"
         tq = linspace(min(t),max(t),defaults.rat('movie_n_frames'));
         
         % Interpolate score so that there is a score value for each frame
         fprintf(1,'->\tInterpolating...\n');
         scoreq = interp1(t,score,tq,'spline'); 
         scoreq = min(max(scoreq,0),1); % Can't go below 0 or above 1 (from spline interp)
         
         % Interpolate power value so it exists for each frame
         pIdx = ~isnan(pArray);
         pq = nan(sum(obj.ChannelMask),numel(tq));
         for iCh = 1:sum(obj.ChannelMask)
            pq(iCh,:) = interp1(t(pIdx(:,iCh)),pArray(pIdx(:,iCh),iCh),tq,'spline');
         end
         
         % Rearrange order of pq to match channel ordering
         E = obj.Electrode;
         e_idx = getChannelElectrodeIndex(obj);
         pq = abs(pq(e_idx,:));
         
         % Make movie
         fig = figure('Name',obj.Name,...
            'Units','Normalized',...
            'Position',[0.3 0.3 0.175 0.4]);
         ax1 = subplot(2,1,1);
         ax1.XTick = [];
         ax1.YTick = [];
         ax1.NextPlot = 'add';
         ax2 = subplot(2,1,2);
         ax2.XLim = [1 31];
         ax2.YLim = [0 100];
         
         ratSkullObj = obj.Parent.buildRatSkullPlot(ax1);
         ratSkullObj.Name = [obj.Name ' (' obj.Parent.Name ')'];
         ratSkullObj.addScatterGroup(E.x,E.y,30,E.ICMS); % initialize
         pq_mu = nanmean(nanmean(pq,1));
         pq_sd = nanstd(nanmean(pq,1));
         sizeData = group.c2sizeData(pq,pq_mu,pq_sd);         
         MV = ratSkullObj.buildMovieFrameSequence(sizeData,scoreq,ax2,tq,t,score); % Get movie
         pname = defaults.rat('movie_loc');
         fname_str = defaults.rat('movie_fname_str');
         if isempty(f)
            fstr = 'Dominant';
         else
            fstr = sprintf('%g-Hz',f(1,1));
         end
         fname = fullfile(pname,sprintf(fname_str,obj.Name,fstr));
         if exist(pname,'dir')==0
            mkdir(pname);
         end
         
         v = VideoWriter(fname);
         v.FrameRate = defaults.rat('movie_fs');
         open(v);
         for ii = 1:size(MV,4)
            writeVideo(v,MV(:,:,:,ii));
         end
         fprintf(1,'Finished writing skull channel movie for %s.\n',obj.Name);
         close(v);
         close(fig);
         
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
      
      % Plot channelwise cross-day condition response correlations
      function fig = plotCR(obj,groupName,rc)
         if nargin < 3
            rc = 'r';
         end
         
         % Parse input
         if numel(obj) > 1
            if nargout > 0
               fig = [];
               for ii = 1:numel(obj)
                  if nargin < 2
                     groupName = obj(ii).Parent.Name;
                  end
                  fig = [fig; plotCR(obj(ii),groupName,rc)];
               end
               return;
            else
               for ii = 1:numel(obj)
                  if nargin < 2
                     groupName = obj(ii).Parent.Name;
                  end
                  plotCR(obj(ii),groupName,rc);
               end
               return;
            end
         else
            if nargin < 2
               groupName = obj.Parent.Name;
            end
         end
         
         if ~obj.HasCrossDayCorrelations
            fprintf(1,'%s: no cross-day correlations yet. Running cross-day correlations...\n',obj.Name);
            obj.getChannelResponseCorrelationsByDay(align,includeStruct);
         end
         
         % Get parameters
         xAxLoc = defaults.rat('ch_by_day_xaxisloc');
         yLim = defaults.rat('ch_by_day_ylim');
         xLim = defaults.rat('ch_by_day_xlim');         
         
         legOpts = defaults.conditionResponseCorrelations(['ch_by_day_legopts_' rc]);
         
         figName = sprintf('%s (%s): Cross-Day Response Stability',...
            obj.Name,groupName);
         fig = figure('Name',figName,...
            'Color','w',...
            'Units','Normalized',...
            'Position',defaults.rat('big_fig_pos'));
         ax = obj.createChannelAxes(fig,xLim,yLim,xAxLoc,legOpts);
         
         err_str = ['err_' rc];
         for p = 1:2
            for ch = 1:16
               iCh = ch + (p-1)*16;
               T = obj.CR((obj.CR.Probe == p) & (obj.CR.Channel == ch),:);
               if contains({obj.ChannelInfo(([obj.ChannelInfo.probe] == p) & ...
                     [obj.ChannelInfo.channel] == ch).area},'RFA')
                  col = [0 0 1];
               else
                  col = [1 0 0];
               end
               
               errorbar(ax(iCh),T.PostOpDay,T.(rc),T.(err_str)./sqrt(T.N),...
                  'LineWidth',1.5,...
                  'Color',col);
            end
         end
         
         % If no output requested, do a batch saving and closing of the
         % figure window.
         if nargout < 1
            save_path = fullfile(...
               defaults.conditionResponseCorrelations('save_path'),...
               obj.Name);
            if exist(save_path,'dir')==0
               mkdir(save_path);
            end
            
            name_str = defaults.conditionResponseCorrelations(['fname_' rc]);
            istr = utils.parseIncludeStruct(obj.RecentIncludes);
               
            fname = fullfile(save_path,sprintf(name_str,obj.Name,...
               obj.RecentAlignment,istr));
            savefig(fig,[fname '.fig']);
            saveas(fig,[fname '.png']);
            delete(fig);               
            fig = [];
         end
         
      end
      
      % Plot average daily rates against cross-day mean rates using
      % coherence
      function fig = plotMeanCoherence(obj,align,includeStruct,groupname)
         if nargin < 2
            if isempty(obj.RecentAlignment)
               align = defaults.rat('align');
            else
               align = obj.RecentAlignment;
            end
         end
         
         if nargin < 3
            if isempty(obj.RecentIncludes)
               includeStruct = defaults.rat('include');
            else
               includeStruct = obj.RecentIncludes;
            end
         end
         
         if numel(obj) > 1
            if nargout < 1
               for ii = 1:numel(obj)
                  if nargin < 4
                     plotMeanCoherence(obj(ii),align,includeStruct);
                  else
                     plotMeanCoherence(obj(ii),align,includeStruct,groupname);
                  end
               end
            else
               fig = [];
               for ii = 1:numel(obj)
                  if nargin < 4
                     fig = [fig; plotMeanCoherence(obj(ii),align,includeStruct)];
                  else
                     fig = [fig; plotMeanCoherence(obj(ii),align,includeStruct,groupname)];
                  end
               end
            end
            return;
         end
         
         if nargin < 4
            if isempty(obj.Parent)
               groupname = [];
            else
               groupname = obj.Parent.Name;
            end
         end
         
         % Get parameters
         xAxLoc = defaults.rat('ch_by_day_coh_xloc');
         yLim = defaults.rat('ch_by_day_coh_ylim');
         xLim = defaults.rat('ch_by_day_coh_xlim');         
         
         legOpts = defaults.rat('ch_by_day_legopts');
         
         figName = sprintf('%s (%s): Cross-Day Coherence',...
            obj.Name,groupname);
         fig = figure('Name',figName,...
            'Color','w',...
            'Units','Normalized',...
            'Position',defaults.rat('big_fig_pos'));
         

         % Get coherence
         [cxy,f,poday] = obj.getMeanCoherence(align,includeStruct);
         
         % Get parameters specific to certain plot types
         [~,X] = meshgrid(f,poday);
         poday_full = poday(1):poday(end);
         poday_idx = ismember(poday_full,poday);
         ptype = lower(defaults.rat('coh_plot_type'));
         if strcmp(ptype,'surface')
            [cm,nColorOpts] = defaults.load_cm(defaults.rat('cm_name'));
            icm = round(linspace(1,size(cm,1),nColorOpts));
            cm = cm(icm,:);
            CData = nan(numel(poday),numel(f),3);
            for iP = 1:numel(poday)
               tmp = reshape(cm(poday(iP),:),1,1,3);
               CData(iP,:,:) = repmat(tmp,1,numel(f),1);
            end     
         end
         if strcmp(ptype,'heatmap')
            % Swap X-Y axes for visualization purposes.
            tmp = xLim;
            xLim = yLim;
            yLim = tmp;
            xlab = defaults.rat('coh_y_lab');
            ylab = defaults.rat('coh_x_lab');
         else
            ylab = defaults.rat('coh_y_lab');
            xlab = defaults.rat('coh_x_lab');
         end
         
         ax = obj.createChannelAxes(fig,xLim,yLim,xAxLoc,legOpts);
         
         chIdx = 0; %#ok<NASGU>
         axLabFlag = false;
         for p = 1:2
            for ch = 1:16
               iCh = ch + (p-1)*16;
               Y = cxy(:,:,iCh);
               switch(ptype)
                  case 'ribbon'
                     ribbon(ax(iCh),X,Y);
                     set(ax(iCh),'ZLim',defaults.rat('ch_by_day_coh_zlim'));
                  case 'waterfall'
                     waterfall(ax(iCh),f,poday,Y);
                     set(ax(iCh),'YDir','reverse');
                     set(ax(iCh),'ZLim',defaults.rat('ch_by_day_coh_zlim'));
                  case 'surface'
                     surface(ax(iCh),f,poday,Y,...
                        'EdgeColor','none',...
                        'FaceAlpha',0.95,...
                        'FaceColor','interp',...
                        'CData',CData);
                     ax(iCh).View = defaults.rat('coh_ax_angle');
                     set(ax(iCh),'ZLim',defaults.rat('ch_by_day_coh_zlim'));
                  case 'heatmap'
                     Z = zeros(numel(poday_full),numel(f));
                     Z(poday_idx,:) = Y;
                     h = pcolor(ax(iCh),poday_full,f,Z.');
                     set(h,'EdgeColor','none');
                     set(ax(iCh),'XLim',[poday(1)-1,poday(end)+1]);
                     set(ax(iCh),'CLim',[1e-3,1]);
                     colormap(ax(iCh),defaults.load_cm('mod_zscore'));
                  otherwise
                     fprintf(1,'''%s'' coh_plot_type parameter not recognized. Using ribbon instead.\n',ptype);
                     ribbon(ax(iCh),X,Y);
               end
               
               if (~axLabFlag) && (obj.ChannelMask(iCh))
                  ylabel(ax(iCh),ylab,'FontName','Arial','Color','k');
                  xlabel(ax(iCh),xlab,'FontName','Arial','Color','k');
                  axLabFlag = true;
               end
            end
         end
         
         % If no output requested, do a batch saving and closing of the
         % figure window.
         if nargout < 1
            save_path = fullfile(...
               defaults.conditionResponseCorrelations('save_path'),...
               obj.Name);
            if exist(save_path,'dir')==0
               mkdir(save_path);
            end
            
            name_str = defaults.rat('coh_fig_fname');
            istr = utils.parseIncludeStruct(includeStruct);
            fname = fullfile(save_path,sprintf(name_str,obj.Name,align,istr));
            savefig(fig,[fname '.fig']);
            saveas(fig,[fname '.png']);
            delete(fig);               
            fig = [];
         end
      end
      
      % Plot rate averages across days for all channels
      % Note that 'outcome' input argument can be specified as
      % "includeStruct" format, to parse averages differently
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
          
         % Add this part to handle "includeStruct" input formatting for
         % 'outcome' parameter
         if isstruct(outcome)
            includeStruct = outcome; % To keep it less-confusing
            str = utils.parseIncludeStruct(includeStruct);
            tmp = strsplit(str,'-');
            outcome = tmp{1};
            fig_str = sprintf('%s-%s: %s Normalized Average Rates',obj.Name,align,str);
            save_str = sprintf('%s_%s__%s__Average-Normalized-Spike-Rates',obj.Name,align,str);
            [pp,ff,ff2] = defaults.files('local_tank','norm_avg_fig_dir','norm_includestruct_fig_dir');
            norm_avg_fig_dir = fullfile(pp,ff,ff2);
         else
            includeStruct = nan;
            fig_str = sprintf('%s: %s-%s Normalized Average Rates',obj.Name,align,outcome);
            save_str = sprintf('%s_%s-%s_Average-Normalized-Spike-Rates',obj.Name,align,outcome);
            [pp,ff] = defaults.files('local_tank','norm_avg_fig_dir');
            norm_avg_fig_dir = fullfile(pp,ff);
         end
         
         fprintf(1,'-->\tPlotting: %s\n',fig_str);
         
         fig = figure('Name',...
                  fig_str,...
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
         
         % Shift legend axes over a little bit and make it wider while
         % squishing it slightly in the vertical direction:
         p = ax(legPlot).Position;
         ax(legPlot).Position = p + [-2.75 * p(3),  0.33 * p(4),...
                                      2.5 * p(3), -0.33 * p(4)];
         obj.chMod = zeros(nDays,1);
         for ii = 1:nDays
            % Superimpose FILTERED rate traces on the channel axes
            if isstruct(includeStruct)
               [rate,t,~,flag] = getMeanRate(obj.Children(ii),align,includeStruct,'Full',true);
               % Skip this day if no data
               if ~flag
                  continue;
               end
               
               x = nan(numel(obj.ChannelInfo),numel(t));
               x(find(obj.Children(ii).ChannelMask),:) = rate.'; %#ok<*FNDSB> % Make consistent orientation

            else
               [x,~,t] = getAvgNormRate(obj.Children(ii),align,outcome,nan,true);
               % Skip this day if no data
               if isempty(t)
                  continue;
               end
            end         

            % For each post-operative day, plot each channel in the
            % recording with the correct color
            poDay = obj.Children(ii).PostOpDay;  
            
            % Restrict timepoints of interest to region around the peak
            % (for estimating channel modulations for index)
            tss = defaults.rat('ch_mod_epoch_start_stop');
            t_idx = (t >= tss(1)) & (t <= tss(2));
            % Get average "peak modulation" across channels for the legend
            obj.chMod(ii) = nanmean(nanmax(x(:,t_idx),[],2) -...
                                    nanmin(x(:,t_idx),[],2));
            for iCh = 1:nAxes  
               ch = obj.Children(ii).matchChannel(iCh);
               if isempty(ch)
                  continue;
               end
               if obj.Children(ii).nTrialRecent.rate < 10
                  plot(ax(iCh),t,x(ch,:),...                   
                     'Color',cm(idx(poDay),:),...  % color by day
                     'LineWidth',0.75,...
                     'LineStyle',':',...
                     'UserData',[iCh,ii]);
               else
                  plot(ax(iCh),t,x(ch,:),...                   
                     'Color',cm(idx(poDay),:),...  % color by day
                     'LineWidth',2.25-(poDay/numel(idx)),...
                     'UserData',[iCh,ii]);
               end
            end
         end
         
         % Make "score by day" plot
%          obj.addToAx_PlotScoreByDay(ax(legPlot));
         basicScorePlot(obj,ax(legPlot));
         
         if nargout < 1
            if exist(norm_avg_fig_dir,'dir')==0
               mkdir(norm_avg_fig_dir);
            end
            savefig(fig,fullfile(norm_avg_fig_dir,...
               sprintf('%s.fig',save_str)));
            saveas(fig,fullfile(norm_avg_fig_dir,...
               sprintf('%s.png',save_str)));
            delete(fig);
         end
         
      end
      
      % Plot the PC Fit coefficient values for channels through time (day)
      function fig = plotPCFit(obj)
         if numel(obj) > 1
            fig = [];
            for ii = 1:numel(obj)
               fig = [fig; plotPCFit(obj(ii))];
            end
            return;
         end
         
         fig = figure('Name',sprintf('%s - PC Fit by Day',obj.Name),...
            'Units','Normalized',...
            'Color','w',...
            'Position',defaults.rat('big_fig_pos'));
         
         [A,~,poday] = getChannelPCFits(obj);
         irm = isnan(poday);
         A(:,:,irm) = [];
         poday(irm) = [];
         
         % Get parameters
         xAxLoc = defaults.rat('ch_by_day_coh_xloc');
         yLim = [-0.4 0.4];
         xLim = defaults.rat('ch_by_day_coh_ylim');         
         
         legOpts = defaults.rat('ch_by_day_legopts');
         ax = obj.createChannelAxes(fig,xLim,yLim,xAxLoc,legOpts);
         
         % Parse parameters for coloring lines, smoothing plots
         [cm,nColorOpts] = defaults.load_cm;
         idx = round(linspace(1,size(cm,1),nColorOpts)); 
         
%          offset = (1:size(A,2)).' * 0.20;
%          c = [1 0 0; 0 1 0; 0 0 1; 1 0 1; 1 1 0; 0 1 1];
%          cd = nan(size(A,2)*numel(poday),3);
%          vec = 1:numel(poday);
%          for ii = 1:size(A,2)
%             cd(vec,:) = repmat(c(ii,:),numel(poday),1);
%             vec = vec + numel(poday);
%          end
%          
         chIdx = 0; %#ok<NASGU>
         axLabFlag = false;
         for iPC = 1:size(A,2)
            for p = 1:2
               for ch = 1:16
                  iCh = ch + (p-1)*16;
   %                x = (repmat(poday.',size(A,2),1)).';               
   %                y = (squeeze(A(iCh,:,:)) + offset).';


   %                scatter(ax(iCh),x(:),y(:),...
   %                   'FaceColor','flat',...
   %                   'CData',cd);

                  scatter(ax(iCh),poday,squeeze(A(iCh,iPC,:)),...
                     'FaceColor','flat',...
                     'CData',cm(idx(poday),:));

                  set(ax(iCh),'YTick',[]);


                  if (~axLabFlag) && (obj.ChannelMask(iCh))
                     ylabel(ax(iCh),sprintf('PC-%g Coeff',iPC),'FontName','Arial','Color','k');
                     xlabel(ax(iCh),'PO-Day','FontName','Arial','Color','k');
                     axLabFlag = true;
                  end
               end
            end
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
      
   end
   
   % Private methods used by other methods
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
      
      % Create "channel" axes
      function ax = createChannelAxes(obj,p,xLim,yLim,xAxLoc,legOpts)
         if nargin < 6
            legOpts = defaults.rat('ch_by_day_legopts');
         end
         
         if nargin < 5
            xAxLoc = defaults.rat('ch_by_day_xaxisloc');
         end
         
         if nargin < 4
            yLim = defaults.rat('ch_by_day_ylim');
         end
         
         if nargin < 3
            xLim = defaults.rat('ch_by_day_xlim');
         end
         
         % 32 channels at least, plus "spare" space
         ax = uiPanelizeAxes(p,35);
         
         % Remove 2 axes and scrunch the other one over to fill the space
         delete(ax(33));
         delete(ax(34));
         pos = ax(35).Position;
         ax(35).Position = pos + [-2.75 * pos(3), 0.33 * pos(4),...
            2.5 * pos(3), -0.33 * pos(4)];
         
         % Set properties of the other axes
         ax(1:32) = obj.createRateAxes(obj.ChannelMask,obj.ChannelInfo,ax(1:32),...
            xLim,yLim,xAxLoc);         
         ax(35) = addToAx_PlotScoreByDay(obj,ax(35),false,legOpts);
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
      
      % Update "channel modulation" if it is not present
      function updateChMod(obj,align,outcome)
         if nargin < 3
            outcome = defaults.block('outcome');
         end
         
         if nargin < 2
            align = defaults.block('alignment');
         end
         
         obj.chMod = zeros(numel(obj.Children),1);
         for ii = 1:numel(obj.Children)
            % Superimpose FILTERED rate traces on the channel axes
            [x,~,t] = getAvgNormRate(obj.Children(ii),align,outcome);
            if isempty(t)
               continue;
            end    
            tss = defaults.jPCA('jpca_start_stop_times');
            t_idx = (t >= tss(1)) & (t <= tss(2));
            % Get average "peak modulation" across channels for the legend
            obj.chMod(ii) = nanmean(max(x(:,t_idx),[],2) -...
                                    min(x(:,t_idx),[],2));
         end
      end
      
   end
   
   % Static methods used by other methods
   methods (Static = true, Access = public)
      % Brings up the dialog box for selecting path to rat
      function path = uiPathDialog()
         path = uigetdir('P:\Extracted_Data_To_Move\Rat\TDTRat',...
            'Select RAT folder');
      end
      
      % Static method to "clean" channelInfo struct
      function channelInfo = cleanChannelInfo(channelInfo,Name)
         channelInfo = utils.addStructField(channelInfo,Name);
         channelInfo = rmfield(channelInfo,'file');
         channelInfo = orderfields(channelInfo,[6,1:5]);
         for k = 1:numel(channelInfo)
            channelInfo(k).area = channelInfo(k).area((end-2):end);
         end
      end
      
      % Sets properties for a given axes for plotting rates
      function ax = createRateAxes(channelmask,channelinfo,ax,xLim,yLim,xAxLoc)
         % Parse inputs
         if nargin < 3
            ax = gca;
         end
         
         if nargin < 4
            xLim = defaults.rat('x_lim_norm');
         end
         
         if nargin < 5
            yLim = defaults.rat('y_lim_norm');
         end
         
         if nargin < 6
            xAxLoc = 'bottom'; % typical default
         end
         
         % Handle axes array
         if numel(ax) > 1
            if (numel(channelmask) == numel(channelinfo)) && ...
                  (numel(channelmask) == numel(ax))
               for ii = 1:numel(ax)
                  ax(ii) = rat.createRateAxes(channelmask(ii),channelinfo(ii),ax(ii),...
                     xLim,yLim,xAxLoc);
               end
            else
               error('For array inputs, provide full ChannelMask and ChannelInfo arrays as well.');
            end
            return;
         end
         
         % Set the axes properties appropriately         
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
         ax.XAxisLocation = xAxLoc;
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
      
      % Prints the current status of the cross-condition mean estimation
      function printCrossCondMeanStatus(includeStruct)
         fprintf(1,'-->\tInclude: ');
         if isempty(includeStruct.Include)
            fprintf(1,'none\n');
         else
            for ii = 1:numel(includeStruct.Include)
               fprintf(1,'%s ',includeStruct.Include{ii});
            end
            fprintf(1,'\n');
         end
         fprintf(1,'-->\tExclude: ');
         if isempty(includeStruct.Exclude)
            fprintf(1,'none\n');
         else
            for ii = 1:numel(includeStruct.Exclude)
               fprintf(1,'%s ',includeStruct.Exclude{ii});
            end
            fprintf(1,'\n');
         end
      end
   end
   
end

