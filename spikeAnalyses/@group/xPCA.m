function xPCA(obj,align,includeStruct,area)
%% XPCA  "Cross" PCA
%  
%  obj must be a GROUP class object array, where obj(1) Name is 'Ischemia'
%  and obj(2) Name is 'Intact' (and the child rat objects should correspond
%  to those groups).

%% CHECK INPUTS
if nargin < 2
   align = defaults.block('alignment');
end

if nargin < 3
   includeStruct = utils.makeIncludeStruct({'Grasp','Reach','Outcome'});
end

if nargin < 4
   area = 'Full';
end

if numel(obj) < 2
   error('See group.XPCA description: need array of GROUP objects.')
end

%% HANDLE ARRAY INPUTS
if iscell(align) && (numel(align) > 1)
   for ii = 1:numel(align)
      xPCA(obj,align{ii},includeStruct,area);
   end
   return;
end

if iscell(includeStruct) && (numel(includeStruct) > 1)
   for ii = 1:numel(includeStruct)
      xPCA(obj,align,includeStruct{ii},area);
   end
   return;
end

if iscell(area) && (numel(area) > 1)
   for ii = 1:numel(area)
      xPCA(obj,align,includeStruct,area{ii});
   end
   return;
end

%% GET CROSS-DAY MEANS FOR INTACT GROUP
tLim = [defaults.xPCA('t_start'), defaults.xPCA('t_stop')];
dbug = defaults.xPCA('debug');

[g,g_idx] = obj.Intact;
if isempty(g)
   error('Missing Intact GROUP object from array.');
end
[rate,t] = getSetIncludeStruct(g.Children,align,includeStruct);
X = [];
for ii = 1:numel(g.Children)
   X = [X, rate{ii}]; %#ok<*AGROW>
   
end
t_idx = (t >= tLim(1)) & (t <= tLim(2));
X = X(t_idx,:);
t = t(t_idx);

if dbug
   fprintf(1,'X is %g rows by %g columns.\n',size(X,1),size(X,2));
   dbFig1 = figure('Name','All Channels Debug Plot',...
      'Units','Normalized',...
      'Position',[0.25 0.25 0.4 0.4],...
      'Color','w'); 
   pLine = plot(t,X,'Color','r');
   set(pLine(contains({g.ChannelInfo.area},'RFA')),'Color','b');
   xlabel('Time (ms)','FontName','Arial','Color','k');
   ylabel('Rate (Normalized)');
   title('All Intact Channels (b - RFA; r - CFA)','FontName','Arial','Color','k');
   keyboard;
   close(dbFig1);
end

%% GET PRINCIPAL COMPONENTS OF CROSS-DAY (CONDITION) MEANS
xPC = utils.doTrialPCA(X);
obj(g_idx).xPC = xPC;

latent_dims = cumsum(xPC.latent)./sum(xPC.latent);

if dbug
   dbFig2 = figure('Name','PCA Summary (all Intact channels)',...
      'Units','Normalized',...
      'Position',[0.25 0.25 0.4 0.4],...
      'Color','w');  
   subplot(2,1,1); 
   li = sum(latent_dims <= 0.95);
   bar(1:li,latent_dims(1:li)*100,'FaceColor','y');
   hold on;
   bar((li+1):numel(latent_dims),latent_dims((li+1):end)*100,'FaceColor','k');
   xlabel('Dim #','FontName','Arial','Color','k');
   ylabel('% Var Explained','FontName','Arial','Color','k');
   title('PCA Summary (All Channels)','FontName','Arial','Color','k','FontSize',18);
   subplot(2,1,2);
   plot(t,xPC.score(:,latent_dims <= 0.95),'LineWidth',1.5);
   legText = [];
   for ii = 1:sum(latent_dims <= 0.95)
      legText = [legText; {sprintf('PC-%g',ii)}];
   end
   legend(legText);
   keyboard;
   close(dbFig2);
end

end