function UTrials = getDescriptiveTimingStats(UTrials,varName)
%GETDESCRIPTIVETIMINGSTATS Returns updated UserData for descriptive stats
%
%  UTrials = analyze.behavior.getDescriptiveTimingStats(UTrials);
%  UTrials = analyze.behavior.getDescriptiveTimingStats(UTrials,varName);
%
% Inputs
%  UTrials - Table with only unique trials as rows, and timing variables
%  varName - (Optional) default is 'Default'; can be any of the "duration"
%              variables
%
% Output
%  UTrials - Same as input but with updated corresponding sub-field of
%              UserData struct property.
%
% See also: analyze.behavior, trial_duration_stats

if nargin < 2
   varName = 'Duration';
end

if ~strcmpi(UTrials.Properties.UserData.Type,'UniqueTrials')
   error('Wrong data table: should be of type "UniqueTrials"');
end

fprintf(1,'\n-----------------------------------------------------------------------------\n');
fprintf(1,'\tDescriptive statistics for all trials: <strong>%s</strong>\n',...
   strrep(varName,'_',' '));
fprintf(1,'-----------------------------------------------------------------------------\n');

data = UTrials.(varName); 
u = UTrials.Properties.VariableUnits{varName}; % Data units

iIschemia = UTrials.GroupID=="Ischemia";
iIntact = UTrials.GroupID=="Intact";
iSuccessful = UTrials.Outcome=="Successful";
iUnsuccessful = UTrials.Outcome=="Unsuccessful";
hasPellet = UTrials.PelletPresent=="Present";

mu = struct;
cb = struct;

% Output descriptive statistic for observations in Intact group
mu.Intact = struct;
cb.Intact = struct;
x = data(iIntact & hasPellet & iSuccessful);
mu.Intact.Successful = nanmean(x);
cb.Intact.Successful = analyze.stat.getCB95(x,true);

x = data(iIntact & hasPellet & iUnsuccessful);
mu.Intact.Unsuccessful = nanmean(x);
cb.Intact.Unsuccessful = analyze.stat.getCB95(x,true);

x = data(iIntact & hasPellet);
mu.Intact.All = nanmean(x);
cb.Intact.All = analyze.stat.getCB95(x,true);

fprintf(1,['Mean <strong>%s</strong> by Outcome:' ...
   '\t\t\t\t\t<strong>Intact</strong> (exclusions)\n'],...
   strrep(varName,'_',' '));
fprintf(1,'\tSuccessful\t\t->\t %4.2f (%s)\n',mu.Intact.Successful,u);
fprintf(1,'\tUnsuccessful\t->\t %4.2f (%s)\n',mu.Intact.Unsuccessful,u);
fprintf(1,'\t------------\n');
fprintf(1,'\t<strong>All</strong>\t\t\t\t->\t %4.2f (%s)\n\n',mu.Intact.All,u);
fprintf(1,['95%% Confidence Interval <strong>%s</strong> by Outcome:' ...
   '\t<strong>Intact</strong> (exclusions)\n'],...
   strrep(varName,'_',' '));
fprintf(1,'\tSuccessful\t\t->\t[%4.2f %4.2f] (%s)\n',cb.Intact.Successful,u);
fprintf(1,'\tUnsuccessful\t->\t[%4.2f %4.2f] (%s)\n',cb.Intact.Unsuccessful,u);
fprintf(1,'\t------------\n');
fprintf(1,'\t<strong>All</strong>\t\t\t\t->\t[%4.2f %4.2f] (%s)\n\n',cb.Intact.All,u);

% Output descriptive statistic for observations in Ischemia group
mu.Ischemia = struct;
cb.Ischemia = struct;
x = data(iIschemia & hasPellet & iSuccessful);
mu.Ischemia.Successful = nanmean(x);
cb.Ischemia.Successful = analyze.stat.getCB95(x,true);

x = data(iIschemia & hasPellet & iUnsuccessful);
mu.Ischemia.Unsuccessful = nanmean(x);
cb.Ischemia.Unsuccessful = analyze.stat.getCB95(x,true);

x = data(iIschemia & hasPellet);
mu.Ischemia.All = nanmean(x);
cb.Ischemia.All = analyze.stat.getCB95(x,true);

UTrials.Properties.UserData.Stats = struct;
UTrials.Properties.UserData.Stats.All.(varName) = struct;
UTrials.Properties.UserData.Stats.All.(varName).mu = mu;
UTrials.Properties.UserData.Stats.All.(varName).cb95 = cb;

fprintf(1,['Mean <strong>%s</strong> by Outcome:' ...
   '\t\t\t\t\t<strong>Ischemia</strong> (exclusions)\n'],...
   strrep(varName,'_',' '));
fprintf(1,'\tSuccessful\t\t->\t %4.2f (%s)\n',mu.Ischemia.Successful,u);
fprintf(1,'\tUnsuccessful\t->\t %4.2f (%s)\n',mu.Ischemia.Unsuccessful,u);
fprintf(1,'\t------------\n');
fprintf(1,'\t<strong>All</strong>\t\t\t\t->\t %4.2f (%s)\n\n',mu.Ischemia.All,u);
fprintf(1,['95%% Confidence Interval <strong>%s</strong> by Outcome:' ...
   '\t<strong>Ischemia</strong> (exclusions)\n'],...
   strrep(varName,'_',' '));
