function UTrials = makeSupportAssociation(UTrials)
%MAKESUPPORTASSOCIATION  Makes association between Support time & alignment
%
%  UTrials = analyze.behavior.makeSupportAssociation(UTrials);
%
% Inputs
%  UTrials - Table of unique trials (.Type = 'UniqueTrials')
%
% Output
%  Same table, but with added variable: SupportType
%
% See also: analyze.behavior, trial_duration_stats

supportCategories = categorical(...
   [1,2,3,4],      ...                               % values in array
   [1,2,3,4],      ...                               % valueset
   {'No Support','Reach','Retract','Grasp'});        % categories

values = repmat(supportCategories(1),size(UTrials,1),1);
values(UTrials.SupportGraspOffset <  0) = supportCategories(2);
values(UTrials.SupportGraspOffset >  0) = supportCategories(3);
values(UTrials.SupportGraspOffset == 0) = supportCategories(4);

UTrials.SupportType = values;
UTrials.Properties.VariableDescriptions{'SupportType'} = 'Support association';

end