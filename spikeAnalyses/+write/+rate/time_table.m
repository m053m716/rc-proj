function TT = time_table(T,fileName,sheetName)
%TIME_TABLE  Write table with matched Time-series relative sample times
%
%  write.rate.time_table(T);
%  TT = write.rate.time_table(T,fileName,sheetName);
%
%  -- Inputs --
%  T : Table from `T = getRateData(gData,`align`);`
%     -> Note: T should have the same RowNames as whatever is used in the
%     other "All Rates.xlsx" spreadsheet towards the Tableau table, so they
%     can be matched accordingly.
%
%  fileName : (Optional) Name of spreadsheet to save
%
%  sheetName : (Optional) Name of sheet in file to save
%
%  -- Output --
%  TT : (Optional) Output to be saved to file. If this output is requested,
%                    the file is not written by default (so nothing will be
%                    saved if you request an output argument).

[def_file,def_sheet] = defaults.group(...
   'default_rowtimes_file','default_rowtimes_sheet');

if nargin < 3
   sheetName = def_sheet;
end

if nargin < 2
   fileName = def_file;
end

tic;
t = T.Properties.UserData.t;
nSamples = numel(t);

Time = repmat(t,size(T,1),1);
TT = table(Time);
TT = splitvars(TT,'Time');
desc = cell(1,nSamples);
for i = 1:nSamples
   rateName = sprintf('Rate_%02g',i);
   desc{i} = sprintf('Time (ms) at bin center for %s',rateName);
   timeName = sprintf('Time_%02g',i);
   TT.Properties.VariableNames{i} = timeName;
   TT.Properties.VariableUnits{i} = 'ms';
end
TT.Properties.RowNames = T.Properties.RowNames;
TT.Properties.VariableDescriptions = desc;
TT.Properties.Description = '1:1 Table of relative sample times';
TT.Properties.DimensionNames{1} = 'Trial ID (Sample Times)';

if nargout > 0
   sounds__.play('pop',1.2,-20);
   toc;
   return;
else
   writetable(TT,fileName,...
      'Sheet',sheetName,...
      'WriteRowNames',true);
   clear TT;
   sounds__.play('pop',0.7,-10);
   toc;
end

end