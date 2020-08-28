function rPivot = pivotWeeklyAUCtable(rWeek)
%PIVOTWEEKLYAUCTABLE Pivot weekly AUC table for ROC prediction to make combined statistical model
%
%  rPivot = analyze.stat.pivotWeeklyAUCtable(rWeek);
%
% Inputs
%  rWeek  - Data with AUC appended to it 
%  
% Output
%  rPivot - Create new variable 'Phase' and combines AUC for each of the
%              different phase-based prediction models so that Phase can be
%              included as a fixed-effect in GLME.
%
% See also: analyze.stat, analyze.stat.addWeeklyROCdata,
%           unit_learning_stats

rWeek.Properties.RowNames = {};
nWeek = size(rWeek,1);
rPivot = repelem(rWeek,3,1); % Replicate each row 3 times



% Create new output variable
rPivot.AUC = splitDistr(rPivot.Pre_AUC,rPivot.Reach_AUC,rPivot.Retract_AUC);
rPivot.Mean = splitDistr(rPivot.n_Pre_mean,rPivot.n_Reach_mean,rPivot.n_Retract_mean);
rPivot.SD = splitDistr(rPivot.n_Pre_std,rPivot.n_Reach_std,rPivot.n_Retract_std);
rPivot.Phase = repmat(categorical((1:3)',1:3,{'Pre','Reach','Retract'}),...
                  nWeek,1);

% Remove old variables
rPivot(:,...
   {'Pre_AUC','Reach_AUC','Retract_AUC',...
    'n_Pre_mean','n_Reach_mean','n_Retract_mean',...
    'n_Pre_std','n_Reach_std','n_Retract_std','RowID'}) = [];
rPivot = movevars(rPivot,'GroupID','Before','AnimalID');
rPivot = movevars(rPivot,{'Phase','AUC'},'Before','Duration');
rPivot(isnan(rPivot.AUC),:) = [];

   function varOut = splitDistr(varPre,varReach,varRetract)
      n = size(varPre,1); % Get total number of rows
      iPre = 1:3:n;
      iReach = 2:3:n;
      iRetract = 3:3:n;
      
      varOut = nan(n,1);
      
      varOut(iPre) = varPre(iPre);
      varOut(iReach) = varReach(iReach);
      varOut(iRetract) = varRetract(iRetract);
   end
end