fprintf(1,'\tSuccessful\t\t->\t[%4.2f %4.2f] (%s)\n',cb.Ischemia.Successful,u);
fprintf(1,'\tUnsuccessful\t->\t[%4.2f %4.2f] (%s)\n',cb.Ischemia.Unsuccessful,u);
fprintf(1,'\t------------\n');
fprintf(1,'\t<strong>All</strong>\t\t\t\t->\t[%4.2f %4.2f] (%s)\n\n',cb.Ischemia.All,u);

% % Now, use exclusions based on trial duration exclusions from
% neurophysiological analyses % %
[min_dur,max_dur] = defaults.complete_analyses('min_duration','max_duration');
fprintf(1,'\n-----------------------------------------------------------------------------\n');
fprintf(1,'\t<strong>%s</strong>: Restrict durations to range [%d %d] (ms)\n',...
   strrep(varName,'_',' '),round(min_dur*1e3),round(max_dur*1e3));
fprintf(1,'-----------------------------------------------------------------------------\n');
iInclude = (UTrials.Duration >= min_dur) & (UTrials.Duration <= max_dur);
UTrials.Properties.UserData.Exclude = (~iInclude) | (~hasPellet) | iUnsuccessful;

% Output descriptive statistic for observations in Intact group
mu.Intact = struct;
cb.Intact = struct;
x = data(iIntact & hasPellet & iSuccessful & iInclude);
mu.Intact.Successful = nanmean(x);
cb.Intact.Successful = analyze.stat.getCB95(x,true);

x = data(iIntact & hasPellet & iUnsuccessful & iInclude);
mu.Intact.Unsuccessful = nanmean(x);
cb.Intact.Unsuccessful = analyze.stat.getCB95(x,true);

x = data(iIntact & hasPellet & iInclude);
mu.Intact.All = nanmean(x);
cb.Intact.All = analyze.stat.getCB95(x,true);

fprintf(1,['Mean <strong>%s</strong> by Outcome:' ...
   '\t\t\t\t\t<strong>Intact</strong> (exclusions)\n'],...
   strrep(varName,'_',' '));
fprintf(1,'\tSuccessful\t\t->\t %4.2f (%s)\n',mu.Intact.Successful,u);
fprintf(1,'\tUnsuccessful\t->\t %4.2f (%s)\n',mu.Intact.Unsuccessful,u);
fprintf(1,'\t------------\n');
fprintf(1,'\t<strong>All</strong>\t\t\t\t->\t %4.2f (%s)\n\n',mu.Intact.All,u);
fprintf(1,['95%% Confidence Interval <strong>%s</strong> by Outcome:' ...
   '\t<strong>Intact</strong> (exclusions)\n'],...
   strrep(varName,'_',' '));
fprintf(1,'\tSuccessful\t\t->\t[%4.2f %4.2f] (%s)\n',cb.Intact.Successful,u);
fprintf(1,'\tUnsuccessful\t->\t[%4.2f %4.2f] (%s)\n',cb.Intact.Unsuccessful,u);
fprintf(1,'\t------------\n');
fprintf(1,'\t<strong>All</strong>\t\t\t\t->\t[%4.2f %4.2f] (%s)\n\n',cb.Intact.All,u);

% Output descriptive statistic for observations in Ischemia group
mu.Ischemia = struct;
cb.Ischemia = struct;
x = data(iIschemia & hasPellet & iSuccessful & iInclude);
mu.Ischemia.Successful = nanmean(x);
cb.Ischemia.Successful = analyze.stat.getCB95(x,true);

x = data(iIschemia & hasPellet & iUnsuccessful & iInclude);
mu.Ischemia.Unsuccessful = nanmean(x);
cb.Ischemia.Unsuccessful = analyze.stat.getCB95(x,true);

x = data(iIschemia & hasPellet & iInclude);
mu.Ischemia.All = nanmean(x);
cb.Ischemia.All = analyze.stat.getCB95(x,true);

UTrials.Properties.UserData.Stats.Included.(varName) = struct;
UTrials.Properties.UserData.Stats.Included.(varName).mu = mu;
UTrials.Properties.UserData.Stats.Included.(varName).cb95 = cb;
fprintf(1,['Mean <strong>%s</strong> by Outcome:' ...
   '\t\t\t\t\t<strong>Ischemia</strong> (exclusions)\n'],...
   strrep(varName,'_',' '));
fprintf(1,'\tSuccessful\t\t->\t %4.2f (%s)\n',mu.Ischemia.Successful,u);
fprintf(1,'\tUnsuccessful\t->\t %4.2f (%s)\n',mu.Ischemia.Unsuccessful,u);
fprintf(1,'\t------------\n');
fprintf(1,'\t<strong>All</strong>\t\t\t\t->\t %4.2f (%s)\n\n',mu.Ischemia.All,u);
fprintf(1,['95%% Confidence Interval <strong>%s</strong> by Outcome:' ...
   '\t<strong>Ischemia</strong> (exclusions)\n'],...
   strrep(varName,'_',' '));
fprintf(1,'\tSuccessful\t\t->\t[%4.2f %4.2f] (%s)\n',cb.Ischemia.Successful,u);
fprintf(1,'\tUnsuccessful\t->\t[%4.2f %4.2f] (%s)\n',cb.Ischemia.Unsuccessful,u);
fprintf(1,'\t------------\n');
fprintf(1,'\t<strong>All</strong>\t\t\t\t->\t[%4.2f %4.2f] (%s)\n\n',cb.Ischemia.All,u);


end