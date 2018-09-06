classdef behaviorInfo < handle
%% BEHAVIORINFO  Class to update HUD & track button information

%% Properties 
   properties(SetAccess = private, GetAccess = public)
      parent  % Figure handle of parent
      
      varVal            % 1 x k vector of scalar values for a single trial
      varType           % 1 x k vector of scalar indicators of varVal type
      varName           % 1 x k label vector
      
      idx = 1;          % Current variable being updated
      cur = 1;          % Index of current trial for alignment
      N                 % Total number of trials
      
      % Info about alignment
      VideoStart = 0; % Default to 0 offset
      Trials            
      
      behaviorData % Table to keep track of all behavior scoring
      
      % Input files
      vectors           % File struct for data streams
      scalars           % File struct for scalar values
      tables            % File struct for table input/output
      
      
   end

   properties(SetAccess = private, GetAccess = private)
      % Constants
      TRIAL_OFFSET = -0.25; % Time before "trial" to offset
      
      % Info about the behaviorData table
      K            % Number of variables
      
      % Graphics
      panel % Panel for holding graphics objects
      conPanel             % Panel for holding controls
      trkPanel             % Panel for tracking progress
      ScoringTracker_ax;   % Axes for scoring tracker image/line
      ScoringTracker_im;   % Image for overall trial progress bar
      ScoringTracker_line; % Overlay line for current trial indicator
      ScoringTracker_lab;  % Title of progress tracker indicator
      trialPop;            % Popupmenu for selecting trial
      editArray;           % Cell array of handles to edit boxes
   end
   
%% Events
   events % These correspond to different scoring events
      update   % When a value is modified during scoring
      newTrial % Switch to a new trial ("row" of behaviorData)
      load     % When a behavior file is loaded
      saveFile % When file is saved
   end
   
