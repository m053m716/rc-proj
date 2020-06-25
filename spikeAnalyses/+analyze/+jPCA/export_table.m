function E = export_table(D,align)
%EXPORT_TABLE  Create table that can be exported for JMP statistics
%
%  E = analyze.jPCA.export_table(D); % Default align is "Grasp"
%  E = analyze.jPCA.export_table(D,align);
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
      thesePCs = D.Summary{iD}.SS.all.explained.sort.skew.vector(...
         [(iPlane-1)*2+1,iPlane*2]);
      
%       wAvgDP = ([D.PhaseData{iD}{iPlane}.wAvgDPWithPiOver2]).';
      mu = ([D.PhaseData{iD}{iPlane}.mu]).'; % Average radius-weighted angle (circ_mean) of each trial
      cb95 = ([D.PhaseData{iD}{iPlane}.cb95]).'; % 95% confidence band on circular mean for each trial
      kur = ([D.PhaseData{iD}{iPlane}.k]).'; % Kurtosis on angle distribution for each trial
      explained = sum(D.Summary{iD}.SS.all.explained.eig.skew(thesePCs));
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
      Explained = repelem(explained,n,1);
      thisTab = table(AnimalID,GroupID,BlockID,Alignment,Area,Outcome,PlaneID,...
         PlaneIndex,PostOpDay,...
         Duration,Explained,...
         mu,cb95,kur);
      iOutlier = isnan(cb95);
      nOutlier = nOutlier + sum(iOutlier);
      thisTab(iOutlier,:) = []; % Remove outlier trials
      E = [E; thisTab]; %#ok<AGROW>
      planeID = planeID + 1;
   end
end
% iWrongDirection = E.mu < 0;
% E(iWrongDirection,:) = [];

% [~,E.RotationStrength] = analyze.jPCA.averageDotProduct(E.mu,pi/2);
% E.RotationStrength = abs(E.mu)./pi;
% E.PostOpDuration = atan(((E.PostOpDay - 17)/35)*2*pi);
po = (E.PostOpDay-2)./29;
E.PostOpDuration = log(po ./ (1 - po));
% iOutOfRange = isinf(E.PostOpDuration);
% E(iOutOfRange,:) = [];
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
E.Properties.UserData = struct;
E.Properties.UserData.Excluded.fail_circle_stats_reqs = nOutlier;
% E.Properties.UserData.Excluded.rotating_clockwise = sum(iWrongDirection);
% E.Properties.UserData.Excluded.out_of_date_range = sum(iOutOfRange);
E.Properties.Description = 'jPCA Rotation Subspace summary table for fitting glme';
E = sortrows(E,'RotationStrength','ascend');

% S = struct;
% S.Link = @(mu)cos(mu);
% S.Derivative = @(mu)-sin(mu);
% S.SecondDerivative = @(mu)-cos(mu);
% S.Inverse = @(mu)acos(cos(mu));
% E.Properties.UserData.LinkFcns = S;

end