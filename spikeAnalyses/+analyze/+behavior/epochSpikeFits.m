function fig = epochSpikeFits(r,glme,T)
%EPOCHSPIKEFITS Plot smoothed model trends in spike rate for given epoch (split by Area/Group)
%
%  fig = analyze.behavior.epochSpikeFits(r,glme);
%  fig = analyze.behavior.epochSpikeFits(r,glme,T);
%  fig = analyze.behavior.epochSpikeFits(r,glme,timeVarName);
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
utils.addHelperRepos();

str = strrep(varName,'N_','');
str = strrep(str,'_',' ');

% % Generate groupings vectors % %
r(r.Properties.UserData.Excluded | r.Outcome=="Unsuccessful",:) = [];

aGroupings = findgroups(r(:,{'AnimalID','Area','PostOpDay'}));

dt = -0.5:0.25:0.5;
nRep = 1000; 

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
SD_reach = nanstd(Reach_Epoch_Duration);
SD_retract = nanstd(Retract_Epoch_Duration);
for iT = 1:numel(dt)
   PostOpDay = poDay + dt(iT);
   Z = [Z; table(AnimalID,Area,ChannelID,Group,N_Pre_Grasp,PostOpDay,Reach_Epoch_Duration,Retract_Epoch_Duration)]; %#ok<AGROW>
end

[Groupings,TID] = findgroups(Z(:,{'Group','Area'}));

% Make Partial Dependence Plot (PDP) figure for Reach Fraction
fig = figure(...
   'Name',sprintf('Trends in spike count: %s',str),...
   'Color','w',...
   'Units','Normalized',...
   'Position',[0.3 0.3 0.4 0.4]);


if ischar(T)
   [t,sz] = splitapply(@(x,t)getXY(x,t),Z.PostOpDay,Z.(T),Groupings);
else
   [t,sz] = splitapply(@(x)getXY(x,T),Z.PostOpDay,Groupings);
end

nTotal = size(TID,1);
nCol = floor(sqrt(nTotal));
nRow = ceil(nTotal/nCol);
ax = gobjects(nTotal,1);
for ii = 1:nTotal
   titleStr = sprintf('%s::%s',char(TID.Group(ii)),char(TID.Area(ii)));
   ax(ii) = subplot(nRow,nCol,ii);
   set(ax(ii),'NextPlot','add','XColor','k','YColor','k',...
      'LineWidth',1.5,'FontName','Arial','Parent',fig);
   
   
   ylim(ax(ii),[0 150]);
   xlim(ax(ii),[0 30]);
   ylabel(ax(ii),sprintf('spikes/sec (%s)',str),...
      'FontName','Arial','Color','k');
   xlabel(ax(ii),'Days from Surgery',...
      'FontName','Arial','Color','k');
   title(ax(ii),titleStr,...
      'FontName','Arial','Color','k');
   
   zThis = Z(Groupings==ii,:);
   zThis = zThis(sz{ii},:); % Get correct order (by days)
   z = [];
   nG = size(zThis,1);
   fprintf(1,'Generating <strong>%s</strong> surrogates (%s)...%03d%%\n',titleStr,varName,0);
   curPct = 0;
   for iRep = 1:nRep
      zhat = zThis;
      zhat.Reach_Epoch_Duration = min(max(zhat.Reach_Epoch_Duration + randn(nG,1).*SD_reach,0.1),0.75);
      zhat.Retract_Epoch_Duration = min(max(zhat.Retract_Epoch_Duration + randn(nG,1).*SD_retract,0.1),0.75);
      z = [z; predict(glme,zhat)./t{ii}]; %#ok<AGROW>
      thisPct = round(iRep/nRep*100);
      if thisPct - curPct >= 5
         fprintf(1,'\b\b\b\b\b%03d%%\n',thisPct);
         curPct = thisPct;
      end
   end
   [ix,xx] = findgroups(repmat(zThis.PostOpDay,nRep,1));
   mu = splitapply(@nanmean,z,ix);
   cb = cell2mat(splitapply(@analyze.stat.getCB95,z,ix));
   gfx__.plotWithShadedError(ax(ii),xx,mu,cb);   
end
suptitle(sprintf('All Successful %s',str));
       

   function [t,sz] = getXY(x,t)
      %GETXY Return x-y coordinates for plotting or averaging
      %
      %  [x,y,sz] = getXY(x,t);
      %
      % Inputs
      %  x  - PostOpDay
      %  t  - Epoch duration (fixed or same # elements as n)
      %
      % Output
      %  t  - Duration
      %  sz - Sort (based on epoch duration; cell)
      
      [~,sz] = sort(x,'ascend');
      if isscalar(t)
         t = {repmat(t,numel(sz),1)};
      else
         t = {t(sz)};
      end
      sz = {sz};
   end
end