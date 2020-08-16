function fig = epochSpikeFits_Split(r,glme,T)
%EPOCHSPIKEFITS_SPLIT Plot smoothed model trends in spike rate for given epoch (split by animal)
%
%  fig = analyze.behavior.epochSpikeFits_Split(r,glme);
%  fig = analyze.behavior.epochSpikeFits_Split(r,glme,T);
%  fig = analyze.behavior.epochSpikeFits_Split(r,glme,timeVarName);
%
% Inputs
%  r           - Rate table with .Excluded UserData field, for Grasp
%                 alignment, where .Rate is binned spike counts.
%  glme        - Generalized Linear Mixed-Effects model for this epoch
%  T           - Duration of epoch (seconds)
%     OR
%  timeVarName - Name of variable with duration of epoch (per trial)
%
% Output
%  fig         - Figure handle
%
% See also: analyze.behavior, analyze.behavior.epochSpikeTrends_Split,
%           unit_learning_stats

varName = glme.ResponseName;

str = strrep(varName,'N_','');
str = strrep(str,'_',' ');

% % Generate groupings vectors % %
r(r.Properties.UserData.Excluded | r.Outcome=="Unsuccessful",:) = [];

aGroupings = findgroups(r(:,{'AnimalID','Area','PostOpDay'}));

dt = -0.5:0.1:0.5;

AnimalID = splitapply(@(x){x},r.AnimalID,aGroupings);
AnimalID = vertcat(AnimalID{:});
Area = splitapply(@(x){x},r.Area,aGroupings);
Area = vertcat(Area{:});
ChannelID = splitapply(@(x){x},r.ChannelID,aGroupings);
ChannelID = vertcat(ChannelID{:});
Group = splitapply(@(x){x},r.Group,aGroupings);
Group = vertcat(Group{:});
Reach_Epoch_Duration = cell2mat(splitapply(@(x){repmat(nanmean(x),numel(x),1)},r.Reach_Epoch_Duration,aGroupings));
Retract_Epoch_Duration = cell2mat(splitapply(@(x){repmat(nanmean(x),numel(x),1)},r.Reach_Epoch_Duration,aGroupings));
N_Pre_Grasp = cell2mat(splitapply(@(x){repmat(nanmean(x),numel(x),1)},r.N_Pre_Grasp,aGroupings));
poDay = cell2mat(splitapply(@(x){x},r.PostOpDay,aGroupings));

Z = [];
for iT = 1:numel(dt)
   PostOpDay = poDay + dt(iT);
   Z = [Z; table(AnimalID,Area,ChannelID,Group,N_Pre_Grasp,PostOpDay,Reach_Epoch_Duration,Retract_Epoch_Duration)];
end
[z,Z.cb] = predict(glme,Z);
[Groupings,TID] = findgroups(Z(:,{'Group','Area'}));

% Make Partial Dependence Plot (PDP) figure for Reach Fraction
fig = figure(...
   'Name',sprintf('Trends in spike count: %s',str),...
   'Color','w',...
   'Units','Normalized',...
   'Position',[0.3 0.3 0.4 0.4]);


if ischar(T)
   [~,y,sz] = splitapply(@(x,n,t)getXY(x,n,t),Z.PostOpDay,z,Z.(T),Groupings);
else
   [~,y,sz] = splitapply(@(x,n)getXY(x,n,T),Z.PostOpDay,z,Groupings);
end

nTotal = size(TID,1);
nCol = floor(sqrt(nTotal));
nRow = ceil(nTotal/nCol);
ax = gobjects(nTotal,1);
for ii = 1:nTotal
   ax(ii) = subplot(nRow,nCol,ii);
   set(ax(ii),'NextPlot','add','XColor','k','YColor','k',...
      'LineWidth',1.5,'FontName','Arial','Parent',fig);
   
   
   ylim(ax(ii),[0 150]);
   xlim(ax(ii),[0 30]);
   ylabel(ax(ii),sprintf('spikes/sec (%s)',str),...
      'FontName','Arial','Color','k');
   xlabel(ax(ii),'Days from Surgery',...
      'FontName','Arial','Color','k');
   title(ax(ii),sprintf('%s::%s',string(TID.Group(ii)),string(TID.Area(ii))),...
      'FontName','Arial','Color','k');
   
   zThis = Z(Groupings==ii,:);
   zThis = zThis(sz{ii},:); % Get correct order (by days)
   uA = unique(zThis.AnimalID);
   
   h = gobjects(numel(uA),1);
   for iA = 1:numel(uA)
      iThis = zThis.AnimalID==uA(iA);
      aThis = zThis(iThis,:);
      [ix,xx] = findgroups(aThis.PostOpDay);
      mu = splitapply(@nanmean,y{ii}(iThis),ix);
      cb = cell2mat(splitapply(@analyze.stat.getCB95,y{ii}(iThis),ix));
      h(iA) = gfx__.plotWithShadedError(ax(ii),xx,mu,cb);
   end
   
end
suptitle(sprintf('All Successful %s',str));
       

   function [x,y,sz] = getXY(x,n,t)
      %GETXY Return x-y coordinates for plotting or averaging
      %
      %  [x,y,sz] = getXY(x,n,t);
      %
      % Inputs
      %  x  - PostOpDay + jitter
      %  n  - Number of spikes (same # elements as x)
      %  t  - Epoch duration (fixed or same # elements as n)
      %
      % Output
      %  x  - PostOpDay + jitter (cell)
      %  y  - Square-root transformed spike rate (cell)
      %  sz - Sort (based on epoch duration; cell)
      
      [x,sz] = sort(x,'ascend');
      x = {x};
      if isscalar(t)
         y = {n(sz)./t};
      else
         y = {n(sz)./t(sz)};
      end
      sz = {sz};
   end
end