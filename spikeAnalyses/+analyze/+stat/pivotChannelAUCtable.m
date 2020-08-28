function rPivot = pivotChannelAUCtable(rSub)
%PIVOTCHANNELAUCTABLE Pivot channel AUC table for ROC prediction to make combined statistical model
%
%  rPivot = analyze.stat.pivotChannelAUCtable(rWeek);
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

rSub.Properties.RowNames = {};
nWeek = size(rSub,1);
rPivot = repelem(rSub,3,1); % Replicate each row 3 times

% Create new output variable
rPivot.N_Spikes = splitDistr(rPivot.N_Pre_Grasp,rPivot.N_Reach,rPivot.N_Retract);
rPivot.Phase_Duration = splitDistrConst(0.6,rPivot.Reach_Epoch_Duration,rPivot.Retract_Epoch_Duration);
rPivot.Phase_Duration_Residual = splitDistr(rPivot.Duration_res,rPivot.Reach_Epoch_Duration_res,rPivot.Retract_Epoch_Duration_res);
rPivot.N_Hat = splitDistr(rPivot.N_Pre_Pred_Hat,rPivot.N_Reach_Pred_Hat,rPivot.N_Retract_Pred_Hat);
rPivot.N_Tilde = splitDistr(rPivot.N_Pre_Pred_Tilde,rPivot.N_Reach_Pred_Tilde,rPivot.N_Retract_Pred_Tilde);
rPivot.AUC = splitDistr(rPivot.Pre_AUC,rPivot.Reach_AUC,rPivot.Retract_AUC);
rPivot.Epsilon = splitDistr(rPivot.epsilon_pre,rPivot.epsilon_reach,rPivot.epsilon_retract);

rPivot.Phase = repmat(categorical((1:3)',1:3,{'Pre','Reach','Retract'}),...
                  nWeek,1);

% Remove old variables
rPivot(:,...
   {'Pre_AUC','Reach_AUC','Retract_AUC',...
    'N_Pre_Grasp','N_Reach','N_Retract',...
    'epsilon_pre','epsilon_reach','epsilon_retract',...
    'delta_Pre_Hat','delta_Reach_Hat','delta_Retract_Hat',...
    'delta_Pre_Tilde','delta_Reach_Tilde','delta_Retract_Tilde',...
    'Reach_Epoch_Duration','Retract_Epoch_Duration', ...
    'N_Pre_Pred_Hat','N_Reach_Pred_Hat','N_Retract_Pred_Hat', ...
    'Duration_res','Reach_Epoch_Duration_res','Retract_Epoch_Duration_res',...
    'N_Pre_Pred_Tilde','N_Reach_Pred_Tilde','N_Retract_Pred_Tilde',...
    'RowID','N_Grasp','Performance_hat_cb95','Performance_hat_mu'}) = [];
rPivot = movevars(rPivot,{'GroupID','ChannelID'},'Before','AnimalID');
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

   function varOut = splitDistrConst(c,varReach,varRetract)
      n = size(varReach,1); % Get total number of rows
      iPre = 1:3:n;
      iReach = 2:3:n;
      iRetract = 3:3:n;
      
      varOut = nan(n,1);
      
      varOut(iPre) = c;
      varOut(iReach) = varReach(iReach);
      varOut(iRetract) = varRetract(iRetract);
   end
end