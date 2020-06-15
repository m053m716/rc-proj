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
      thesePCs = ...
         ismember(D.Summary{iD}.sortIndices_jPCs,[(iPlane-1)*2+1,iPlane*2]);
      
      wAvgDP = ([D.PhaseData{iD}{iPlane}.wAvgDPWithPiOver2]).';
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
      Missed = 1 - Explained; % For convenience later during weightings
      thisTab = table(AnimalID,Group,BlockID,Alignment,Area,PostOpDay,...
         PlaneIndex,PlaneID,wAvgDP,mu,cb95,kur,...
         Outcome,Duration,Explained,Missed);
      thisTab(isnan(cb95),:) = []; % Remove outlier trials
      E = [E; thisTab]; %#ok<AGROW>
      planeID = planeID + 1;
   end
end

end