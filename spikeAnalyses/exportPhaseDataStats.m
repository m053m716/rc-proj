function out = exportPhaseDataStats(phaseData)
%% EXPORTPHASEDATASTATS  Export phase stats to excel file for JMP
%
%  EXPORTPHASEDATASTATS(phaseData);
%  out = EXPORTPHASEDATASTATS(phaseData);
%
%  --------
%   INPUTS
%  --------
%  phaseData      :     Table returned by GETPHASE method of group object,
%                       which contains the Data property of all
%                       sub-children Block objects.
%
%                    -> Variables of J:
%                    --> 'Rat'        : Name of RAT
%                    --> 'Name'       : Name of BLOCK
%                    --> 'Group'      : 'Ischemia' or 'Intact'
%                    --> 'PostOpDay'  : Days after surgery (int scalar)
%                    --> 'Score'      : % Successful (0 - 1 float scalar)
%                    --> 'phaseData'  : Data structure (see BLOCK)
%
%  --------
%   OUTPUT
%  --------
%    out       :     Table similar to J, but without Data fields and with
%                       the following additional fields:
%                 
%                    --> 'wAvg'
%
%                    If no output is requested, then the table C will be
%                    written to an excel spreadsheet for analysis using
%                    JMP.
%
% By: Max Murphy  v1.0  2019-06-10  Original version (R2017a)

%%
OUT = {'Successful';'Unsuccessful'};


varNames = [phaseData.Properties.VariableNames(1:8),{'wAvg','Outcome'}];

out = [];
for iP = 1:size(phaseData,1)
   if isempty(phaseData.phaseData{iP})
      continue;
   else
      P = phaseData(iP,[1:6,8]);
   end
   
   wAvg = [phaseData.phaseData{iP}.wAvgDPWithPiOver2].';
   Outcome = OUT([phaseData.phaseData{iP}.label].');
   phase = unwrap(vertcat(phaseData.phaseData{iP}.phaseDiff).');
   Phase = nan(size(phase,2),ceil(size(phase,1)/10));
   for ii = 1:size(phase,2)
      Phase(ii,:) = decimate(phase(:,ii),10);
   end
   p = repmat(P,numel(wAvg),1);
   
%    Rat = p.Rat;
%    Name = p.Name;
%    Group = p.Group;
%    PostOpDay = p.PostOpDay;
%    Score = p.Score;
%    Align = p.Align;
   
   if nargout > 0
      t = [table(Outcome,wAvg),array2table(Phase)];
   else
      t = table(Outcome,wAvg);
   end
   out = [out; [p,t]]; %#ok<*AGROW>
end
out.PostOpDay = tanh((out.PostOpDay - 14)/7);
out.Score = sinh(out.Score);

if nargout < 1 % Write excel file if no output requested
   lpf_fc = defaults.block('lpf_fc');
   output_score = defaults.group('output_score');
   jpca_start_stop_times = defaults.jPCA('jpca_start_stop_times');
   fname = sprintf('PhaseDataStats_%gms_to_%gms_%s_%gHzFc.xls',...
      jpca_start_stop_times(1),jpca_start_stop_times(2),output_score,lpf_fc);
   writetable(out,fname);
end

end