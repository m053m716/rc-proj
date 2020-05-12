function [Td,S,Cs] = plotProj3D(J,planeNum,rowNum)

COL = {'b';'r'};

if nargin < 3
   rowNum = 1:size(J,1);
end

if nargin < 2
   planeNum = 1;
end

if numel(rowNum) > 1
   Td = cell(numel(rowNum),1);
   S = cell(size(Td));
   Cs = cell(size(Td));
   for ii = 1:numel(rowNum)
      [Td{ii},S{ii},Cs{ii}] = plotProj3D(J,planeNum,rowNum(ii));
   end
   return;
end

d1 = (planeNum-1)*2 + 1;
d2 = planeNum*2;

fig = figure('Name',sprintf('%s: 3D jPCA Projections',J.Name{rowNum}),...
   'Color','w',...
   'Units','Normalized',...
   'Position',[0.2 0.1 0.3 0.65]);
Z = cat(3,J.Data(rowNum).Projection.proj);
T = J.Data(rowNum).Projection(1).times;
subplot(2,1,1);
X = cell(2,1);
for ii = 1:numel(COL)
   idx = J.Data(rowNum).Summary.outcomes==ii;
   if sum(idx)==0
      Td = [];
      S = [];
      Cs = [];
      delete(fig);
      return;
   end
   plot3(T,...
      squeeze(Z(:,d1,idx)),...
      squeeze(Z(:,d2,idx)),...
      'LineWidth',0.5,'Color',COL{ii},'LineStyle',':'); hold on;
   X{ii}(:,1) = mean(squeeze(Z(:,d1,idx)),2);
   X{ii}(:,2) = mean(squeeze(Z(:,d2,idx)),2);
   plot3(T,X{ii}(:,1),X{ii}(:,2),...
      'LineWidth',2.5,'Color',COL{ii});
end

title(sprintf('%s: Post-Op D%g 3D jPCA Projections',...
   J.Rat{rowNum},J.PostOpDay(rowNum)),'FontName','Arial','FontSize',16,'Color','k');
xlabel('Time (ms)','FontName','Arial','FontSize',14,'Color','k');
ylabel(sprintf('jPC-%g',d1),'FontName','Arial','FontSize',14,'Color','k');
zlabel(sprintf('jPC-%g',d2),'FontName','Arial','FontSize',14,'Color','k');


dX = cell(1,2);
dX{1} = diff(X{1});
dX{1} = [dX{1}(1,:); dX{1}];
dX{2} = diff(X{2});
dX{2} = [dX{2}(1,:); dX{2}];

Cs = nan(numel(T),1);
for ii = 1:numel(T)
   Cs(ii) = getCosineSimilarity(dX{1}(ii,:),dX{2}(ii,:));
end
% [~,idx] = min(Cs);
[~,idx] = findpeaks(-Cs);

scatter3(T(idx),X{1}(idx,1),X{1}(idx,2),40,'k','Marker','o','LineWidth',2);
scatter3(T(idx),X{2}(idx,1),X{2}(idx,2),40,'k','Marker','o','LineWidth',2);


subplot(2,1,2);
plot(T,Cs,'Color','r','LineWidth',1.5); hold on;
scatter(T(idx),Cs(idx),40,'k','Marker','o','LineWidth',2);
xlabel('Time (ms)','FontName','Arial','FontSize',14,'Color','k');
ylabel('Cosine Similarity','FontName','Arial','FontSize',14,'Color','k');
ylim([-1 1]);

Td = T(idx);
S = Cs(idx);

out_folder = defaults.jPCA('preview_folder');
out_folder = fullfile(pwd,out_folder,'Divergence',J.Align{rowNum},...
   J.Group{rowNum},J.Rat{rowNum});
if exist(out_folder,'dir')==0
   mkdir(out_folder);
end

jpca_start_stop_times = defaults.jPCA('jpca_start_stop_times');
fname = sprintf('%s_%s_PostOpDay-%g_%gms_to_%g_ms_jPCA-Plane-%g',...
   J.Rat{rowNum},J.Align{rowNum},...
   J.PostOpDay(rowNum),jpca_start_stop_times(1),jpca_start_stop_times(2),...
   planeNum);

savefig(fig,fullfile(out_folder,[fname '.fig']));
saveas(fig,fullfile(out_folder,[fname '.png']));
delete(gcf);

end