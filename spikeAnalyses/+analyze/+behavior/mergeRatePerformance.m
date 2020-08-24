function r = mergeRatePerformance(r,doExclusions)
%MERGERATEPERFORMANCE Merge rate (count) table and performance table
%
%  r = analyze.behavior.mergeRatePerformance(r,doExclusions);
%
% Inputs
%  r - Table of rates/counts
%  doExclusions - Default is true, if true, applies .Excluded UserData
%
% Output
%  r - Updated (merged) table

B = utils.readBehaviorTable([],true);
leftVars = setdiff(r.Properties.VariableNames,...
   {'Performance_mu','Performance_hat_mu','Performance_hat_cb95'});
rightVars = {'Performance_mu','Performance_hat_mu','Performance_hat_cb95'};
r = outerjoin(r,B,...
   'Keys',{'GroupID','AnimalID','PostOpDay'},...
   'MergeKeys',true,'Type','Left',...
   'LeftVariables',leftVars,...
   'RightVariables',rightVars);
if doExclusions
   r = r(~r.Properties.UserData.Excluded,:);
   r.Properties.UserData.Excluded = r.Properties.UserData.Excluded(~r.Properties.UserData.Excluded);
end
r.Week = ceil(r.PostOpDay/7);
r.Properties.UserData.Excluded(r.Week > 4) = [];
r(r.Week > 4,:) = [];

end