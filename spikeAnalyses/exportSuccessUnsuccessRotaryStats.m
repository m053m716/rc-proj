function C = exportSuccessUnsuccessRotaryStats(J)
%% EXPORTSUCCESSUNSUCCESSROTARYSTATS Export data about number of trials by day and outcome with strong rotatory signatures to JMP
%
%  EXPORTSUCCESSUNSUCCESSROTARYSTATS(J);
%  C = EXPORTSUCCESSUNSUCCESSROTARYSTATS(J);
%
%  --------
%   INPUTS
%  --------
%     J           :     Table returned by GETPHASE method of group object,
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
%     C        :     Table similar to J, but without Data fields and with
%                       the following additional fields:
%                 
%                    --> 'nSuccessful'
%                    --> 'nUnsuccessful'
%
%                    If no output is requested, then the table C will be
%                    written to an excel spreadsheet for analysis using
%                    JMP.
%
% By: Max Murphy  v1.0  2019-06-10  Original version (R2017a)

%%
nSuccessful = nan(size(J,1),1);
nUnsuccessful = nan(size(J,1),1);
pctUnsuccessful = nan(size(J,1),1);

for iJ = 1:size(J,1)

   nSuccessful(iJ) = sum(J.Data(iJ).Summary.outcomes==1);
   nUnsuccessful(iJ) = sum(J.Data(iJ).Summary.outcomes==2);
   
   pctUnsuccessful(iJ) = round(nUnsuccessful(iJ) / ...
                           J.nAttempts(iJ)*100);
end

C = [J(:,1:7), table(nSuccessful,nUnsuccessful,pctUnsuccessful)];
C.PostOpDay = tanh((C.PostOpDay - 14)/7);
C.Score = sinh(C.Score);

if nargout < 1 % Write excel file if no output requested
   lpf_fc = defaults.block('lpf_fc');
   output_score = defaults.group('output_score');
   jpca_start_stop_times = defaults.jPCA('jpca_start_stop_times');
   fname = sprintf('SuccessUnsuccessRotaryStats_%gms_to_%gms_thresh-%g_%s_%gHzFc.xls',...
      jpca_start_stop_times(1),jpca_start_stop_times(2),...
      round(defaults.group('w_avg_dp_thresh')*100),output_score,lpf_fc);
   writetable(C,fname);
end

end