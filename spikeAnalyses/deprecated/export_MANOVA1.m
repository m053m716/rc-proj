if exist('x','var')==0
   load('All-Days-Successful-Grasp-All-Groups-All-Channels-xPCobj_No-Groups.mat','x','y');
end

X = x.X;

g1 = {x.ChannelInfo.Group}.';
g2 = {x.ChannelInfo.area}.';
g = cell(size(g1));
for i = 1:numel(g1)
   g{i} = [g1{i} '-' g2{i}((end-2):end)];
end

[d,p,stats] = manova1(X',g');
figure('Name','MANOVA-1: GROUP * AREA',...
   'NumberTitle','off',...
   'Color','w',...
   'Units','Normalized',...
   'Position',[0.25 0.2 0.3 0.6]);

manovacluster(stats);
ylabel('Group Mean Mahalanobis Distance','FontName','Arial','Color','k','FontSize',16);
