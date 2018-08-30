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
   end

   properties(SetAccess = private, GetAccess = private)
      
      behaviorData % Table to keep track of all behavior scoring
      
      N            % Total number of trials
      K            % Number of variables
      
      panel % Panel for holding graphics objects
      
      % Graphics
      ScoringTracker_ax;   % Axes for scoring tracker image/line
      ScoringTracker_im;   % Image for overall trial progress bar
      ScoringTracker_line; % Overlay line for current trial indicator
      trialPop;            % Popupmenu for selecting trial
      editArray;           % Cell array of handles to edit boxes
   end
   
%% Events
   events % These correspond to different scoring events
      update   % When a value is modified during scoring
      newTrial % Switch to a new trial ("row" of behaviorData)
   end
   
%% Methods
   methods (Access = public)
      % Construct the object for keeping track of which "button press" (or
      % trial) we are currently looking at
      function obj = behaviorInfo(figH,behaviorData)
         obj.parent = figH;
         obj.updateBehaviorData(behaviorData);
      end
      
      % Update behaviorData and add variable names property
      function updateBehaviorData(obj,behaviorData)
         obj.behaviorData = behaviorData;
         obj.N = size(behaviorData,1);
         obj.K = size(behaviorData,2);
         vnames = obj.behaviorData.Properties.VariableNames;
         vnames = reshape(vnames,1,numel(vnames));
         obj.varName = vnames;
      end
      
      % Set the current trial button and emit notification about the event
      function setTrial(obj,newTrial)
         
         if (newTrial ~= obj.currentTrial) && ...
            (newTrial > 0) && ...
            (newTrial <= obj.N)
            
            obj.currentTrial = newTrial;
            notify(obj,'newTrial');
            
         end
      end
      
      % Set the associated value and notify
      function setValue(obj,idx,val)
         obj.varVal(idx) = val;
         notify('update');
      end
      
      % Returns the current trial index
      function trial = getTrial(obj)
         trial = obj.currentTrial;
      end
      
      % Increment the idx property by 1 and return false if out of range
      function flag = stepIdx(obj)
         obj.idx = obj.idx + 1;
         flag = obj.idx <= obj.K;
         if ~flag
            obj.idx = 1;
         end            
      end
      
      % Returns a struct of handles to graphics objects
      function graphics = getGraphics(obj)
         graphics = struct('trialTracker_display',obj.ScoringTracker_im,...
            'trialTracker_displayOverlay',obj.ScoringTracker_line,...
            'trialPopup_display',obj.trialPop,...
            'editArray_display',obj.editArray);
      end
      
      % Construct the scoring progress tracker graphics objects
      function buildProgressTracker(obj,container)
         % Create tracker and set all to red to start
         C = zeros(1,size(obj.behaviorData,1),3);
         C(1,:,1) = 1;
         x = [0 1];
         y = [0 1];
         
         obj.ScoringTracker_ax = axes(container,'Units','Normalized',...
            'Position',[0.025 0.1 0.95 0.25],...
            'NextPlot','replacechildren',...
            'XLim',[0 1],...
            'YLim',[0 1],...
            'XLimMode','manual',...
            'YLimMode','manual',...
            'YDir','reverse',...
            'XTick',[],...
            'YTick',[]);
         
         obj.ScoringTracker_im = image(obj.ScoringTracker_ax,x,y,C);
         obj.ScoringTracker_line = line(obj.ScoringTracker_ax,[0 0],[0 1],...
            'LineWidth',2,...
            'Color',[0 0.7 0],...
            'LineStyle',':');
         
      end
      
      % Construct the video controller graphics objects for scoring
      function buildVideoControPanel(obj)
         % Panel with controls for setting behavior & manipulating video
         obj.panel = uipanel(obj.parent,...
            'Units','Normalized',...
            'BackgroundColor','k',...
            'Position',[0.76 0.01 0.23 0.48]);

         
         % Make text labels for controls
         labs = reshape(obj.varName,numel(obj.varName),1);
         yPos = makeLabels(obj.panel,labs);
         
         % Make controller for switching between trials
         str = cellstr(num2str(obj.behaviorData.(obj.varName{1})));
         str = cellfun(@(x) strrep(x,' ',''),str,'UniformOutput',false); % This makes it look nicer
         obj.trialPop = uicontrol(obj.panel,'Style','popupmenu',...
            'Units','Normalized',...
            'Position',[0.5 yPos(1) 0.475 0.15],...
            'FontName','Arial',...
            'FontSize',14,...
            'String',str,...
            'UserData',obj.behaviorData.(obj.varName{1}));
         
         obj.editArray = uiMakeEditArray(container,yPos(2:end));
      end
   
   end

end