function T = getRateTable(obj,align,includeStruct,area)
%GETRATETABLE  Returns table of per-trial rate trajectories
%
%  T = getRateTable(obj);
%  * Note: Default behavior is to construct FULL table of
%     alignments. Specify optional arguments in case you want to
%     save space or speed up pulling a subset of the table.
%
%  T = getRateTable(obj,align,includeStruct,area);
%
%  -- Inputs --
%  obj : `rat` class object
%
%  align :  'Reach','Grasp','Complete','Support' or cell
%           combination of some of those options
%  -> Default is {'Reach','Grasp'}
%  -> Can set as [] to set later argument while retaining defaults.
%
%  includeStruct: see: `utils.makeIncludeStruct`
%  -> Default (if not specified) is
%     {utils.makeIncludeStruct({'Reach','Grasp','Complete','Outcome'},[]);
%      utils.makeIncludeStruct({'Reach','Grasp','Complete'},{'Outcome'})}
%  -> If set as [], retains default values.
%
%  area : 'RFA', 'CFA', or {'RFA','CFA'} (which areas to pull)
%  -> Default is {'RFA','CFA'} (pulls channels from both areas)
%  -> If set as [], retains default values.
%
%  -- Output --
%  T : Table wherein each row contains metadata as well as the rate values
%      for a single channel on a single trial from a single recording.
%        -> If `obj` is a single `rat`, then the table will contain all
%            such rows matching the other agument specifications, for that
%            animal, from all "child" `block` objects.
%        -> If `obj` is an array of `rat`, then the tables returned by each
%           `rat` are concatenated vertically.

if nargin < 4
   area = {'RFA','CFA'};
elseif isempty(area)
   area = {'RFA','CFA'};
elseif ~iscell(area)
   area = {area};
end

if nargin < 3
   includeStruct = defaults.experiment('rate_table_includes');
elseif isempty(includeStruct)
   includeStruct = defaults.experiment('rate_table_includes');
elseif ~iscell(includeStruct)
   includeStruct = {includeStruct};
end

if nargin < 2
   align = {'Reach','Grasp'};
elseif isempty(align)
   align = {'Reach','Grasp'};
elseif ~iscell(align)
   align = {align};
end

if numel(obj) > 1
   T = table.empty;
   for i = 1:numel(obj)
      fprintf(1,'Parsing %s...',obj(i).Name);
      T = [T; getRateTable(obj(i),align,includeStruct,area)];
      fprintf(1,'complete\n');
   end
   return;
end

hasTime = false;
t = [];

nChild = numel(obj.Children);
nAlign = numel(align);
nArea = numel(area);
nInclude = numel(includeStruct);

id = strsplit(obj.Name,'-');
id = str2double(id{end});

[rat_ids,rat_names,icms_all,area_all,ml_all,align_all] = ...
   defaults.experiment(...
   'rat_id','rat',...
   'icms_opts','area_opts','ml_opts','event_opts'...
   );

PostOpDay = [];
BlockID = [];
ML = [];
ICMS = [];
Area = [];
Alignment = [];
Rate = [];
Probe = [];
Channel = [];
Trial_ID = [];
Reach = [];
Grasp = [];
Support = [];
Complete = [];
PelletPresent = [];
Outcome = [];
for ii = 1:nChild
   for iAlign = 1:nAlign
      for iArea = 1:nArea
         for iInc = 1:nInclude
            if ~hasTime % Only assign `t` once
               [rate,flag_exists,flag_isempty,t,~,...
                  b,channelInfo] = getRate(obj.Children(ii),...
                  align{iAlign},'All',area{iArea},includeStruct{iInc});
               if flag_exists && ~flag_isempty
                  hasTime = true;
               end
            else
               [rate,~,~,~,~,b,channelInfo] = getRate(obj.Children(ii),...
                  align{iAlign},'All',area{iArea},includeStruct{iInc});
            end
            nCh = size(rate,3);
            nTrial = size(rate,1);
            nRow = nTrial * nCh;
            if nRow == 0
               continue;
            end
            % Day: Same for each element
            PostOpDay = [PostOpDay; ...
               repmat(obj.Children(ii).PostOpDay,nRow,1)]; %#ok<*AGROW>
            % Block: Same for all members of this iteration
            BlockID = [BlockID; ...
               repmat(30*id+ii,nRow,1)];
            % Area: Same for all members of this iteration
            Area = [Area; repmat(area(iArea),nRow,1)];
            % Alignment: Same for all memebers of this iteration
            Alignment = [Alignment; repmat(align(iAlign),nRow,1)];
            
            % Mediolateral Location: Repeated  [1,1,1,...2,2,2....]
            ml = reshape({channelInfo.ml},1,nCh);
            ml = repmat(ml,nTrial,1);
            ML = [ML; ml(:)];
            % ICMS: Repeated channels info [1,1,1,...2,2,2....]
            icms = reshape({channelInfo.icms},1,nCh);
            icms = repmat(icms,nTrial,1);
            ICMS = [ICMS; icms(:)];
            % Channel Index: Repeated  [1,1,1,...2,2,2....]
            channel = reshape([channelInfo.channel],1,nCh);
            channel = repmat(channel,nTrial,1);
            Channel = [Channel; channel(:)];
            % Probe Index: Repeated  [1,1,1,...2,2,2....]
            probe = reshape([channelInfo.probe],1,nCh);
            probe = repmat(probe,nTrial,1);
            Probe = [Probe; probe(:)];
            
            % Trial ID: Repeated  [1,2,3,...1,2,3...]
            Trial_ID = [Trial_ID; ...
               repmat(b.Properties.RowNames,nCh,1)];
            
            % Reach (ts; sec): Repeated  [1,2,3,...1,2,3...]
            Reach = [Reach; repmat(b.Reach,nCh,1)];
            % Grasp (ts; sec): Repeated  [1,2,3,...1,2,3...]
            Grasp = [Grasp; repmat(b.Grasp,nCh,1)];
            % Support (ts; sec): Repeated  [1,2,3,...1,2,3...]
            Support = [Support; repmat(b.Support,nCh,1)];
            % Complete (ts; sec): Repeated  [1,2,3,...1,2,3...]
            Complete = [Complete; repmat(b.Complete,nCh,1)];
            
            % Pellet Present flag: Repeated  [1,2,3,...1,2,3...]
            PelletPresent = [PelletPresent; ...
               repmat(b.PelletPresent,nCh,1)];
            % Success flag: Repeated  [1,2,3,...1,2,3...]
            Outcome = [Outcome; repmat(b.Outcome,nCh,1)];
            
            % Concatenate so columns are timesteps, rows are
            % channel/trial combinations.
            r = permute(rate,[3 1 2]);
            Rate = [Rate; reshape(r(:),nTrial*nCh,size(rate,2))];
         end
      end
   end
end
% Get unique channel ID for each animal
ChannelID = Channel + (Probe - 1).*16 + (32*id);
% Get unique probe ID for each animal
ProbeID = Probe + 2*id;
AnimalID = repmat(id,numel(BlockID),1);
AnimalID = categorical(AnimalID,rat_ids,rat_names);
ICMS = categorical(ICMS,icms_all);
ML = categorical(ML,ml_all);
Area = categorical(Area,area_all);
Alignment = categorical(Alignment,align_all);
T = table(Trial_ID,AnimalID,BlockID,PostOpDay,Alignment,...
   ML,ICMS,Area,ProbeID,Probe,ChannelID,Channel,...
   Reach,Grasp,Support,Complete, ...
   PelletPresent,Outcome,Rate);
T.Properties.UserData = struct('t',t);

end