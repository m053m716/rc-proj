function data_table(T,fname)
%DATA_TABLE  Write spike rate time-series data table to excel files
%
%  write.rate.data_table(T,fname);
%
%  -- Inputs --
%  T :         Result from `T = getRateTable(gData,`align`);`
%                 * Should only be a single "align" at a time (2020-04-29)
%  fname :     File name of excel spreadsheet to write 
%
%  Note: this function is to export for viewing in `Tableau` software

if nargin < 2
   fname = defaults.files('rate_tableau_table');
end

% Split up table
T.Properties.DimensionNames{1} = 'Trial ID';
Meta = T(:,[1:12,18,19]);
Events = T(:,11:15);
Data = T(:,20);
Time = milliseconds(T.Properties.UserData.t).';
TT = table(Time);
Locations = make.location_table(T);

% Rate = T.Rate.';
% Data = timetable(Time,Rate);
% TT = repmat(Time,size(T,1),1);
% TT = table(Time,'RowNames',T.Properties.RowNames);


% Make sure the variable names stay in alphabetical order (e.g. not Rate_1
% ... Rate_10, Rate_11, ... Rate_100, etc)
Data = splitvars(Data,'Rate');
for i = 1:numel(Data.Properties.VariableNames)
   rateName = sprintf('Rate_%02g',i);
   Data.Properties.VariableNames{i} = rateName;
   TT.Properties.RowNames{i} = rateName;
end

% First, write a .mat file containing the row names of the Table, in case
% we want to retrieve the matching row names for future export of a
% different table:
RowNames = T.Properties.RowNames;
[p,f,~] = fileparts(fname);
% Match the filename, and indicate .mat filename that this file contains
% "__RowNames" so we can easily get the correctly-associated row key
save(fullfile(p,[f '__RowNames.mat']),'RowNames','-v7.3');


tic;
fprintf(1,'Writing %s::<strong>Times</strong>...',f);
writetable(TT,fname,...
   'WriteRowNames',true,...
   'Sheet','Times');
sounds__.play('pop',1.1,-15);
fprintf(1,'complete\n');

fprintf(1,'Writing %s::<strong>Locations</strong>...',f);
writetable(Locations,fname,...
   'WriteRowNames',true,...
   'Sheet','Locations');
sounds__.play('pop',1.0,-15);
fprintf(1,'complete\n');

fprintf(1,'Writing %s::<strong>Recording Metadata</strong>...',f);
writetable(Meta,fname,...
   'WriteRowNames',true,...
   'Sheet','Meta');
fprintf(1,'complete\n');
sounds__.play('pop',0.9,-15);

fprintf(1,'Writing %s::<strong>Trial Metadata</strong>...',f);
writetable(Events,fname,...
   'WriteRowNames',true,...
   'Sheet','Events');
sounds__.play('pop',0.8,-15);
fprintf(1,'complete\n');

fprintf(1,'Writing %s::<strong>Time-Series</strong>...',f);
writetable(Data,fname,...
   'WriteRowNames',true,...
   'Sheet','Rate');
sounds__.play('bell',1.0,-15);
fprintf(1,'complete\n\n\t');
toc;

end