function data_table(T,fname,metaVars,eventVars)
%DATA_TABLE  Write spike rate time-series data table to excel files
%
%  write.rate.data_table(T);
%  write.rate.data_table(T,fname);
%  write.rate.data_table(T,fname,metaVars,eventVars);
%
%  -- Inputs --
%  T :         Result from `T = getRateTable(gData,`align`);`
%                 * Should only be a single "align" at a time (2020-04-29)
%  fname :     File name of excel spreadsheet to write 
%              -> If not specified: `defaults.files('rate_tableau_table')`
%
%  metaVars :  Cell array of "Meta" table variables 
%                 -> (has default if not specified)
%
%  eventVars : Cell array of "Event" table variables 
%                 -> (has default if not specified)
%
%  Note: this function is to export for viewing in `Tableau` software

if nargin < 2
   fname = defaults.files('rate_tableau_table');
end

if nargin < 3
   metaVars = defaults.experiment('meta_vars');
end

if nargin < 4
   eventVars = defaults.experiment('event_vars');
end

% Split up table
T.Properties.DimensionNames{1} = 'Series_ID';
varNames = T.Properties.VariableNames;
metaIdx = ismember(varNames,metaVars);
evtIdx = ismember(varNames,eventVars);

Meta = T(:,metaIdx);
Events = T(:,evtIdx);

data = T.Rate;
Time = milliseconds(T.Properties.UserData.t).';
TT = table(Time);
Locations = make.location_table(T);

% Data = table(T.Rate);
% Rate = T.Rate.';
% Data = timetable(Time,Rate);
% TT = repmat(Time,size(T,1),1);
% TT = table(Time,'RowNames',T.Properties.RowNames);
% Data = splitvars(Data,'Rate');

% Make sure the variable names stay in alphabetical order (e.g. not Rate_1
% ... Rate_10, Rate_11, ... Rate_100, etc)
Data = table.empty;
% for i = 1:numel(Data.Properties.VariableNames)
for i = 1:size(data,2)
   rateName = sprintf('Rate_%03g',i);
   Data = [Data, table(data(:,i),'VariableNames',{rateName})]; %#ok<AGROW>
%    Data.Properties.VariableNames{i} = rateName;
   TT.Properties.RowNames{i} = rateName;
end
Data.Properties.DimensionNames{1} = 'Series_ID';
Data.Properties.RowNames = T.Properties.RowNames;

% First, write a .mat file containing the row names of the Table, in case
% we want to retrieve the matching row names for future export of a
% different table:
RowNames = T.Properties.RowNames;
[p,f,e] = fileparts(fname);
% Match the filename, and indicate .mat filename that this file contains
% "__RowNames" so we can easily get the correctly-associated row key
save(fullfile(p,[f '__RowNames.mat']),'RowNames','-v7.3');

warning('off','MATLAB:xlswrite:AddSheet');
tic;
sNames = defaults.files('tableau_spreadsheet_tag_struct');
ff = [f sNames.Times e];
fprintf(1,'Writing %s::<strong>Times</strong>...',ff);
writetable(TT,fullfile(p,ff),...
   'WriteRowNames',true,...
   'Sheet','Times');
sounds__.play('pop',1.1,-15);
fprintf(1,'complete\n');

ff = [f sNames.Locations e];
fprintf(1,'Writing %s::<strong>Locations</strong>...',ff);
writetable(Locations,fullfile(p,ff),...
   'WriteRowNames',true,...
   'Sheet','Locations');
sounds__.play('pop',1.0,-15);
fprintf(1,'complete\n');

ff = [f sNames.Meta e];
fprintf(1,'Writing %s::<strong>Meta</strong>...',ff);
writetable(Meta,fullfile(p,ff),...
   'WriteRowNames',true,...
   'Sheet','Meta');
fprintf(1,'complete\n');
sounds__.play('pop',0.9,-15);

ff = [f sNames.Events e];
fprintf(1,'Writing %s::<strong>Events</strong>...',ff);
writetable(Events,fullfile(p,ff),...
   'WriteRowNames',true,...
   'Sheet','Events');
sounds__.play('pop',0.8,-15);
fprintf(1,'complete\n');

ff = [f sNames.Rates e];
fprintf(1,'Writing %s::<strong>Rate</strong>...',ff);
writetable(Data,fullfile(p,ff),...
   'WriteRowNames',true,...
   'Sheet','Rate');
sounds__.play('bell',1.0,-15);
fprintf(1,'complete\n\n\t');
toc;
warning('on','MATLAB:xlswrite:AddSheet');
end