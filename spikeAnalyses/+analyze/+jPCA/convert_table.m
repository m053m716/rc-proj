function [Data,T,TID,CID] = convert_table(T,align,area,varargin)
%CONVERT_TABLE Converts from table format to jPCA struct array format
%
% Data = analyze.jPCA.convert_table(T);
% Data = analyze.jPCA.convert_table(T,align,area);
% [Data,T,TID,CID] = analyze.jPCA.convert_table(T,align,area,...
%                 'slice_var1',slice_val1,...);
%
% Inputs
%  T        - Data table, such as returned by `T = getRateTable(gData);`
%  align    - (Optional) Alignment event (default: "Grasp")
%  area     - (Optional) Area (default: "All")
%  varargin - (Optional) <'Name',value> pairs: `analyze.slice(T,varargin);`
%              -> Determines what Blocks get included in Data output.
%              -> Can also specify one of the pairs as 
%                 <'t_lims',[lower_bound, upper_bound]> to set the bounding
%                 of time limits, which is usually returned from
%                 `defaults.jPCA('t_lims');`
%
% Output
%  Data     - Struct array, such as required by `analyze.jPCA.jPCA(Data)`
%  T        - (Optional output); in case you want result of slice filters 
%              for convenience.
%  TID      - (Optional output); groupings metadata for each row of the
%                 table -- potentially useful for labeling things.
%  CID      - (Optional output); groupings metadata for channels
%
% See Also:    analyze.jPCA.jPCA, analyze.jPCA.multi_jPCA

if isempty(T)
   Data = struct(...
      'AnimalID',{},...
      'Trial_ID',{},...
      'Alignment',{},...
      'Area',{},...
      'Group',{},...
      'Outcome',{},...
      'PostOpDay',{},...
      'Duration',{},...
      'tReach',{},...
      'tGrasp',{},...
      'tSupport',{},...
      'tComplete',{},...
      'A',{},...
      'times',{}...
      );
   warning('off','MATLAB:table:PreallocateCharWarning');
   TID = table('Size',[0,3],...
      'VariableType',{'char','categorical','categorical'},...
      'VariableNames',{'Trial_ID','Alignment','Outcome'});
   warning('on','MATLAB:table:PreallocateCharWarning');
   fprintf(1,...
      ['\n\t\t->\tTried to convert from <strong>empty</strong> table.\n' ...
       '\t\t\t\t(Returned empty arrays)\n']);
   return;
end

if nargin < 2
   align = "Grasp";
elseif isempty(align)
   align = "Grasp"; 
end

if nargin < 3
   area = "All";
elseif isempty(area)
   area = "All";
end

[t_lims,sg_ord,sg_wlen,interp_method,dt] = defaults.jPCA(...
   't_lims','sg_ord','sg_wlen','interp_method','dt');

% % Check from input args % %
% Check `t_lims` parameter %
check_opts= {'t_lims','t_lim','tlim','tlims'};
[varargin,update] = check_input_opts(varargin,check_opts);
if ~isempty(update)
   t_lims = update;
end

% Check `sg_ord` parameter %
check_opts = {'sg_ord','sgord','ord'};
[varargin,update] = check_input_opts(varargin,check_opts);
if ~isempty(update)
   sg_ord = update;
end

% Check `sg_wlen` parameter %
check_opts = {'sg_wlen','sgwlen','wlen'};
[varargin,update] = check_input_opts(varargin,check_opts);
if ~isempty(update)
   sg_wlen = update;
end

% Check `interp_method` parameter %
check_opts = {'interp','interp_method','interpmethod','interpolation'};
[varargin,update] = check_input_opts(varargin,check_opts);
if ~isempty(update)
   interp_method = update;
end

% Check `interp_method` parameter %
check_opts = {'dt','period','binwidth','bin'};
[varargin,update] = check_input_opts(varargin,check_opts);
if ~isempty(update)
   dt = update;
end

% Parse times to be included %
times_mask = (T.Properties.UserData.t >= t_lims(1)) & ...
             (T.Properties.UserData.t <= t_lims(2));
t = T.Properties.UserData.t(times_mask).';
tq = (t(1):dt:t(end)).'; % "Query" times

switch upper(area)
   case "ALL"
      T = analyze.slice(T,'Alignment',align,varargin{:});
   otherwise
      T = analyze.slice(T,'Alignment',align,'Area',area,varargin{:});
end

uTrial = unique(T.Trial_ID);

