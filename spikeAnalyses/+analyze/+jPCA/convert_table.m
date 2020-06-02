function [Data,T,TID] = convert_table(T,align,varargin)
%CONVERT_TABLE Converts from table format to jPCA struct array format
%
% Data = analyze.jPCA.convert_table(T);
% Data = analyze.jPCA.convert_table(T,t_lims);
% [Data,T,TID] = analyze.jPCA.convert_table(T,'slice_var1',slice_val1,...);
%
% Inputs
%  T        - Data table, such as returned by `T = getRateTable(gData);`
%  t_lims   - (Optional) 2-element vector of [lower,upper] bounds on times
%              -> Units should be in milliseconds (relative to alignment)
%              -> Default: [-1000 750] (set [] to use default)
%  varargin - (Optional) <'Name',value> pairs: `analyze.slice(T,varargin);`
%              -> Determines what Blocks get included in Data output.
%
% Output
%  Data     - Struct array, such as required by `analyze.jPCA.jPCA(Data)`
%  T        - (Optional output); in case you want result of slice filters 
%              for convenience.
%  TID      - (Optional output); groupings metadata for each row of the
%                 table -- potentially useful for labeling things.

if isempty(T)
   Data = struct('Trial_ID',{},...
      'A',{},'times',{},...
      'Alignment',{},...
      'Outcome',{},...
      'Duration',{},...
      'tReach',{},...
      'tGrasp',{},...
      'tSupport',{},...
      'tComplete',{});
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
   align = 'Grasp';
elseif isempty(align)
   align = 'Grasp';
elseif ischar(align)
   if ~ismember(lower(align),{'reach','grasp'})
      varargin = [align, varargin];
      align = 'Grasp';
   end   
end
t_lims = defaults.jPCA('t_lims');
times_mask = (T.Properties.UserData.t >= t_lims(1)) & ...
             (T.Properties.UserData.t <= t_lims(2));
t = T.Properties.UserData.t(times_mask).';
                         
dt = defaults.jPCA('dt');
tq = (t(1):dt:t(end)).'; % "Query" times

T = analyze.slice(T,'Alignment',align,varargin{:});
uTrial = unique(T.Trial_ID);

% Want to make sure we have channels with equal # of trials (meaning that
% the channel can be expected for each condition).
G_pre = findgroups(T(:,{'Trial_ID','Alignment','ChannelID'}));
nTrial = splitapply(@(tid)sum(ismember(uTrial,tid)),T.Trial_ID,G_pre);
iRemove = find(nTrial ~= mode(nTrial));
T(ismember(G_pre,iRemove),:) = [];

[G,TID] = findgroups(T(:,union({'Trial_ID','Alignment'},varargin(1:2:end))));
TID = movevars(TID,{'Trial_ID','Alignment'},'Before',1);
fcn = @(rate)interp1(t,sgolayfilt(rate,3,9,hamming(9),1),tq,'spline');
T.Properties.UserData.jPCA = struct;
T.Properties.UserData.jPCA.InterpFcn = fcn;
T.Properties.UserData.jPCA.mask = times_mask;
T.Properties.UserData.jPCA.t = tq;
T.Properties.UserData.jPCA.key = {'Unsuccessful';'Successful'};

[~,iLeft,iRight] = outerjoin(T,TID);
[~,uIdx] = unique(iRight);
iTrial = iLeft(uIdx);
Outcome = T.Outcome(iTrial);
Outcome = num2cell((Outcome=='Successful')+1);
Alignment = cellstr(char(T.Alignment(iTrial)));
Duration = num2cell(T.Duration(iTrial)*1e3);
tReach = num2cell((T.Reach(iTrial)-T.(align)(iTrial))*1e3);
tGrasp  = num2cell((T.Grasp(iTrial)-T.(align)(iTrial))*1e3);
tSupport = num2cell((T.Support(iTrial)-T.(align)(iTrial))*1e3);
tComplete = num2cell((T.Complete(iTrial)-T.(align)(iTrial))*1e3);


% Rate times are currently columns, but need to be rows (so transpose);
% groupings will grab Channels (which become columns) as appropriate
Rate = splitapply(@(rate){rate(:,times_mask).'},T.Rate,G);
A = cellfun(@(C)fcn(C),Rate,'UniformOutput',false);

Data = struct('Trial_ID',TID.Trial_ID,...
   'A',A,'times',[],...
   'Alignment',Alignment,...
   'Outcome',Outcome,...
   'Duration',Duration,...
   'tReach',tReach,...
   'tGrasp',tGrasp,...
   'tSupport',tSupport,...
   'tComplete',tComplete);

[Data.times] = deal(tq);
utils.addHelperRepos();
fprintf(1,...
   '\n\t->\tTable conversion for <strong>jPCA</strong> complete.\n');
sounds__.play('pop',1.5,-15);
end