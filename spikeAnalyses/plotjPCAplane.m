function fig = plotjPCAplane(J,rowIdx,planeIdx,align,outcome,area,labels)
%% PLOT_JPCA_PLANE_COMPONENTS    Plot X,dX; Y,dY in 4 separate subplots
%
%  fig = PLOT_JPCA_PLANE_COMPONENTS(J,rowIdx,planeIdx);
%
% By: Max Murphy  v1.0  2019-06-14  Original version (R2017a)

%% PARSE INPUT
if nargin < 6
   area = 'Full';
end

if nargin < 5
   outcome = 'Successful';
end

if nargin < 4
   align = 'Grasp';
end

%%
dim1 = (planeIdx-1)*2+1;
dim2 = dim1 + 1;

Projection = J.Data(rowIdx).(align).(outcome).jPCA.(area).Projection;

if nargin < 7
   labels = J.Data(rowIdx).(align).(outcome).jPCA.(area).Summary.outcomes;
end

%%
fig = figure('Name',sprintf('%s: jPCA Plane-%d',J.Name{rowIdx},planeIdx),...
   'Color','w',...
   'Units','Normalized',...
   'Position',[0.1 0.1 0.8 0.8]);

for ii = 1:numel(Projection)
   subplot(2,2,1);
   plot_Val(Projection,ii,dim1,labels);
   hold on;
   subplot(2,2,2);
   plot_dVal(Projection,ii,dim1,labels);
   hold on;
   subplot(2,2,3);
   plot_Val(Projection,ii,dim2,labels);
   hold on;
   subplot(2,2,4);
   plot_dVal(Projection,ii,dim2,labels);
   hold on;
end

subplot(2,2,1);
xlabel('Time (ms)','FontName','Arial','FontSize',14,'Color','k');
ylabel('jPC1','FontName','Arial','FontSize',14,'Color','k');

subplot(2,2,2);
xlabel('Time (ms)','FontName','Arial','FontSize',14,'Color','k');
ylabel('\DeltajPC1','FontName','Arial','FontSize',14,'Color','k');

subplot(2,2,3);
xlabel('Time (ms)','FontName','Arial','FontSize',14,'Color','k');
ylabel('jPC2','FontName','Arial','FontSize',14,'Color','k');

subplot(2,2,4);
xlabel('Time (ms)','FontName','Arial','FontSize',14,'Color','k');
ylabel('\DeltajPC2','FontName','Arial','FontSize',14,'Color','k');

   function plot_dVal(proj,index,dim,labels)
      COLS = {'b';'r'};       
      plot(proj(index).times(2:end),...
           diff(proj(index).proj(:,dim)),...
           'Color',COLS{labels(index)},...
           'LineWidth',1.5);
   end

   function plot_Val(proj,index,dim,labels)
      COLS = {'k';[0.4 0.4 0.4]};
      plot(proj(index).times,...
           proj(index).proj(:,dim),...
           'Color',COLS{labels(index)},...
           'LineWidth',1.5);
      ylim([-0.4 0.4]);
   end

end