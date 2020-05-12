function C = exportCircleStats(J,align,outcome,area)
%% EXPORTCIRCLESTATS  Export stats to excel file for JMP
%
%  EXPORTCIRCLESTATS(J);
%  C = EXPORTCIRCLESTATS(J);
%
%  --------
%   INPUTS
%  --------
%     J        :     Table returned by GETJPCA method of group object
%
%                    -> Variables of J:
%                    --> 'Rat'        : Name of RAT
%                    --> 'Name'       : Name of BLOCK
%                    --> 'Group'      : 'Ischemia' or 'Intact'
%                    --> 'PostOpDay'  : Days after surgery (int scalar)
%                    --> 'Score'      : % Successful (0 - 1 float scalar)
%                    --> 'Data'       : Data structure (see BLOCK)
%
%  --------
%   OUTPUT
%  --------
%     C        :     Table similar to J, but without Data fields and with
%                       the following additional fields:
%                 
%                    --> 'Mu0'                 
%                    --> 'Std0'                 
%                    --> 'Skewness0'                 
%                    --> 'Kurtosis0'
%
%                    If no output is requested, then the table C will be
%                    written to an excel spreadsheet for analysis using
%                    JMP.
%
% By: Max Murphy  v1.0  2019-06-10  Original version (R2017a)

%%
if nargin < 4
   area = 'Full';
end

if nargin < 3
   outcome = 'Successful';
end

if nargin < 2
   align = 'Grasp';
end


Outcome = repmat({outcome},size(J,1),1);
Align = repmat({align},size(J,1),1);
Area = repmat({area},size(J,1),1);
Mu = nan(size(J,1),1);
Std0 = nan(size(Mu));
Skewness0 = nan(size(Mu));
Kurtosis0 = nan(size(Mu));

for iJ = 1:size(J,1)
%    if ~isfield(J.Data(iJ),align)
%       continue;
%    elseif ~isfield(J.Data(iJ).(align),outcome)
%       continue;
%    elseif ~isfield(J.Data(iJ).(align).(outcome),'jPCA')
%       continue;
%    elseif ~isfield(J.Data(iJ).(align).(outcome).jPCA,area)
%       continue;
%    end
%    tmp = J.Data(iJ).(align).(outcome).analyze.jPCA.(area);
%    if isempty(tmp.Summary)
%       continue;
%    end
   tmp = J.Data(iJ);

   Mu(iJ) = tmp.Summary.circStats{1}.stats.mean;
   Std0(iJ) = tmp.Summary.circStats{1}.stats.std0;
   Skewness0(iJ) = tmp.Summary.circStats{1}.stats.skewness0;
   Kurtosis0(iJ) = tmp.Summary.circStats{1}.stats.kurtosis0;
end

C = [J(:,1:5),table(Outcome,Align,Area,Mu,Std0,Skewness0,Kurtosis0)];
if nargout < 1 % Write excel file if no output requested
   lpf_fc = defaults.block('lpf_fc');
   output_score = defaults.group('output_score');
   jpca_start_stop_times = defaults.jPCA('jpca_start_stop_times');
   fname = sprintf('GroupCircleStats_%s_%s_%s_%gms_to_%gms_%s_%gHzFc.xlsx',...
      align,outcome,area,jpca_start_stop_times(1),jpca_start_stop_times(2),...
      output_score,lpf_fc);
   writetable(C,fname);
end

end