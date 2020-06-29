function E = export_rm_table(D,align)
%EXPORT_RM_TABLE  Create table that can be exported for JMP statistics
%
%  E = analyze.jPCA.export_rm_table(D); % Default align is "Grasp"
%  E = analyze.jPCA.export_rm_table(D,align);
%
%  Inputs
%     D - Table output by `analyze.jPCA.multi_jPCA`
%
%  Output
%     E - Table that can be exported for jPCA analysis.

if nargin < 2
   align = "Grasp";
end

D = D(ismember(string(D.Alignment),align) & ismember(string(D.Area),"All"),:);

E = table.empty;
nOutlier = 0;

for iD = 1:size(D,1)
   animalID = D.AnimalID(iD);
   blockID = floor(iD/2);
   align = D.Alignment(iD);
   groupID = D.Group(iD);
   postOpDay = D.PostOpDay(iD);
   mu = [];
   cb95 = [];
   kur = [];
   explained = [];
   for iPlane = 1:3      
      thesePCs = D.Summary{iD}.SS.all.explained.sort.skew.vector(...
         [(iPlane-1)*2+1,iPlane*2]);
      mu = [mu,([D.PhaseData{iD}{iPlane}.mu]).']; %#ok<*AGROW> % Average radius-weighted angle (circ_mean) of each trial
      cb95 = [cb95,([D.PhaseData{iD}{iPlane}.cb95]).']; % 95% confidence band on circular mean for each trial
      kur = [kur,([D.PhaseData{iD}{iPlane}.k]).']; % Kurtosis on angle distribution for each trial
      explained = [explained,sum(D.Summary{iD}.SS.all.explained.eig.skew(thesePCs) ...
          .* D.Summary{iD}.SS.all.explained.R2.skew(thesePCs).')];
   end
   n = size(mu,1);
   AnimalID = repelem(animalID,n,1);
   BlockID = repelem(blockID,n,1);
   Alignment = repelem(align,n,1);
   GroupID = repelem(groupID,n,1);
   PostOpDay = repelem(postOpDay,n,1);
   Duration = [D.Data{iD}.Duration].';
   Explained = repmat(explained,n,1);
   Outcome = categorical([D.Data{iD}.Outcome].',...
      [1,2],["Unsuccessful","Successful"]);
   thisTab = table(AnimalID,GroupID,BlockID,...
      Alignment,Outcome,PostOpDay,Duration,Explained,...
      mu,cb95,kur);
   iOutlier = any(isnan(cb95),2);
   nOutlier = nOutlier + sum(iOutlier);
   thisTab(iOutlier,:) = []; % Remove outlier trials
   E = [E; thisTab];
end
po = (E.PostOpDay-2)./29;
E.PostOpDuration = log(po ./ (1 - po));
E.GroupID = categorical(E.GroupID);
E.Alignment = categorical(E.Alignment);
E.BlockID = categorical(E.BlockID);
E.AnimalID = categorical(E.AnimalID);
E.Explained = E.Explained ./ 100; % Normalize [0 to 1]
E.RotationStrength = log(E.Explained)-mean(log(E.Explained));
E.Duration = E.Duration .* 1e-3; % Convert to seconds
E.Properties.UserData = struct;
E.Properties.UserData.Excluded.fail_circle_stats_reqs = nOutlier;
E.Properties.Description = 'jPCA Rotation Subspace summary table for fitting repeated-measures model';

E = sortrows(E,'AnimalID','ascend');
E = splitvars(E, 'RotationStrength');
E.Properties.UserData.WithinModel = 'orthogonalcontrasts';
E.Properties.UserData.WithinDesign = table([1,2,3]','VariableNames',{'Plane'});
E.Properties.UserData.BetweenModel = "RotationStrength_1-RotationStrength_3~PostOpDay*GroupID+Duration";
end