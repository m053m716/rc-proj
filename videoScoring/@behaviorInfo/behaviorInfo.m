classdef behaviorInfo < handle
%% BEHAVIORINFO  Class to update HUD & track button information

%% Properties 
   properties(SetAccess = private, GetAccess = public)
      vidInfo
      
      graspTime
      reachTime
      buttonTime
      handUsed
      trialOutcome
   end

   properties(SetAccess = private, GetAccess = private)
      maxButton
      
      currentButton = 0;
   end
   
%% Events
   events % These correspond to different scoring events
      grasp
      reach
      button
      hand
      outcome
   end
   
%% Methods
   methods (Access = public)
      % Construct the object for keeping track of which "button press" (or
      % trial) we are currently looking at
      function obj = buttonInfo(curButton,maxbutton,vidInfo_obj)
         obj.currentButton = curButton;
         obj.maxButton = maxbutton; 
         obj.vidInfo = vidInfo_obj;
         
         obj.setButton(curButton);
      end
      
      % Set the current trial button and emit notification about the event
      function setButton(obj,newButton)
         
         if (newButton ~= obj.currentButton) && ...
            (newButton > 0) && ...
            (newButton <= obj.maxButton)
            
            
            obj.currentButton = newButton;
            notify(obj,'button');
            
         end
      end
      
      % Set the trial reach time and emit a notification about the event
      function setReachTime(obj,reach_t)
         
         obj.reachTime = reach_t;
         notify(obj,'reach');
         
      end
      
      % Set the trial grasp time and emit a notification about the event
      function setGraspTime(obj,grasp_t)
         
         obj.graspTime = grasp_t;
         notify(obj,'grasp');

      end
      
      % Set the trial hand and emit a notification about the event
      function setHandedness(obj,hand_used)
         obj.handUsed = hand_used;
         notify(obj,'hand');
      end
      
      % Set the trial outcome and emit a notification about the event
      function setOutcome(obj,trial_outcome)
         obj.trialOutcome = trial_outcome;
         notify(obj,'outcome');
      end
      
      function trial = getTrial(obj)
         trial = obj.currentButton;
      end
   
   end

end