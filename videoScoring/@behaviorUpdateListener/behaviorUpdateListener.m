classdef behaviorUpdateListener < handle
%% BEHAVIORUPDATELISTENER    Class to update video scoring UI on update for a given behavioral event
   

   properties (SetAccess = private, GetAccess = public)
      behaviorData % Table to keep track of all scoring
   end
   
   properties (SetAccess = private, GetAccess = private)
      % Graphics object display handles
      buttonTracker_display
      buttonTracker_displayOverlay
      buttonPopup_display
      reachEdit_display
      graspEdit_display
      forelimbEdit_display
      outcomeEdit_display
      
      % State variables for updating the "progress tracker" for each trial
      graspState = false
      reachState = false
      outcomeState = false
      forelimbState = false
   end

   methods
      % Create the listener object and add listeners for each kind of event
      function obj = behaviorUpdateListener(buttonInfo_obj,behaviorData_table,buttonTracker_obj,buttonTracker_line,buttonPopup_obj,reachEdit_obj,graspEdit_obj,handEdit_obj,outcomeEdit_obj)
         obj.behaviorData = behaviorData_table;
         obj.buttonTracker_display = buttonTracker_obj;
         obj.buttonTracker_displayOverlay = buttonTracker_line;
         obj.buttonPopup_display = buttonPopup_obj;
         obj.reachEdit_display = reachEdit_obj;
         obj.graspEdit_display = graspEdit_obj;
         obj.forelimbEdit_display = handEdit_obj;
         obj.outcomeEdit_display = outcomeEdit_obj;
         
         addlistener(buttonInfo_obj,...
            'button',@obj.updateButton);
         
         addlistener(buttonInfo_obj,...
            'grasp',@obj.addRemoveGrasp);
         
         addlistener(buttonInfo_obj,...
            'reach',@obj.addRemoveReach);
         
         addlistener(buttonInfo_obj,...
            'hand',@obj.updateHand);
         
         addlistener(buttonInfo_obj,...
            'outcome',@obj.updateOutcome);
      end
      
      % Update which "button push" is used, which is basically a different 
      % way of saying go to a new trial, since each button push defines a
      % trial in this case.
      function updateButton(obj,src,~)
         obj.graspState = ~isnan(obj.behaviorData.Grasp(src.getTrial));
         obj.reachState = ~isnan(obj.behaviorData.Reach(src.getTrial));
         
         obj.outcomeState = ~isnan(obj.behaviorData.Outcome(src.getTrial));
         obj.forelimbState = ~strcmp(obj.behaviorData.Forelimb(src.getTrial),'?');
         
         if obj.reachState && ~isinf(obj.behaviorData.Reach(src.getTrial))
            t = src.vidInfo.getVidTime(...
               obj.behaviorData.Reach(src.getTrial));
            src.vidInfo.setVidTime(t);
         elseif obj.graspState && ~isinf(obj.behaviorData.Grasp(src.getTrial))
            t = src.vidInfo.getVidTime(...
               obj.behaviorData.Grasp(src.getTrial));
            src.vidInfo.setVidTime(t);
         else
            t = src.vidInfo.getVidTime(...
               obj.behaviorData.Button(src.getTrial));
            src.vidInfo.setVidTime(t);
         end
         
         obj.updateGraspEdit(src.getTrial,src.vidInfo);
         obj.updateReachEdit(src.getTrial,src.vidInfo);
         obj.updateOutcomeEdit(src.getTrial);
         obj.updateForelimbEdit(src.getTrial);
         obj.updateButtonPopup(src.getTrial);
         obj.updateTracker(src.getTrial);
         obj.updateCurrentTrackerTrial(src.getTrial);
      end
      
      % Add or remove the grasp time for this trial
      function addRemoveGrasp(obj,src,~)
         t = src.vidInfo.getNeuralTime(src.graspTime);
         if obj.behaviorData.Grasp(src.getTrial)==t
            obj.behaviorData.Grasp(src.getTrial) = nan;
            obj.graspState = false;
         else
            obj.behaviorData.Grasp(src.getTrial) = t;
            obj.graspState = true;
         end
         obj.updateGraspEdit(src.getTrial,src.vidInfo);
         obj.updateTracker(src.getTrial);
         
      end
      
      % Add or remove the reach time for this trial
      function addRemoveReach(obj,src,~)
         t = src.vidInfo.getNeuralTime(src.reachTime);
         if obj.behaviorData.Reach(src.getTrial)==t
            obj.behaviorData.Reach(src.getTrial) = nan;
            obj.reachState = false;
         else
            obj.behaviorData.Reach(src.getTrial) = t;
            obj.reachState = true;
         end
         obj.updateReachEdit(src.getTrial,src.vidInfo);
         obj.updateTracker(src.getTrial);
         
      end
      
      % Update the hand used for this trial, where each "trial" corresponds
      % to a single button push      
      function updateHand(obj,src,~)
         obj.behaviorData.Forelimb(src.getTrial) = src.handUsed;
         obj.forelimbState = true;
         obj.updateForelimbEdit(src.getTrial);
         obj.updateTracker(src.getTrial);
      end
      
      % Update the outcome for this trial, where each "trial" corresponds
      % to a single button push
      function updateOutcome(obj,src,~)
         obj.behaviorData.Outcome(src.getTrial) = src.trialOutcome;
         obj.outcomeState = true;
         obj.updateOutcomeEdit(src.getTrial);
         obj.updateTracker(src.getTrial);
      end
      
      % Update the tracker image by reflecting the "state" using red or
      % blue coloring in an image
      function updateTracker(obj,idx)
         if obj.reachState && obj.graspState && ...
               obj.outcomeState && obj.forelimbState
            
            obj.buttonTracker_display.CData(1,idx,:)=[0 0 1];
         else
            obj.buttonTracker_display.CData(1,idx,:)=[1 0 0];

         end
         
      end
      
      % Update the tracker to reflect which trial is being looked at
      % currently
      function updateCurrentTrackerTrial(obj,idx)
         x = linspace(0,1,size(obj.buttonTracker_display.CData,2)+1);
         x = x(2:end) - mode(diff(x))/2;
         obj.buttonTracker_displayOverlay.XData = [x(idx), x(idx)];
      end
      
      % Update the graphics object associated with grasp time
      function updateGraspEdit(obj,idx,v)
         if obj.graspState
            obj.graspEdit_display.String = num2str(v.getVidTime(obj.behaviorData.Grasp(idx)));
         else
            obj.graspEdit_display.String = 'N/A';
         end
      end
      
      % Update the graphics object associated with reach time
      function updateReachEdit(obj,idx,v)
         if obj.reachState
            obj.reachEdit_display.String = num2str(v.getVidTime(obj.behaviorData.Reach(idx)));
         else
            obj.reachEdit_display.String = 'N/A';
         end
      end
      
      % Update the graphics object associated with hand use
      function updateForelimbEdit(obj,idx)
         if obj.forelimbState
            obj.forelimbEdit_display.String = obj.behaviorData.Forelimb(idx);
         else
            obj.forelimbEdit_display.String = '?';
         end
      end
      
      % Update the graphics object associated with trial outcome
      function updateOutcomeEdit(obj,idx)
         if obj.outcomeState
            tmp = obj.behaviorData.Outcome(idx);
            if (tmp == 1)
               obj.outcomeEdit_display.String = 'Successful';
            else
               obj.outcomeEdit_display.String = 'Unsuccessful';
            end
         else
            obj.outcomeEdit_display.String = '?';
         end
      end
      
      % Update the graphics object associated with trial button
      function updateButtonPopup(obj,idx)
         obj.buttonPopup_display.Value = idx;         
      end
      
      
   end
   
end