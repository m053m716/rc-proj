function fig = plotProj3D_unified(J,planeNum,Rat,tag)
%% PLOTPROJ3D_UNIFIED   Plot jPCA trajectories across days in single plane through time in 3D and highlight points of maximal deviation from ensemble average.
%
%  PLOTPROJ3D_UNIFIED(J);
%  fig = PLOTPROJ3D_UNIFIED(J,planeNum,Rat);
%
%  --------
%   INPUTS
%  --------
%     J        :     (only required input) Table returned by GETJPCA method
%                       of GROUP class object.
%
%   planeNum   :     Index of jPCA plane to use for selecting jPC pair
%
%    Rat       :     Name of rat (or cell array of rat names) to plot.
%
%    tag       :     (Optional) tag to add to saved filename
%
%  --------
%   OUTPUT
%  --------
%    fig       :     Figure handle. If not requested, figure is
%                       automatically deleted (but saved locally). Useful
%                       for loops.
%
% By: Max Murphy  v1.0  2019-06-20  Original version (R2017a)

%%
if nargin < 4
   tag = J.Align{1};
end

if nargin < 3
   Rat = unique(J.Rat);
end

if nargin < 2
   planeNum = 1;
end

if iscell(Rat)
   fig = [];
   for ii = 1:numel(Rat)
      if nargout < 1
         plotProj3D_unified(J,planeNum,Rat{ii},tag);
      else
         fig = [fig; plotProj3D_unified(J,planeNum,Rat{ii},tag)]; %#ok<*AGROW>
      end
   end
   return;
end

d1 = (planeNum-1)*2 + 1;
d2 = planeNum*2;

fig = figure('Name',sprintf('%s: 3D jPCA Projections Across Days',Rat),...
   'Color','w',...
   'Units','Normalized',...
   'Position',[0.2 0.1 0.3 0.65],...
   'NumberTitle','off',...
   'ToolBar','none',...
   'MenuBar','none');

J = J(ismember(J.Rat,Rat),:);
T = J.Data(1).Projection(1).times;

Z = cell(size(J,1),1);
X = nan(numel(T),2,size(J,1));
dX = nan(size(X));

% Cs = cell(size(Z));
% S = cell(size(Z));

cm = flipud(redgreencmap(size(J,1)));

legText = [];
for rowNum = 1:size(J,1)
   Z{rowNum} = cat(3,J.Data(rowNum).Projection.proj);

   idx = J.Data(rowNum).Summary.outcomes==1;
   if sum(idx)==0
      continue;
   end
   
   X(:,1,rowNum) = nanmean(squeeze(Z{rowNum}(:,d1,idx)),2);
   X(:,2,rowNum) = nanmean(squeeze(Z{rowNum}(:,d2,idx)),2);
   plot3(T,X(:,1,rowNum),X(:,2,rowNum),...
      'LineWidth',2.5,'Color',cm(rowNum,:)); hold on;
%    legText = [legText; {sprintf('PO-Day: %g',J.PostOpDay(rowNum))}];
   legText = [legText; {num2str(J.PostOpDay(rowNum))}];
   dX(2:end,:,rowNum) = diff(X(:,:,rowNum));
   dX(1,:,rowNum) = dX(2,:,rowNum);
   
end
if numel(legText) > 10
   fontSize = 10;
   o = 'Vertical';
   loc = 'northeast';
else % used to be a difference but this should work
   fontSize = 10;
   o = 'Vertical';
   loc = 'northeast';
end
lgd = legend(legText,...
   'Location',loc,...
   'Box','off',...
   'AutoUpdate','off',...
   'FontName','Arial',...
   'Color','k',...
   'FontSize',fontSize,...
   'FontWeight','bold',...
   'Orientation',o);
lgd.Title.String = 'Post-Op Day';
lgd.Title.FontSize = 16;
lgd.Title.FontWeight = 'bold';

title(sprintf('%s: Mean 3D jPCA Projections All Days',Rat),...
   'FontName','Arial','FontSize',16,'Color','k');
xlabel('Time (ms)','FontName','Arial','FontSize',14,'Color','k');
ylabel(sprintf('jPC-%g',d1),'FontName','Arial','FontSize',14,'Color','k');
zlabel(sprintf('jPC-%g',d2),'FontName','Arial','FontSize',14,'Color','k');

xlim([min(T) max(T)]);
ylim([-1 1]);
zlim([-1 1]);


mu = nanmean(X,3);


Y = nan(size(X));
for ii = 1:size(X,3)
   Y(:,:,ii) = X(:,:,ii) - mu;
end

yerr = nansum(nansum(Y.^2,3),2);
[~,idx] = max(yerr);
for ii = 1:size(X,3)
   scatter3(T(idx),X(idx,1,ii),X(idx,2,ii),40,'k','Marker','o','LineWidth',2);
end
text(T(idx),-0.25,-0.25,sprintf('%g ms',round(T(idx))),'FontName','Arial',...
   'Color','k','FontSize',16,'FontWeight','bold');


for ii = 1:size(X,3)
   Cs = nan(numel(T),1);
   for ij = 1:numel(T)
      Cs(ij) = getCosineSimilarity(dX(ij,:,ii),mu(ij,:));
   end
   [~,idx] = findpeaks(-Cs);
   scatter3(T(idx),X(idx,1,ii),X(idx,2,ii),40,'b','Marker','o','LineWidth',2);
end

% Td = T(idx);
% S = Cs(idx);

lpf_fc = defaults.block('lpf_fc');
out_folder = defaults.jPCA('preview_folder');
out_folder = fullfile(pwd,out_folder,'Divergence',J.Align{1},...
   J.Group{1},Rat);
if exist(out_folder,'dir')==0
   mkdir(out_folder);
end


jpca_start_stop_times = defaults.jPCA('jpca_start_stop_times');
fname = sprintf('%s_%s_AllDays_%gms_to_%g_ms_jPCA-Plane-%g_%gHzFc',...
   Rat,tag,...
   jpca_start_stop_times(1),jpca_start_stop_times(2),...
   planeNum,lpf_fc);

savefig(fig,fullfile(out_folder,[fname '.fig']));
saveas(fig,fullfile(out_folder,[fname '.png']));

az = linspace(-37.5,177,600);
el = linspace(30,90,600);

vName = fullfile(out_folder,[fname '.avi']);
if exist(vName,'file')~=0
   delete(vName);
end
v = VideoWriter(vName);
v.FrameRate = 60;
open(v);
for ii = 1:numel(az)
   set(gca,'View',[az(ii),el(ii)]);
   MV = screencapture(fig);
   writeVideo(v,MV);
end
close(v);


if nargout < 1
   delete(fig);
end

end