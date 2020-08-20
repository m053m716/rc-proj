function E = exportTable(D)
%EXPORTTABLE Create table for GLME model fit
%
%  E = analyze.dynamics.exportTable(D); % Default align is "Grasp"
%
% Inputs
%  D   - Table output by `analyze.jPCA.multi_jPCA`
%
% Output
%  E   - Table that can be exported for jPCA analysis.
%
% See also: analyze.dynamics, population_firstorder_mls_regression_stats

minPlaneRank = 6;
nTotal = size(D,1)*minPlaneRank;

E = table.empty;
fprintf(1,'Exporting linearized dynamics fit trends (table)...000%%\n');
curPct = 0;
iCur = 0;
for iD = 1:size(D,1)
   AnimalID = D.AnimalID(iD);
   Alignment = D.Alignment(iD);
   BlockID = floor(iD/2);
   GroupID = D.Group(iD);
   PostOpDay = D.PostOpDay(iD);
   N_Trials = numel(D.Projection{iD});
   N_Channels = size(D.CID{iD},1);
   N_CFA = sum(D.CID{iD}.Area=="CFA");
   N_RFA = sum(D.CID{iD}.Area=="RFA");
   N_Distal_Forelimb = sum(contains(string(D.CID{iD}.ICMS),'DF'));
   N_Forelimb = sum(contains(string(D.CID{iD}.ICMS),'F'));
   Pct_DF = N_Distal_Forelimb ./ N_Forelimb;
   Pct_RFA = N_RFA ./ N_Channels;
   Duration = nanmean([D.PhaseData{iD}{1}.duration].' .* 1e-3);
   for iPlane = 1:minPlaneRank  
      iCur = iCur + 1;
      vec = [(iPlane-1)*2+1,iPlane*2];
      best_PCs = D.Summary{iD}.SS.best.explained.sort.vec.eig(vec);
      skew_PCs = D.Summary{iD}.SS.skew.explained.sort.vec.eig(vec);
      Explained_Skew = sum(D.Summary{iD}.SS.skew.explained.eig(skew_PCs)) ./ 100;
      R2_Skew = nanmean(D.Summary{iD}.SS.skew.explained.varcapt(skew_PCs)) ./ 100;
      Explained_Best = sum(D.Summary{iD}.SS.best.explained.eig(best_PCs)) ./ 100;
      R2_Best = nanmean(D.Summary{iD}.SS.best.explained.varcapt(best_PCs)) ./ 100;
      PlaneIndex = iPlane;  
      thisTab = table(AnimalID,GroupID,BlockID,Alignment,...
         PostOpDay,PlaneIndex,Duration,...
         N_Trials,N_Channels,N_CFA,N_RFA,N_Forelimb,N_Distal_Forelimb,...
         Pct_DF,Pct_RFA,...
         Explained_Skew,R2_Skew,...
         Explained_Best,R2_Best);
      E = [E; thisTab]; %#ok<AGROW>
      thisPct = round(iCur/nTotal * 100);
      if (thisPct - curPct) >= 2
         fprintf(1,'\b\b\b\b\b%03d%%\n',thisPct);
         curPct = thisPct;
      end
   end
end
E.GroupID   = categorical(E.GroupID);
E.BlockID   = categorical(E.BlockID);
E.AnimalID  = categorical(E.AnimalID);
E.PlaneIndex = ordinal(E.PlaneIndex);

E.LogOdds_Explained = log(E.Explained_Skew) - log(E.Explained_Best);
E.LogOdds_Fit = log(E.R2_Skew) - log(E.R2_Best);

E.Properties.UserData = struct;
E.Properties.UserData.Type = 'Dynamics';
E.Properties.Description = 'Linearized Dynamics Fit Trends';
E = sortrows(E,'PostOpDay','ascend');
obsNames = strcat(...
   strrep(string(E.AnimalID),'-',''),"::",...
   string(arrayfun(@(d)sprintf('D%02d',d),E.PostOpDay,'UniformOutput',false)),"::",...
   E.Alignment,"::",...
   string(arrayfun(@(d)sprintf('P%d',d),E.PlaneIndex,'UniformOutput',false))...
);
E.Properties.RowNames = obsNames;
T = utils.readBehaviorTable([],true);
E = outerjoin(E,T,'Keys',{'GroupID','AnimalID','PostOpDay'},...
   'MergeKeys',true,...
   'Type','left',...
   'RightVariables',{'GroupID','AnimalID','PostOpDay','PostOpDay_Cubed','Performance_hat_mu','Performance_hat_cb95'});


end