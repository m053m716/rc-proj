function E = exportSubTable(D)
%EXPORTSUBTABLE Create table for GLME model fit, using only R^2_adj
%
%  E = analyze.dynamics.exportSubTable(D);
%
% Inputs
%  D   - Table output by `analyze.jPCA.multi_jPCA`
%
% Output
%  E   - Table that can be exported for jPCA analysis.
%
% See also: analyze.dynamics, population_firstorder_mls_regression_stats
%           analyze.dynamics.exportTable

nTotal = size(D,1);

E = table.empty;
fprintf(1,'Exporting linearized dynamics fit trends (table)...000%%\n');
curPct = 0;
for iD = 1:nTotal
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
   Duration = nanmean([D.PhaseData{iD}{1}.duration] .* 1e-3);
   Reach_Epoch_Duration = nanmean(([D.Data{iD}.tGrasp] - [D.Data{iD}.tReach]) .* 1e-3);
   Retract_Epoch_Duration = nanmean(([D.Data{iD}.tComplete] - [D.Data{iD}.tGrasp]) .* 1e-3);
   
   SS = analyze.dynamics.parseSingleR2(D.Projection{iD});
   Explained = SS.best.explained_pcs;
   R2_Best = SS.best.Total.Rsquared_adj;
   R2_Skew = SS.skew.Total.Rsquared_adj;
   E = [E; table(AnimalID,GroupID,BlockID,Alignment,PostOpDay,...
         Duration,Reach_Epoch_Duration,Retract_Epoch_Duration,...
         N_Trials,N_Channels,N_CFA,N_RFA,N_Forelimb,N_Distal_Forelimb,...
         Pct_DF,Pct_RFA,Explained,R2_Best,R2_Skew,SS)]; %#ok<AGROW>
   
   thisPct = round(iD/nTotal * 100);
   if (thisPct - curPct) >= 2
      fprintf(1,'\b\b\b\b\b%03d%%\n',thisPct);
      curPct = thisPct;
   end
end
E.GroupID   = categorical(E.GroupID);
E.BlockID   = categorical(E.BlockID);
E.AnimalID  = categorical(E.AnimalID);
E.LogOdds_Fit_Skew = log(E.R2_Skew) - log(E.R2_Best);

E.Properties.UserData = struct;
E.Properties.UserData.Type = 'Dynamics';
E.Properties.Description = 'Linearized Dynamics Fit Trends';
E = sortrows(E,'PostOpDay','ascend');
T = utils.readBehaviorTable([],true);
E = outerjoin(E,T,'Keys',{'GroupID','AnimalID','PostOpDay'},...
   'MergeKeys',true,...
   'Type','left',...
   'RightVariables',{'GroupID','AnimalID',...
                     'PostOpDay','PostOpDay_Cubed','Performance_mu','Performance_hat_mu'});
E.Properties.VariableNames{'Performance_mu'} = 'Performance';
E.Properties.VariableNames{'Performance_hat_mu'} = 'Model_Fit_Performance';
obsNames = strcat(...
   strrep(string(E.AnimalID),'-',''),"::",...
   string(arrayfun(@(d)sprintf('D%02d',d),E.PostOpDay,'UniformOutput',false)),"::",...
   E.Alignment);
E.Properties.RowNames = obsNames;
E.ExplainedLogit = -log(100./E.Explained - 1);
end