function fig = epochSpikeFits(r,varName,T)
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

% varName = glme.ResponseName;
utils.addHelperRepos();

str = strrep(varName,'N_','');
str = strrep(str,'_',' ');
C = struct('Ischemia',...
      struct('RFA',[0.8 0.2 0.2],...
             'CFA',[1.0 0.4 0.4]), ...
          'Intact',...
       struct('RFA',[0.2 0.2 0.8],...
              'CFA',[0.4 0.4 1.0]));
                 
% % Generate groupings vectors % %
Z = r((~r.Properties.UserData.Excluded) & (r.Outcome=="Successful"),:);

% r(r.Properties.UserData.Excluded | r.Outcome=="Unsuccessful",:) = [];

% aGroupings = findgroups(r(:,{'AnimalID','Area','PostOpDay'}));

% dt = -0.5:0.25:0.5;
% nRep = 1000; 

% AnimalID = splitapply(@(x){x},r.AnimalID,aGroupings);
% AnimalID = vertcat(AnimalID{:});
% Area = splitapply(@(x){x},r.Area,aGroupings);
% Area = vertcat(Area{:});
% ChannelID = splitapply(@(x){x},r.ChannelID,aGroupings);
% ChannelID = vertcat(ChannelID{:});
% Group = splitapply(@(x){x},r.Group,aGroupings);
% Group = vertcat(Group{:});
% Reach_Epoch_Duration = cell2mat(splitapply(@(x){repmat(nanmean(x),numel(x),1)},r.Reach_Epoch_Duration,aGroupings));
% Retract_Epoch_Duration = cell2mat(splitapply(@(x){repmat(nanmean(x),numel(x),1)},r.Reach_Epoch_Duration,aGroupings));
% N_Pre_Grasp = cell2mat(splitapply(@(x){repmat(nanmean(x),numel(x),1)},r.N_Pre_Grasp,aGroupings));
% poDay = cell2mat(splitapply(@(x){x},r.PostOpDay,aGroupings));

% Z = [];
% SD_reach = nanstd(Reach_Epoch_Duration);
% SD_retract = nanstd(Retract_Epoch_Duration);
% for iT = 1:numel(dt)
%    PostOpDay = poDay + dt(iT);
%    Zhat = table(AnimalID,Area,ChannelID,Group,N_Pre_Grasp,PostOpDay,Reach_Epoch_Duration,Retract_Epoch_Duration);
%    Zhat.(varName) = random(glme,Zhat);
%    Z = [Z; Zhat]; %#ok<AGROW>
% end

[Groupings,TID] = findgroups(Z(:,{'Group','Area'}));

% Make Partial Dependence Plot (PDP) figure for Reach Fraction
fig = figure(...
   'Name',sprintf('Trends in spike count: %s',str),...
   'Color','w',...
   'Units','Normalized',...
   'Position',[0.3 0.3 0.4 0.4]);


if ischar(T)
   [z,x] = splitapply(@(x,y,t)getXY(x,y,t),Z.PostOpDay,Z.(varName),Z.(T),Groupings);
else
   [z,x] = splitapply(@(x,y)getXY(x,y,T),Z.PostOpDay,Z.(varName),Groupings);
end

nTotal = size(TID,1);
nCol = floor(sqrt(nTotal));
nRow = ceil(nTotal/nCol);
ax = gobjects(nTotal,1);
for ii = 1:nTotal
   c = C.(string(TID.Group(ii))).(string(TID.Area(ii)));
   titleStr = sprintf('%s::%s',char(TID.Group(ii)),char(TID.Area(ii)));
   ax(ii) = subplot(nRow,nCol,ii);
   set(ax(ii),'NextPlot','add','XColor','k','YColor','k',...
      'LineWidth',1.5,'FontName','Arial','Parent',fig);
   
   
   ylim(ax(ii),[0 40]);
   xlim(ax(ii),[0 30]);
   ylabel(ax(ii),sprintf('\\surdspikes/sec (%s)',str),...
      'FontName','Arial','Color','k');
   xlabel(ax(ii),'Days from Surgery',...
      'FontName','Arial','Color','k');
   title(ax(ii),titleStr,...
      'FontName','Arial','Color','k');
   
