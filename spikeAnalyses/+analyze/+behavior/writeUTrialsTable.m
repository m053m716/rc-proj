function T = writeUTrialsTable(UTrials)
%WRITEUTTRIALSTABLE Write/return table with descriptive Duration stats
%
%  T = analyze.behavior.writeUTrialsTable(UTrials);
%
% Inputs
%  UTrials - Table returned by analyze.rec.getUTrials, which contains only
%            unique trial elements as well as the UserData struct field
%            'Stats', which has sub-struct fields that get turned into the
%            table variables of output `T`
%
% Output
%  T       - Table that is also saved in output table file
%              TABLE-DURATIONS.xlsx
%
% See also: analyze.behavior, analyze.rec.getUTrials

VARS = {'Subset','GroupID','Outcome','Variable','Mean','LB_95','UB_95'};
ISCAT = [true, true, true, true, false, false, false];
UNITS = struct(...
   'Duration','sec',...
   'Reach_Epoch_Duration','sec',...
   'Retract_Epoch_Duration','sec',...
   'Reach_Epoch_Proportion','fraction');

stats = UTrials.Properties.UserData.Stats;
inc = fieldnames(stats);  % "All" or "Included"
v = fieldnames(stats.(inc{1}));     % "Duration" etc
x = fieldnames(stats.(inc{1}).(v{1})); % "mu" or "cb95"
g = fieldnames(stats.(inc{1}).(v{1}).(x{1})); % "Intact" or "Ischemia"
o = fieldnames(stats.(inc{1}).(v{1}).(x{1}).(g{1})); % "Successful" "Unsuccessful" "All"
T = [];
for ii = 1:numel(inc)
   
   for ig = 1:numel(g)
      for io = 1:numel(o)
         for iv = 1:numel(v)
            for ix = 1:numel(x)
               switch x{ix}
                  case 'mu'
                     mu = string(...
                        sprintf('%5.3f (%s)',...
                           stats.(inc{ii}).(v{iv}).(x{ix}).(g{ig}).(o{io}),...
                           UNITS.(v{iv})) ...
                           );
                  case 'cb95'
                     lb95 = string(...
                        sprintf('%5.3f (%s)',...
                           stats.(inc{ii}).(v{iv}).(x{ix}).(g{ig}).(o{io})(1), ...
                           UNITS.(v{iv})) ...
                           );
                     ub95 = string(...
                        sprintf('%5.3f (%s)',...
                           stats.(inc{ii}).(v{iv}).(x{ix}).(g{ig}).(o{io})(2), ...
                           UNITS.(v{iv})) ...
                           );
                  otherwise
                     warning('Unrecognized field: %s',x{ix});
               end
            end
            T = [T; ...
               table(string(inc{ii}),string(g{ig}),string(o{io}),string(strrep(v{iv},'_',' ')),...
                  mu,lb95,ub95,...
                  'VariableNames',VARS)]; %#ok<AGROW>
         end
      end
      
   end
end

for iVar = 1:numel(VARS)
   if ISCAT(iVar)
      T.(VARS{iVar}) = categorical(T.(VARS{iVar}));
   end
end
T.Properties.UserData = struct(...
   'isCategorical',ISCAT,...
   'Units',UNITS,...
   'N_Trials',struct('All',size(UTrials,1),...
                     'Included',sum(~UTrials.Properties.UserData.Excluded)));

outfile = defaults.files('utrials_durations_table');
% if exist(outfile,'file')~=0
%    delete(outfile);
% end
G = findgroups(T.Subset);
splitapply(@(varargin)writetable(table(varargin{:},'VariableNames',VARS),...
                                 outfile,...
                                 'Sheet',string(varargin{1}(1))),...
           T,G);

end