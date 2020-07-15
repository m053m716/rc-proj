function [Total_Trials,Successful_Trials,Unsuccessful_Trials,Success_Rate] = score(outcome)
%SCORE Estimates behavior score endpoints by BlockID or PostOpDay
%
%  [Total_Trials,Successful_Trials,Unsuccessful_Trials,Success_Rate] = analyze.behavior.score(outcome);
%
%  Example Usage:
%     [G,S] = findgroups(U(:,{'Group','AnimalID','BlockID','PostOpDay'}));
%     [S.Total_Trials,S.Successful_Trials,...
%      S.Unsuccessful_Trials,S.Success_Rate] = ...
%        splitapply(@(outcome)analyze.behavior.score(outcome),U.Outcome,G);
%
% Inputs
%  outcome -  Variable ".Outcome" from main "rates" table, as a categorical
%              array containing either "Successful" or "Unsuccessful".
%              Only elements that correspond to a UNIQUE Trial_ID value
%              should be used.
%
% Output
%  Total_Trials        - Number of total trials from this recording
%  Successful_Trials   - Number of successful pellet retrievals
%  Unsuccessful_Trials - Number of failed pellet retrievals
%  Success_Rate        - Percent of successful to total (nSucc/nTrials)*100
%  
% See also: analyze.behavior, analyze.behavior.show, behavior_timing.mlx

Total_Trials = size(outcome,1);
Successful_Trials = sum(string(outcome)=="Successful");
Unsuccessful_Trials = sum(string(outcome)=="Unsuccessful");
Success_Rate = (Successful_Trials/Total_Trials)*100;

end