% Want to make sure we have channels with equal # of trials (meaning that
% the channel can be expected for each condition). Also want to ensure that
% we have 
cid_vars = {'Alignment','ChannelID', ... % main grouping variables
   'ProbeID','AnimalID','Area','ML','ICMS','X','Y'}; % for metadata/labels
[G_pre,CID] = findgroups(T(:,cid_vars));
CID.Properties.Description = 'Channel information/metadata';
CID.Properties.VariableUnits = {...
   '','','','','','','Evoked Movement','mm','mm'...
   };
CID.Properties.UserData = struct('type','ChannelInfo');
nTrial = splitapply(@(tid)sum(ismember(uTrial,tid)),T.Trial_ID,G_pre);
iRemove = find(nTrial ~= max(nTrial));
T(ismember(G_pre,iRemove),:) = [];

[G,TID] = findgroups(...
   T(:,union({'AnimalID','Trial_ID','Alignment'},...
   varargin(1:2:end))));
TID = movevars(TID,{'AnimalID','Trial_ID','Alignment'},'Before',1);
T.Properties.UserData.jPCA = struct;
T.Properties.UserData.jPCA.mask = times_mask;
T.Properties.UserData.jPCA.t = tq;
T.Properties.UserData.jPCA.key = ["Unsuccessful";... % Outcome == 1
                                  "Successful"];     % Outcome == 2

[~,iLeft,iRight] = outerjoin(T,TID);
[~,uIdx] = unique(iRight);
iTrial = iLeft(uIdx);
AnimalID = cellstr(string(T.AnimalID(iTrial)));
Alignment = cellstr(string(T.Alignment(iTrial)));
Area = upper(string(area));
Group = cellstr(string(T.Group(iTrial)));
Outcome = T.Outcome(iTrial);
Outcome = num2cell((Outcome=='Successful')+1);
PostOpDay = num2cell(T.PostOpDay(iTrial));
Duration = num2cell(T.Duration(iTrial)*1e3);
tReach = num2cell((T.Reach(iTrial)-T.(align)(iTrial))*1e3);
tGrasp  = num2cell((T.Grasp(iTrial)-T.(align)(iTrial))*1e3);
tSupport = num2cell((T.Support(iTrial)-T.(align)(iTrial))*1e3);
tComplete = num2cell((T.Complete(iTrial)-T.(align)(iTrial))*1e3);


% Rate times are currently columns, but need to be rows (so transpose);
% groupings will grab Channels (which become columns) as appropriate
Rate = splitapply(@(rate){rate(:,times_mask).'},T.Rate,G);

% Apply interpolation, as defined in `fcn`:
if ~isnan(sg_ord) && ~isnan(sg_wlen)
   fcn = @(rate)interp1(t,...
                        sgolayfilt(rate,sg_ord,sg_wlen,ones(1,sg_wlen),1),...
                        tq,...
                        interp_method);
else
   fcn = @(rate)interp1(t,rate,tq,interp_method);
end
A = cellfun(@(C)fcn(C),Rate,'UniformOutput',false);

% Make sure the function itself is stored with the returned data table:
T.Properties.UserData.jPCA.InterpFcn = fcn;

Data = struct(...
   'AnimalID',AnimalID,...
   'Trial_ID',TID.Trial_ID,...
   'Alignment',Alignment,...
   'Area',Area,...
   'Group',Group,...
   'Outcome',Outcome,...
   'PostOpDay',PostOpDay,...
   'Duration',Duration,...
   'tReach',tReach,...
   'tGrasp',tGrasp,...
   'tSupport',tSupport,...
   'tComplete',tComplete,...
   'A',A,...
   'times',[]...
   );

[Data.times] = deal(tq);
utils.addHelperRepos();
fprintf(1,...
   '\n\t\t->\tTable conversion for <strong>jPCA</strong> complete.\n');
sounds__.play('pop',1.5,-15);

   function [opts,update] = check_input_opts(opts,check_opts)
      %CHECK_INPUT_OPTS  Check input options against some list of opts
      %
      %  [opts,update] = check_input_opts(opts,check_opts);
      %
      %  Inputs
      %     opts        - Cell array from input `varargin`
      %     check_opts  - Options to check for from input list
      %
      %  Output
      %     opts        - Updated opts list
      %     update      - Updated variable of interest 
      %                    -> If not found, then this is returned as []
      
      i_char = find(cellfun(@(C)ischar(C),opts));
      i_opt = i_char(ismember(lower(opts(i_char)),check_opts));
      if isempty(i_opt)
         update = [];
      else
         update = opts{i_opt+1};
         opts(i_opt:(i_opt+1)) = []; % Remove "used" <'Name',value> pair
      end
   end
end