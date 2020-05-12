function fig = plotCrossDayChannelActivations(stats,propName,ratName)
%% PLOTCROSSDAYCHANNELACTIVATIONS



%%
if nargin < 3
   ratName = unique(stats.Rat);
end

if nargin < 2
   propName = 'maxRate';
elseif ~ismember(propName,stats.Properties.VariableNames)
   error('%s is not a valid table variable for table STATS.',propName);
end

if iscell(ratName)
   for ii = 1:numel(ratName)
      fig = [];
      if nargout > 0
         fig = [fig; plotCrossDayChannelActivations(stats,propName,ratName{ii})]; %#ok<*AGROW>
      else
         plotCrossDayChannelActivations(stats,propName,ratName{ii});
      end
   end
   return;
end

%%
s = screenStats(stats,ratName); % get subset

xData = s.PostOpDay;
yData = s.channel + (s.probe-1)*2;
X = meshgrid(min(xData):max(xData),min(yData):max(yData));

xSubs = yData - min(yData) + 1;
ySubs = xData - min(xData) + 1;

% C = zeros(size(X,1),size(X,2),3);
% li = sub2ind(size(C),xSubs,ySubs,ones(size(xSubs))*3);
% C(li) = s.(propName)./max(s.(propName));
% 
% li = sub2ind(size(C),xSubs,ySubs,ones(size(xSubs)));
% C(li) = 1 - s.Score;

C = nan(size(X));
li = sub2ind(size(C),xSubs,ySubs);
C(li) = s.(propName);


fig = figure('Name',sprintf('%s: %s',ratName,propName),...
   'Units','Normalized',...
   'Position',[0.35+randn(1)*0.02,0.35+randn(1)*0.02,0.35,0.35],...
   'Color','w');

imagesc([min(xData),max(xData)],[min(yData),max(yData)],C);
set(gca,'YTick',[]);
xlabel('Post-Op Day','FontName','Arial','FontSize',14,'Color','k');
title(sprintf('%s: %s',ratName,propName),'FontName','Arial','FontSize',16,'Color','k');

colormap('jet');
colorbar;

end