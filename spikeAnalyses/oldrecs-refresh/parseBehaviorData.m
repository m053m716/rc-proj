function behaviorData = parseBehaviorData(succGrasp,failGrasp,reach,support,varargin)
%% PARSEBEHAVIORDATA  Parse correct table format for old video scoring
%
%  PARSEBEHAVIORDATA(succGrasp,failGrasp,reach,support);
%  PARSEBEHAVIORDATA(succGrasp,failGrasp,reach,support,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%  succGrasp      :     1 x i vector of successful grasp times, relative to
%                          neural recording.
%
%  failGrasp      :     1 x j vector of unsuccessful grasp times, relative
%                          to neural recording.
%
%   reach         :     1 x k vector of reach times, relative to neural
%                          recording. This is used to determine the number
%                          of rows in behaviorData, the output table.
%
%  support        :     1 x l vector of times the support paw reached its
%                          apex (if it was moving during a trial), or the
%                          first frame in which it came into contact with
%                          the wall of the behavior box.
%
%  varargin       :     (optional) 'NAME' value input argument pairs.
%
%  --------
%   OUTPUT
%  --------
%  Saves [blockName _Scoring.mat] in the _Digital sub-folder of the BLOCK.
%  Contains behaviorData table, which has rows for each reach.
%
% By: Max Murphy  v1.0  12/29/2018  Original version (R2017a)

%% DEFAULTS
E_PRE = 0.5;  % Seconds prior to reach to look for "support" or "grasp"
% [note: this typically occurs just prior to or after the
%        grasp, which is the reason this is set to a shorter
%        duration prior to the reach and a longer duration
%        after the reach.

E_POST = 2.0; % Seconds after the reach to look for "support"

SCORER = 'MM'; % Keep track of who appended scoring at least, since wasn't tracked before
VARTYPE = [0 1 1 1 2 3 4 5]; % Variable types for behavior scoring UI

%% TRIALS = REACHES, WHICH ARE ALL ALREADY SCORED
Trial = reshape(reach,numel(reach),1); % col 1
Reach = Trial;                         % col 2

%% PELLET PRESENCE, # PELLETS, & FORELIMB WERE NOT SCORED
Pellets = nan(size(Reach));         % col 5
PelletPresent = nan(size(Reach));   % col 6
Forelimb = nan(size(Reach));        % col 8

%% EACH REACH HAS A CORRESPONDING GRASP AND SUPPORT OR NONE AT ALL
% Pre-allocate to match correct number of trials
Grasp = nan(size(Reach));     % col 3
Support = nan(size(Reach));   % col 4
Outcome = nan(size(Reach));   % col 7

% They must be within some limited frame around the reach to be considered
% as part of the trial anyhow.
g = [succGrasp, failGrasp];
o = [ones(size(succGrasp)), zeros(size(failGrasp))];

% Make sure they are chronological, and sort outcomes to match
[g,idx] = sort(g,'ascend');
o = o(idx);

% Next, loop through each Reach to find a corresponding Grasp & Support
for ii = 1:numel(Reach)
   % Set the current trial time to look at
   r = Reach(ii);
   
   % Create bounds on when to look for grasps & supports
   pre = r - E_PRE;
   post = r + E_POST;
   
   % Figure out if there are any  grasps or supports in that time
   otmp = o((g >= pre) & (g <= post));
   gtmp = g((g >= pre) & (g <= post));
   stmp = support((support >= pre) & (support <= post));
   
   [Grasp(ii),Outcome(ii)] = getMatchingGrasp(r,gtmp,otmp);
   Support(ii) = getMatchingSupport(r,stmp);
   
end

behaviorData = table(Trial,Reach,Grasp,Support,Pellets,PelletPresent,Outcome,Forelimb);

behaviorData.Properties.UserData = VARTYPE;
todays_date = datestr(datetime,'YYYY-mm-dd');
behaviorData.Properties.Description = sprintf('Updated by %s on %s',...
   SCORER,todays_date); 

%% SUB-FUNCTIONS
   % Function to get grasp and outcome that matches the reach
   function [g,o] = getMatchingGrasp(r,G,O)
      % If no times in that epoch, return NaN
      if isempty(G)
         g = nan;
         o = nan;
         return;
      end
      
      % Otherwise, need to set up logic to prioritize grasp events
      % *after* the reach, but otherwise take the nearest grasp event
      % prior to the reach, and associated outcome.
      if numel(G)>1 % If more than one option, 
                    % pick the closest ts to the reach, after the reach
         postG = G(G > r);
         postO = O(G > r);
         if isempty(postG) % If only times before the reach, take closest
            [~,gIdx] = min(abs(G - r));
            g = G(gIdx);
            o = O(gIdx);
         else % Prioritizes the nearest grasp *after* the reach
            [~,gIdx] = min(abs(postG - r));
            g = postG(gIdx);
            o = postO(gIdx); % And its associated outcome
         end
         return;         
      else % Otherwise, only one option for everything
         g = G;
         o = O;
         return;
      end
      
   end

   % Function to get support that matches the reach
   function s = getMatchingSupport(r,S)
      % If no times in that epoch, return NaN
      if isempty(S)
         s = nan;
         return;
      end
      
      % Otherwise, need to set up logic to prioritize support events
      % *after* the reach, but otherwise take the nearest support event
      % prior to the reach.
      if numel(S)>1 % If more than one option
         postS = S(S > r); % Look for any *after* the reach
         if isempty(postS) % If none, get nearest to the reach
            [~,sIdx] = min(abs(S - r));
            s = S(sIdx);
         else % Prioritizes the earliest support *after* the reach
            [~,sIdx] = min(abs(postS - r));
            s = postS(sIdx);
         end         
         return;
      else % Otherwise return the only option
         s = S;
         return;
      end
   end

end