%    zThis = Z(Groupings==ii,:);
%    zThis = zThis(sz{ii},:); % Get correct order (by days)
%    z = [];
%    nG = size(zThis,1);
%    fprintf(1,'Generating <strong>%s</strong> surrogates (%s)...%03d%%\n',titleStr,varName,0);
%    curPct = 0;
%    for iRep = 1:nRep
%       zhat = zThis;
%       zhat.Reach_Epoch_Duration = min(max(zhat.Reach_Epoch_Duration + randn(nG,1).*SD_reach,0.1),0.75);
%       zhat.Retract_Epoch_Duration = min(max(zhat.Retract_Epoch_Duration + randn(nG,1).*SD_retract,0.1),0.75);
%       z = [z; predict(glme,zhat)./t{ii}]; %#ok<AGROW>
%       thisPct = round(iRep/nRep*100);
%       if thisPct - curPct >= 5
%          fprintf(1,'\b\b\b\b\b%03d%%\n',thisPct);
%          curPct = thisPct;
%       end
%    end
%    [ix,xx] = findgroups(repmat(zThis.PostOpDay,nRep,1));
%    mu = splitapply(@nanmean,z,ix);
%    cb = cell2mat(splitapply(@analyze.stat.getCB95,z,ix));
%    gfx__.plotWithShadedError(ax(ii),xx,mu,cb);   
%    [ix,xx] = findgroups(zThis.PostOpDay);
   [ix,xx] = findgroups(x{ii});
   mu = splitapply(@nanmean,z{ii},ix);
   cb95 = cell2mat(splitapply(@analyze.stat.getCB95,z{ii},ix));
   
   xq = (min(xx):max(xx))';
   muq = interp1(xx,mu,xq,'makima');
   cb95q = interp1(xx,cb95,xq,'makima');
   
   muq = sgolayfilt(muq,5,7,ones(1,7),1);
   cb95q = sgolayfilt(cb95q,5,7,ones(1,7),1);
   
   gfx__.plotWithShadedError(ax(ii),xq,muq,cb95q,...
      'FaceColor',c,...
      'DisplayName',str,...
      'Annotation','on',...
      'LineWidth',2.5); 
   
   zMu = nan(1,4);
   zMu(1) = nanmean(z{ii}(x{ii} < 7.5));
   zMu(2) = nanmean(z{ii}((x{ii} >= 7.5) & (x{ii} < 14.5)));
   zMu(3) = nanmean(z{ii}((x{ii} >= 14.5) & (x{ii} < 21.5)));
   zMu(4) = nanmean(z{ii}((x{ii} >= 21.5) & (x{ii} < 28.5)));
   line(ax(ii),[6,13,20,27],zMu,'LineStyle','none','Marker','s',...
      'MarkerFaceColor','m','MarkerEdgeColor','none','MarkerSize',12,...
      'DisplayName','Mean');
   text(ax(ii),6,0.15*ax(ii).YLim(2),sprintf('%5.1f',zMu(1)),...
      'Color','k','FontName','Arial',...
      'BackgroundColor','none','FontWeight','bold','HorizontalAlignment','center');
   text(ax(ii),13,0.15*ax(ii).YLim(2),sprintf('%5.1f',zMu(2)),...
      'Color','k','FontName','Arial',...
      'BackgroundColor','none','FontWeight','bold','HorizontalAlignment','center');
   text(ax(ii),20,0.15*ax(ii).YLim(2),sprintf('%5.1f',zMu(3)),...
      'Color','k','FontName','Arial',...
      'BackgroundColor','none','FontWeight','bold','HorizontalAlignment','center');
   text(ax(ii),27,0.15*ax(ii).YLim(2),sprintf('%5.1f',zMu(4)),...
      'Color','k','FontName','Arial',...
      'BackgroundColor','none','FontWeight','bold','HorizontalAlignment','center');
end
suptitle(sprintf('All Successful %s',str));
       

   function [z,x] = getXY(x,y,t)
      %GETXY Return x-y coordinates for plotting or averaging
      %
      %  [z,x] = getXY(x,t);
      %
      % Inputs
      %  x  - PostOpDay
      %  t  - Epoch duration (fixed or same # elements as n)
      %
      % Output
      %  z  - Spike rate
      %  x  - Sorted PostOpDay
      
      [x,sz] = sort(x,'ascend');
      x = {x};
      z = sqrt(y)./t;
      z = {z(sz)};
   end
end