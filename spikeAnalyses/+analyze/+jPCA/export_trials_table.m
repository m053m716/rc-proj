function E = export_trials_table(D,align)
%EXPORT_TRIALS_TABLE  Create table that can be exported for JMP statistics
%
%  E = analyze.jPCA.export_trials_table(D); % Default align is "Grasp"
%  E = analyze.jPCA.export_trials_table(D,align);
%
%  Inputs
%     D - Table output by `analyze.jPCA.multi_jPCA`
%
%  Output
%     E - Table that can be exported for jPCA analysis.

if nargin < 2
   align = "Grasp";
end

D = D(ismember(string(D.Alignment),align) & ...
   ismember(string(D.Area),"All"),:);

E = table.empty;
planeID = 0;
nOutlier = 0;
for iD = 1:size(D,1)
   animalID = D.AnimalID(iD);
   blockID = floor(iD/2);
   align = D.Alignment(iD);
   groupID = D.Group(iD);
   postOpDay = D.PostOpDay(iD);
   area = D.Area(iD); % ["All","RFA","CFA"]
   for iPlane = 1:3      
      planeIndex = iPlane;
      best_PCs = D.Summary{iD}.SS.explained.sort.best.vec.eig(...
         [(iPlane-1)*2+1,iPlane*2]);
      skew_PCs = D.Summary{iD}.SS.explained.sort.skew.vec.eig(...
         [(iPlane-1)*2+1,iPlane*2]);
      mu = ([D.PhaseData{iD}{iPlane}.mu]).'; % Average radius-weighted angle (circ_mean) of each trial
      cb95 = ([D.PhaseData{iD}{iPlane}.cb95]).'; % 95% confidence band on circular mean for each trial
      kur = ([D.PhaseData{iD}{iPlane}.k]).'; % Kurtosis on angle distribution for each trial
      e_skew = sum(D.Summary{iD}.SS.explained.eig.skew(skew_PCs));
      var_skew = mean(D.Summary{iD}.SS.explained.Rsquared(skew_PCs));
      e_best = sum(D.Summary{iD}.SS.explained.eig.best(best_PCs));
      var_best = mean(D.Summary{iD}.SS.explained.Rsquared(best_PCs));
      Outcome = categorical([D.PhaseData{iD}{iPlane}.outcome],[1,2],...
         ["Unsuccessful","Successful"]).';
      n = numel(Outcome);
      AnimalID = repelem(animalID,n,1);
      BlockID = repelem(blockID,n,1);
      Alignment = repelem(align,n,1);
      Area = repelem(area,n,1);
      GroupID = repelem(groupID,n,1);
      PostOpDay = repelem(postOpDay,n,1);
      PlaneIndex = repelem(planeIndex,n,1);
      PlaneID = repelem(planeID,n,1);   
      Duration = [D.PhaseData{iD}{iPlane}.duration].';
      thisTab = table(AnimalID,GroupID,BlockID,Alignment,Area,Outcome,PlaneID,...
         PlaneIndex,PostOpDay,...
         Duration,Explained_Skew,...
         mu,cb95,kur);
      iOutlier = isnan(cb95);
      nOutlier = nOutlier + sum(iOutlier);
      thisTab(iOutlier,:) = []; % Remove outlier trials
      E = [E; thisTab]; %#ok<AGROW>
      planeID = planeID + 1;
   end
end

po = (E.PostOpDay-2)./29;
E.PostOpDuration = log(po ./ (1 - po));
E.GroupID = categorical(E.GroupID);
E.Alignment = categorical(E.Alignment);
E.BlockID = categorical(E.BlockID);
E.AnimalID = categorical(E.AnimalID);
E.Area = categorical(E.Area);
E.PlaneID = categorical(E.PlaneID);
E.PlaneIndex = ordinal(E.PlaneIndex);
E.Explained = E.Explained ./ 100; % Normalize [0 to 1]
E.RotationStrength = log(E.Explained)-mean(log(E.Explained));
E.Duration = E.Duration .* 1e-3; % Convert to seconds
E.AveragePhaseAngleDeviation = abs(E.mu);
E.Properties.UserData = struct;
E.Properties.UserData.Excluded.fail_circle_stats_reqs = nOutlier;
E.Properties.Description = 'jPCA Rotation Subspace summary table for fitting glme';

E = sortrows(E,'AnimalID','ascend');


end