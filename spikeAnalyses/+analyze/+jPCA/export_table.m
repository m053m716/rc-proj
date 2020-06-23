function E = export_table(D)
%EXPORT_TABLE  Create table that can be exported for JMP statistics
%
%  E = analyze.jPCA.export_table(D);
%
%  Inputs
%     D - Table output by `analyze.jPCA.multi_jPCA`
%
%  Output
%     E - Table that can be exported for jPCA analysis.

E = table.empty;
planeID = 0;
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
      Group = repelem(groupID,n,1);
      PostOpDay = repelem(postOpDay,n,1);
      PlaneIndex = repelem(planeIndex,n,1);
      PlaneID = repelem(planeID,n,1);   
      Duration = [D.PhaseData{iD}{iPlane}.duration].';
      Explained = repelem(explained,n,1);
      thisTab = table(AnimalID,Group,BlockID,Alignment,Area,Outcome,PlaneID,...
         PlaneIndex,PostOpDay,...
         Duration,Explained,...
         mu,cb95,kur);
      thisTab(isnan(cb95),:) = []; % Remove outlier trials
      E = [E; thisTab]; %#ok<AGROW>
      planeID = planeID + 1;
   end
end
[~,rot] = analyze.jPCA.averageDotProduct(E.mu,pi/2);
E.RotationStrength = 1 - abs(rot);
E.Group = categorical(E.Group);
E.Alignment = categorical(E.Alignment);
E.BlockID = categorical(E.BlockID);
E.AnimalID = categorical(E.AnimalID);
E.Area = categorical(E.Area);
E.PlaneID = categorical(E.PlaneID);

end