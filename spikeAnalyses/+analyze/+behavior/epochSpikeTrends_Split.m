function fig = epochSpikeTrends_Split(r,glme,T)
%EPOCHSPIKETRENDS_SPLIT Plot trends in spike rate for given epoch (split panels)
%
%  fig = analyze.behavior.epochSpikeTrends_Split(r,glme);
%  fig = analyze.behavior.epochSpikeTrends_Split(r,glme,T);
%  fig = analyze.behavior.epochSpikeTrends_Split(r,glme,timeVarName);
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
% See also: analyze.behavior, unit_learning_stats

varName = glme.ResponseName;

str = strrep(varName,'N_','');
str = strrep(str,'_',' ');

% % Generate groupings vectors % %
r(r.Properties.UserData.Excluded | r.Outcome=="Unsuccessful",:) = [];
% z = r.(varName);
z = predict(glme,r);

[Groupings,TID] = findgroups(r(:,{'Group','Area'}));
% Make Partial Dependence Plot (PDP) figure for Reach Fraction
fig = figure(...
   'Name',sprintf('Trends in spike count: %s',str),...
   'Color','w',...
   'Units','Normalized',...
   'Position',[0.3 0.3 0.4 0.4]);


if ischar(T)
   [x,y,sz,z] = splitapply(@(x,n,t,z)getXY(x,n,t,z),r.PostOpDay,r.(varName),r.(T),z,Groupings);
else
   [x,y,sz,z] = splitapply(@(x,n,z)getXY(x,n,T,z),r.PostOpDay,r.(varName),z,Groupings);
end

nTotal = size(TID,1);
nCol = floor(sqrt(nTotal));
nRow = ceil(nTotal/nCol);
ax = gobjects(nTotal,1);
for ii = 1:nTotal
   ax(ii) = subplot(nRow,nCol,ii);
   set(ax(ii),'NextPlot','add','XColor','k','YColor','k',...
      'LineWidth',1.5,'FontName','Arial','Parent',fig);
   c = ax(ii).ColorOrder(ii,:);
   scatter(ax(ii),x{ii},z{ii},...
      'DisplayName','Predicted',...
      'Marker','o',...
      'LineWidth',1,...
      'MarkerEdgeColor','k',...
      'MarkerFaceColor','none',...
      'MarkerEdgeAlpha',0.25,...
      'SizeData',sz{ii});
   scatter(ax(ii),x{ii},y{ii},'filled',...
      'DisplayName','Observed',...
      'Marker','o',...
      'MarkerEdgeColor','none',...
      'MarkerFaceColor',c,...
      'MarkerFaceAlpha',0.25,...
      'SizeData',sz{ii});
   
   yMu = nan(1,3);
   yMu(1) = nanmean(y{ii}(x{ii} < 7.5));
   yMu(2) = nanmean(y{ii}((x{ii} >= 7.5) & (x{ii} < 14.5)));
   yMu(3) = nanmean(y{ii}((x{ii} >= 14.5) & (x{ii} < 21.5)));
   line(ax(ii),[4,11,18],yMu,'LineStyle','none','Marker','s',...
      'MarkerFaceColor','m','MarkerEdgeColor','none','MarkerSize',12,...
      'DisplayName','Mean');
   legend(ax(ii),...
      'TextColor','k','FontName','Arial','AutoUpdate','off',...
      'Location','northoutside');
   
   
   ylim(ax(ii),[0 150]);
   xlim(ax(ii),[0 30]);
   ylabel(ax(ii),sprintf('spikes/sec (%s)',str),...
      'FontName','Arial','Color','k');
   xlabel(ax(ii),'Days from Surgery',...
      'FontName','Arial','Color','k');
   title(ax(ii),sprintf('%s::%s',string(TID.Group(ii)),string(TID.Area(ii))),...
      'FontName','Arial','Color','k');
   
   rThis = r(Groupings==ii,:);
   uA = unique(rThis.AnimalID);
   
   for iA = 1:numel(uA)
      iThis = rThis.AnimalID==uA(iA);
      aThis = rThis(iThis,:);
      [ix,xx] = findgroups(aThis.PostOpDay);
      zz = splitapply(@nanmean,z{ii}(iThis),ix);
      [xx,isort] = sort(xx,'ascend');
      zz = zz(isort);
      line(ax(ii),xx,zz,'LineStyle','-','LineWidth',1.5,'Color','k','Tag',string(uA(iA)));
   end
   text(ax(ii),4,125,sprintf('%5.1f',yMu(1)),...
      'Color','k','FontName','Arial',...
      'BackgroundColor','w','FontWeight','bold');
   text(ax(ii),11,125,sprintf('%5.1f',yMu(2)),...
      'Color','k','FontName','Arial',...
      'BackgroundColor','w','FontWeight','bold');
   text(ax(ii),18,125,sprintf('%5.1f',yMu(3)),...
      'Color','k','FontName','Arial',...
      'BackgroundColor','w','FontWeight','bold');
   
end
suptitle(sprintf('All Successful %s',str));
       

   function [x,y,sz,z] = getXY(x,n,t,z)
      %GETXY Return x-y coordinates for plotting or averaging
      %
      %  [x,y,sz,z] = getXY(x,n,t,z);
      %
      % Inputs
      %  x  - PostOpDay + jitter
      %  n  - Number of spikes (same # elements as x)
      %  t  - Epoch duration (fixed or same # elements as n)
      %  z  - Model-predicted values at jittered x-values
      %
      % Output
      %  x  - PostOpDay + jitter (cell)
      %  y  - Square-root transformed spike rate (cell)
      %  sz - Size (based on epoch duration; cell)
      %  z  - Same as input, but cell
      
      x = {x+randn(size(n)).*0.15};
      y = {n./t};
      z = {z./t};
      if isscalar(t)
         sz = {ones(size(n)).*5};
      else
         sz = {max(3,t.*10)};
      end
   end
end