%% Methods
   methods (Access = public)
      % Construct the behaviorInfo object
      function obj = behaviorInfo(figH,F,vname,container)
         obj.parent = figH;
         obj.loadData(F);
         
         % Create behaviorData table
         if ~isempty(obj.behaviorData)
            obj.updateBehaviorData;
         elseif nargin > 2
            obj.makeBehaviorData(vname);
         else
            warning('behaviorData table not initialized.');
         end
         
         % Build graphics
         if exist('container','var')==0
            obj.buildContainer;
         else
            obj.buildContainer(container);
         end
         obj.buildVideoControlPanel;
         obj.buildProgressTracker;
         
         
      end
      
      % Loads all datapoints from associated data files
      function loadData(obj,F)
         vname = fieldnames(F);
         for ii = 1:numel(vname)
            if ismember(vname{ii},properties(obj))
               obj.(vname{ii}) = F.(vname{ii});
            end
         end
         obj.parseFiles;
      end
      
      % Create behaviorData and update associated values
      function makeBehaviorData(obj,vname)
         tmp = table(obj.Trials,'VariableNames',vname(1));
         for ii = 2:numel(vname)
            tmp = [tmp, ...
               table(nan(size(obj.Trials)),...
                  'VariableNames',vname(ii))]; %#ok<AGROW>
         end
         obj.behaviorData = tmp;
         obj.updateBehaviorData;
      end
      
      % Update behaviorData and add variable names property
      function updateBehaviorData(obj)
         obj.N = size(obj.behaviorData,1);
         obj.K = size(obj.behaviorData,2);
         vname = obj.behaviorData.Properties.VariableNames;
         vname = reshape(vname,1,numel(vname));
         obj.varName = vname;
         
         % In case there is a dimension mismatch from previous deletions
         obj.Trials = table2array(obj.behaviorData(:,1));
      end
      
      % Set the current trial button and emit notification about the event
      function setTrial(obj,src,newTrial,reset)
         % Give option of sending in a uiControl object and getting value
         % for the new trial
         if isa(src,'matlab.ui.control.UIControl')
            newTrial = src.Value;
         end
         
         % Add a "reset" arg that can be used in specific instances where
         % we WANT to reset the trial based on having the same index (for
         % example, after a trial deletion).
         if exist('reset','var')==0
            reset = false;
         end
         
         % Or just using newTrial as extra input argument
         if ((newTrial ~= obj.cur) && ...
            (newTrial > 0) && ...
            (newTrial <= obj.N) || reset)
            
            obj.idx = 1;  % reset index to 1 for checking graphics
            obj.cur = newTrial;
            obj.varVal = table2array(obj.behaviorData(obj.cur,:));
            notify(obj,'newTrial');
            
         end
      end
      
      % Remove this trial (if it is an invalid trial)
      function removeTrial(obj)
         % Remove entry from list
         obj.behaviorData(obj.cur,:) = [];
         obj.Trials(obj.cur) = [];
         obj.trialPop.String(obj.cur) = []; 
         obj.ScoringTracker_im.CData(:,obj.cur,:) = [];
         
         obj.N = obj.N - 1;
         if obj.N > 0
            obj.cur = min(obj.cur,obj.N); % Make sure you don't go over
            obj.setTrial(nan,obj.cur,true);          
         else
            delete(gcf);
            warning('No valid trials for this video!');
         end
      end
      
      % Set the associated value and notify
      function setValue(obj,idx,val)
         obj.varVal(idx) = val;
         obj.idx = idx;
         notify(obj,'update');
      end
      
      % Set all associated values
      function setValueAll(obj,idx,val)
         vec = 1:obj.N;
         obj.varVal(idx) = val;
         obj.idx = idx;
         notify(obj,'update'); % Update first to display it
         obj.behaviorData.(obj.varName{obj.idx})(:) = val;
      end
      
      % Add or remove the grasp time for this trial
      function varState = addRemoveValue(obj,val)
         if obj.idx == 1 % Don't modify trial onset guesses
            varState = true;
            return;
         end
         
         if obj.behaviorData.(obj.varName{obj.idx})(obj.cur)==val
            obj.behaviorData.(obj.varName{obj.idx})(obj.cur) = nan;
            varState = false;
         else
            obj.behaviorData.(obj.varName{obj.idx})(obj.cur) = val;
            varState = true;
         end        
      end
      
      % Increment the idx property by 1 and return false if out of range
      function flag = stepIdx(obj)
         obj.idx = obj.idx + 1;
         flag = obj.idx <= obj.K;
         if ~flag
            obj.idx = 2;
         end            
      end
      
      % Returns a struct of handles to graphics objects
      function graphics = getGraphics(obj)
         graphics = struct('trialTracker_display',obj.ScoringTracker_im,...
            'trialTracker_displayOverlay',obj.ScoringTracker_line,...
            'trialTracker_label',obj.ScoringTracker_lab,...
            'trialPopup_display',obj.trialPop,...
            'editArray_display',{obj.editArray},...
            'behavior_panel',obj.panel,...
            'behavior_conPanel',obj.conPanel,...
            'behavior_trkPanel',obj.trkPanel);
      end
            
      function saveScoring(obj)
         fname = fullfile(obj.tables.behaviorData.folder,...
            obj.tables.behaviorData.name);
         fprintf(1,'Saving %s...',obj.tables.behaviorData.name);
         behaviorData = obj.behaviorData; %#ok<PROP>
         save(fname,'behaviorData','-v7.3');
         notify(obj,'saveFile');
         fprintf(1,'complete.\n');
      end
   
   end

   methods (Access = private)
            % Build panel that contains graphics for this object
      function buildContainer(obj,container)
         if exist('container','var')==0 
            obj.panel = uipanel(obj.parent,...
               'Units','Normalized',...
               'BackgroundColor','k',...
               'Position',[0.75 0 0.25 1]);
         else
            obj.panel = container;
         end
      end
      
      % Construct the scoring progress tracker graphics objects
      function buildProgressTracker(obj)
         % Create tracker and set all to red to start
         C = zeros(1,size(obj.behaviorData,1),3);
         C(1,1:(obj.cur-1),3) = 1; % Set already-scored trials to blue
         C(1,obj.cur:obj.N,1) = 1; % set unscored trials to red
         x = [0 1];
         y = [0 1];
         
         % Put these things into a separate panel
         obj.trkPanel = uipanel(obj.panel,...
            'Units','Normalized',...
            'BackgroundColor','k',...
            'Position',[0 0.75 1 0.25]);
         
         % Create axes that will display "progress" image
         obj.ScoringTracker_ax = axes(obj.trkPanel,...
            'Units','Normalized',...
            'Position',[0.025 0.025 0.95 0.725],...
            'NextPlot','replacechildren',...
            'XLim',[0 1],...
            'YLim',[0 1],...
            'XLimMode','manual',...
            'YLimMode','manual',...
            'YDir','reverse',...
            'XTick',[],...
            'YTick',[],...
            'XColor','k',...
            'YColor','k');
         
         obj.ScoringTracker_lab = annotation(obj.trkPanel, ...
            'textbox',[0.025 0.825 0.95 0.15],...
            'Units', 'Normalized', ...
            'Position', [0.025 0.825 0.95 0.15], ...
            'FontName','Arial',...
            'FontSize',24,...
            'FontWeight','bold',...
            'Color','w',...
            'String','Progress Indicator');
         
         % Make the progress image and an overlay line to indicate 
         % current trial.
         obj.ScoringTracker_im = image(obj.ScoringTracker_ax,x,y,C);
         obj.ScoringTracker_line = line(obj.ScoringTracker_ax,[0 0],[0 1],...
            'LineWidth',2,...
            'Color',[0 0.7 0],...
            'LineStyle',':');
         
      end
      
      % Construct the video controller graphics objects for scoring
      function buildVideoControlPanel(obj)
         
         % Need a panel to separate this stuff from other
         obj.conPanel = uipanel(obj.panel,...
            'Units','Normalized',...
            'BackgroundColor','k',...
            'Position',[0 0 1 0.75]);
         
         % Make text labels for controls
         labs = reshape(obj.varName,numel(obj.varName),1);
         yPos = uiMakeLabels(obj.conPanel,labs);
         
         % Make controller for switching between trials
         str = cellstr(num2str(obj.behaviorData.(obj.varName{1})));
         % This makes it look nicer:
         str = cellfun(@(x) strrep(x,' ',''),str,'UniformOutput',false); 
         
         % Make box for selecting current trial
         obj.trialPop = uicontrol(obj.conPanel,'Style','popupmenu',...
            'Units','Normalized',...
            'Position',[0.5 yPos(1) 0.475 0.15],...
            'FontName','Arial',...
            'FontSize',14,...
            'String',str,...
            'UserData',obj.behaviorData.(obj.varName{1}),...
            'Callback',@obj.setTrial);
         
         % Make "disabled" edit boxes to display trial scoring data
         obj.editArray = uiMakeEditArray(obj.conPanel,yPos(2:end));
      end
      
      % Parse input from different file structs
      function parseFiles(obj)
         % First, load VideoStart (if it exists)
         obj.parseScalars;
         
         % Next, load trials
         obj.parseVectors;
         
         % Shift trials by the desired offset to facilitate scoring
         obj.Trials = obj.Trials + obj.TRIAL_OFFSET;
         
         % Last, load behaviorData table (if it exists - continue scoring)
         obj.parseTables;
         if ~isempty(obj.behaviorData) % If it exists, pick up where stopped
            obj.cur = obj.findNextToScore;
         end
         
         notify(obj,'load');
         
      end
      
      % Parse input from scalar file
      function parseScalars(obj)
         f = obj.scalars;
         vname = fieldnames(f);
         for iV = 1:numel(vname)
            if ismember(vname{iV},properties(obj))
               obj.(vname{iV}) = loadScalar(f.(vname{iV}));           
            end
         end
      end
      
      % Parse input from vector file
      function parseVectors(obj)
         f = obj.vectors;
         vname = fieldnames(f);
         for iV = 1:numel(vname)
            if ismember(vname{iV},properties(obj))
               obj.(vname{iV}) = loadVector(f.(vname{iV}));           
            end
         end
      end
      
      % Parse input from Table file
      function parseTables(obj)
         f = obj.tables;
         vname = fieldnames(f);
         for iV = 1:numel(vname)
            if ismember(vname{iV},properties(obj))
               obj.(vname{iV}) = loadTable(f.(vname{iV}));           
            end
         end
      end
      
      % Find next trial to score, if loading a previous session
      function nextTrial = findNextToScore(obj)
         X = table2array(obj.behaviorData(:,2:end));
         nextTrial = find(any(isnan(X),2),1,'first');
         
         % If it can't find any NaN entries, its already been fully scored.
         % Default to final trial to indicate that.
         if isempty(nextTrial)
            nextTrial = size(obj.behaviorData,1);
         end
      end
      
   end
   
end