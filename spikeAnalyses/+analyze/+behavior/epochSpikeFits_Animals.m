function fig = epochSpikeFits_Animals(r,varName,T)
%EPOCHSPIKEFITS_Animals Plot smoothed model trends in spike rate for given epoch (split by Area/Group)
%
%  fig = analyze.behavior.epochSpikeFits_Animals(r,varName);
%  fig = analyze.behavior.epochSpikeFits_Animals(r,varName,T);
%  fig = analyze.behavior.epochSpikeFits_Animals(r,varName,timeVarName);
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
[Groupings,TID] = findgroups(Z(:,{'Group','Area'}));

% Make Partial Dependence Plot (PDP) figure for Reach Fraction
fig = figure(...
   'Name',sprintf('Trends in spike count: %s',str),...
   'Color','w',...
   'Units','Normalized',...
   'Position',[0.3 0.3 0.4 0.4]);


if ischar(T)
   [z,x,sz] = splitapply(@(x,y,t)getXY(x,y,t),Z.PostOpDay,Z.(varName),Z.(T),Groupings);
else
   [z,x,sz] = splitapply(@(x,y)getXY(x,y,T),Z.PostOpDay,Z.(varName),Groupings);
end

nTotal = size(TID,1);
nCol = floor(sqrt(nTotal));
nRow = ceil(nTotal/nCol);
ax = gobjects(nTotal,1);
for ii = 1:nTotal
   c = C.(string(TID.Group(ii))).(string(TID.Area(ii)));
   rThis = r(Groupings==ii,:);
   rThis = rThis(sz{ii},:);
   [gAnimals,tidAnimals] = findgroups(rThis(:,'AnimalID'));
   
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
   
   for iG = 1:max(gAnimals)
      idx = gAnimals==iG;
      xThis = x{ii}(idx);
      zThis = z{ii}(idx);
      [ix,xx] = findgroups(xThis);
      mu = splitapply(@nanmean,zThis,ix);
      cb95 = cell2mat(splitapply(@analyze.stat.getCB95,zThis,ix));

      xq = (min(xx):max(xx))';
      muq = interp1(xx,mu,xq,'spline');
      cb95q = interp1(xx,cb95,xq,'spline');

      muq = sgolayfilt(muq,3,7,ones(1,7),1);
      cb95q = sgolayfilt(cb95q,3,7,ones(1,7),1);

      gfx__.plotWithShadedError(ax(ii),xq,muq,cb95q,...
         'FaceColor',c,...
         'DisplayName',string(tidAnimals.AnimalID(iG)),...
         'FaceAlpha',0.45,...
         'Annotation','on',...
         'LineWidth',2.5); 
   end
end
suptitle(sprintf('All Successful %s',str));
       

   function [z,x,sz] = getXY(x,y,t)
      %GETXY Return x-y coordinates for plotting or averaging
      %
      %  [z,x,sz] = getXY(x,t);
      %
      % Inputs
      %  x  - PostOpDay
      %  t  - Epoch duration (fixed or same # elements as n)
      %
      % Output
      %  z  - Spike rate
      %  x  - Sorted PostOpDay
      %  sz - Sorting indices
      
      [x,sz] = sort(x,'ascend');
      x = {x};
      z = sqrt(y)./t;
      z = {z(sz)};
      sz = {sz};
   end
end