function T = addConfusionData(T,threshold)
%ADDCONFUSIONDATA Add variables: 'TP' 'FP' 'TN' 'FN' for confusion matrix
%
%  T = analyze.trials.addConfusionData(T);
%  T = analyze.trials.addConfusionData(T,threshold);
%
% Inputs
%  T - Data table with 'Outcome' and 'Prediction_Outcome' variables
%
% Output
%  T - Same as input, but appends 'TP' (True Positive), 'FP' (False
%     Positive), 'TN' (True Negative), 'FN' (False Negative) variables
%
% See also: Contents, unit_learning_stats


if (nargin < 2) && (~isnumeric(T.Prediction_Outcome))
   T = addOutcomeMatrix(T);
   T = addOutcomeMatrix(T,'W','Weekly_Prediction_Outcome');
   T = addOutcomeMatrix(T,'_s','Prediction_Outcome_Simple');
   T = addOutcomeMatrix(T,'_sW','Weekly_Prediction_Outcome_Simple');
   return;
end

if nargin < 2
   [G,TID] = findgroups(T(:,{'AnimalID','Week'}));
   TID.Prior = splitapply(@(o)sum(string(o)=="Successful")./numel(o),T.Outcome,G);
   T = outerjoin(T,TID,'Keys',{'AnimalID','Week'},...
      'LeftVariables',setdiff(T.Properties.VariableNames,{'Prior'}),...
      'RightVariables',{'Prior'},'Type','left');
   threshold = T.Prior .* 0.5;
end

if numel(threshold) > 1
   idx = ~isnan(threshold);
   threshold = threshold(idx);
else
   idx = true(size(T,1),1);
end

out = categorical(...
   double(T.Prediction_Outcome(idx) > threshold)+1,...
   [1 2],...
   {'Unsuccessful','Successful'});
obs = T.Outcome(idx);
T.TP = zeros(size(T,1),1);
T.TN = zeros(size(T,1),1);
T.FN = zeros(size(T,1),1);
T.FP = zeros(size(T,1),1);

T.TP(idx) = obs=="Successful" & out=="Successful";
T.TN(idx) = obs=="Unsuccessful" & out=="Unsuccessful";
T.FN(idx) = obs=="Successful" & out=="Unsuccessful";
T.FP(idx) = obs=="Unsuccessful" & out=="Successful";

   function T = addOutcomeMatrix(T,tag,predVar)
      
      if nargin < 2
         tag = '';
      end
      
      TPv = ['TP' tag];
      FPv = ['FP' tag];
      TNv = ['TN' tag];
      FNv = ['FN' tag];
      
      if nargin < 3
         predVar = ['Prediction_Outcome' tag];
      end
      
      if ismember(TPv,T.Properties.VariableNames)
         T.(TPv) = [];
      end

      if ismember(FPv,T.Properties.VariableNames)
         T.(FPv) = [];
      end

      if ismember(TNv,T.Properties.VariableNames)
         T.(TNv) = [];
      end

      if ismember(FNv,T.Properties.VariableNames)
         T.(FNv) = [];
      end
      
      if ~ismember(predVar,T.Properties.VariableNames)
         warning('Bad prediction variable: <strong>''%s''</strong> (skipped)',predVar);
         T.(TPv) = zeros(size(T,1),1);
         T.(FPv) = zeros(size(T,1),1);
         T.(FNv) = zeros(size(T,1),1);
         T.(TNv) = zeros(size(T,1),1);
         return;
      end
      
      T.(TPv) = T.Outcome=="Successful" & T.(predVar)=="Successful";
      T.(TNv) = T.Outcome=="Unsuccessful" & T.(predVar)=="Unsuccessful";

      T.(FNv) = T.Outcome=="Successful" & T.(predVar)=="Unsuccessful";
      T.(FPv) = T.Outcome=="Unsuccessful" & T.(predVar)=="Successful";
      
      
   end

end