function fig = view_scores(P)
%VIEW_SCORES  Plot PCA scores for grasps
%
%  fig = analyze.complete.view_scores(P);
%
%  -- Inputs --
%  P : Table from `[P,C] = analyze.complete.pca_table(U);`
%        (U : Table from `U = analyze.complete.get_subset(T);`)
%
%  -- Output --
%  fig : Figure handle

close all force;
utils.addHelperRepos();
fig = gobjects(2,1);

% % Plot overview scatter matrix for all scores % %
fig(1) = figure('Name','Completed Grasp PC Scores',...
   'NumberTitle','off',...
   'Color','w',...
   'Units','Normalized',...
   'Position',[0.1 0.1 0.8 0.8]);
idx = P.Alignment=='Grasp';
p = P(idx,:);
p(p.AnimalID=='RC-14' & p.PostOpDay==17,:)=[]; % Remove outlier
group = cellfun(@(C1,C2)sprintf('%s: %s',C1,C2),...
   cellstr(char(p.Group)),cellstr(char(p.Area)),...
   'UniformOutput',false);

score = p.PC_Score; % Values to plot are PC-1 thru PC-4 scores

clr = getColorMap(4,'pastel');
sym = '.x';
siz = [12 6];
doleg = 'on';
factor_names = defaults.fails_analyses('factor_names');
factor_names = cellfun(@(C)strrep(C,'_','\_'),factor_names,...
   'UniformOutput',false);

gplotmatrix(fig(1),...
   score,[],group,clr,sym,siz,doleg,[],...
   factor_names,factor_names);
sounds__.play('pop',1.5,-30);

% % Second figure is "Zoom-In" on scores(:,[2,3]) % %
fig(2) = figure(...
   'Name','Completed Grasp: Zoom-In',...
   'NumberTitle','off',...
   'Color','w',...
   'Units','Normalized',...
   'Position',ui__.getSecondMonitorPosition([0.45 0.45 0.5 0.5]));
ax = axes(fig(2),'NextPlot','add',...
   'XColor','k',...
   'YColor','k',...
   'ZColor','k',...
   'LineWidth',1.5);
view(ax,3);
psub = p(p.Area=='RFA',:);
% group = cellfun(@(C1)sprintf('%s: RFA',C1),...
%    cellstr(char(psub.Group)),'UniformOutput',false);
[G,TID] = findgroups(psub(:,'Group'));
cRed = getColorMap(6,'red');
cRed = cRed(5,:);
cBlue = getColorMap(4,'blue');
cBlue = cBlue(2,:);
clr = [cRed; cBlue];
% sym = '.';
% siz = 8;
score = psub.PC_Score;
day = psub.PostOpDay;
% y = tsne(score);
% sounds__.play('pop',0.9,-15);
for iG = 1:2
   iGroup = G==iG;
   scatter3(ax,score(iGroup,3),day(iGroup),score(iGroup,2),...
      'Marker','o',...
      'MarkerFaceColor',clr(iG,:),...
      'DisplayName',char(TID.Group(iG)),...
      'MarkerEdgeColor',clr(iG,:),...
      'MarkerFaceAlpha',0.5,...
      'SizeData',10);
end
xlabel(ax,factor_names{3});
zlabel(ax,factor_names{2});
ylabel(ax,'Post-Op Day');
sounds__.play('pop',0.75,-20);

% % Plot scores trajectories across days for different animals % %
fig(3) = figure(...
   'Name','Completed Grasp: Day Trajectories',...
   'NumberTitle','off',...
   'Color','w',...
   'Units','Normalized',...
   'Position',ui__.getSecondMonitorPosition([0.05 0.05 0.5 0.5]));
figure(fig(3));

for iScore = 1:size(score,2)
   ax = subplot(2,2,iScore);
   hold on;
   for iG = 1:2
      psub_a = psub(psub.Group==TID.Group(iG),:);
      gAnimal = findgroups(psub_a(:,'AnimalID'));
      c = clr(iG,:);
      this_score = psub_a.PC_Score(:,iScore);
      this_animal = psub_a.AnimalID;
      splitapply(@(day,score,animal)addAnimalPC_by_Day(ax,c,day,score,animal),...
         psub_a.PostOpDay,this_score,this_animal,gAnimal);
   end
   xlim(ax,[3 45]);
   ylim(ax,[-2 2]);
   legend(ax,'Location','best');
   title(factor_names{iScore});
   
   ax.XTick = [7 14 21];
   xlabel(ax,'Post-Op Day','FontName','Arial','Color','k');
   ylabel(ax,'PC Score','FontName','Arial','Color','k');
   ax.YTick = [-1 0 1];
end
suptitle('Completed Grasps');

% % Plot scores(:,[2,3]) trajectories by area & day for animals % %
fig(4) = figure(...
   'Name','Completed Grasp: By Area and Day',...
   'NumberTitle','off',...
   'Color','w',...
   'Units','Normalized',...
   'Position',ui__.getSecondMonitorPosition([0.05 0.45 0.5 0.5]));
figure(fig(4));
[G,TID] = findgroups(p(:,{'Group','Area'}));
clr4 = clr([1,1,2,2],:);
for iG = 1:4
   ax = subplot(2,2,iG);
   ax.NextPlot = 'add';
   p_a = p(G==iG,:);
   gAnimal = findgroups(p_a(:,'AnimalID'));
   c = clr4(iG,:);
   these_days = p_a.PostOpDay;
   this_score1 = p_a.PC_Score(:,2);
   this_score2 = p_a.PC_Score(:,3);
   this_animal = p_a.AnimalID;
   splitapply(@(day,score1,score2,animal)addAnimalPC3_by_Day(ax,c,day,score1,score2,animal),...
      these_days,this_score1,this_score2,this_animal,gAnimal);

   xlim(ax,[3 45]);
   ylim(ax,[-3 3]);
   zlim(ax,[-3 3]);
   view(ax,3);
   legend(ax,'Location','best');
   title(sprintf('%s: %s',char(TID.Group(iG)),char(TID.Area(iG))),...
      'Color','k','FontName','Arial');
   ax.LineWidth = 1.5;
   ax.XColor = 'k';
   ax.YColor = 'k';
   ax.ZColor = 'k';
   ax.XTick = [7 14 21];
   xlabel(ax,'Post-Op Day','FontName','Arial','Color','k');
   ylabel(ax,factor_names{2},'FontName','Arial','Color','k');
   zlabel(ax,factor_names{3},'FontName','Arial','Color','k');
   ax.YTick = [-2 0 2];
   ax.ZTick = [-2 0 2];
   
end
suptitle('Completed Grasps');

% % Plot scores(:,[2,3]) trajectories by area & day for animals + err % %
fig(5) = figure(...
   'Name','Completed Grasp: Gauss + Mod by Day',...
   'NumberTitle','off',...
   'Color','w',...
   'Units','Normalized',...
   'Position',[0.1 0.1 0.8 0.8]);
figure(fig(5));
[G,TID] = findgroups(p(:,{'Group','Area'}));
col = [0.7 0.3 0.3; ...
       0.7 0.3 0.3; ...
       0.3 0.3 0.7; ...
       0.3 0.3 0.7];
for iG = 1:4
   ax = subplot(2,2,iG);
   ax.NextPlot = 'add';
   p_a = p(G==iG,:);
   gAnimal = findgroups(p_a(:,'AnimalID'));
   these_days = p_a.PostOpDay;
   
   score_1 = p_a.PC_Score(:,2);
   score_2 = p_a.PC_Score(:,3);
   
   this_animal = cellfun(@(C)sprintf('%s: %s',C,factor_names{2}),...
      cellstr(char(p_a.AnimalID)),'UniformOutput',false);
   c = col(iG,:)+0.2;
   splitapply(@(day,score,animal)addAnimalPC_by_Day(ax,c,day,score,animal),...
      these_days,score_1,this_animal,gAnimal);
   
   this_animal = cellfun(@(C)sprintf('%s: %s',C,factor_names{3}),...
      cellstr(char(p_a.AnimalID)),'UniformOutput',false);
   c = col(iG,:)-0.2;
   splitapply(@(day,score,animal)addAnimalPC_by_Day(ax,c,day,score,animal),...
      these_days,score_2,this_animal,gAnimal);
   
   xlim(ax,[3 30]);
   ylim(ax,[-6 3]);
   legend(ax,'Location','south','NumColumns',2);
   title(sprintf('%s: %s',char(TID.Group(iG)),char(TID.Area(iG))),...
      'Color','k','FontName','Arial');
   ax.LineWidth = 1.5;
   ax.XColor = 'k';
   ax.YColor = 'k';
   ax.XTick = [7 14 21];
   xlabel(ax,'Post-Op Day','FontName','Arial','Color','k');
   ylabel(ax,'PC Score','FontName','Arial','Color','k');
   ax.YTick = [-2 0 2];
   
end
suptitle('Completed Grasps');


   function addAnimalPC3_by_Day(ax,col,day,score1,score2,animal)
      %ADDANIMALPC3_BY_DAY  Add PC score by day to current axis
      
      [postOpDay,iDay] = sort(day,'ascend');
      pc_score1 = score1(iDay);
      pc_score2 = score2(iDay);
      [g_day,u_day] = findgroups(postOpDay);
      
      pc_score1_mu = splitapply(@(x)mean(x),pc_score1,g_day);
      pc_score2_mu = splitapply(@(x)mean(x),pc_score2,g_day);
      col = col + rand(1,3)*0.05;
      str = char(animal(1));
      hh = plot3(ax,u_day,pc_score1_mu,pc_score2_mu,...
         'Color',col.*0.75,...
         'Marker','>',...
         'LineWidth',3,...
         'DisplayName',str,...
         'Tag',str);
      hh.Annotation.LegendInformation.IconDisplayStyle = 'off';
      scatter3(ax,postOpDay,pc_score1,pc_score2,...
         'Marker','o',...
         'MarkerFaceColor',col,...
         'MarkerEdgeColor',col,...
         'MarkerFaceAlpha',0.1,...
         'MarkerEdgeAlpha',0.2,...
         'SizeData',8,...
         'DisplayName',str,...
         'Tag',str);
   end

   function addAnimalPC_by_Day(ax,col,day,score,animal)
      %ADDANIMALPC_BY_DAY  Add PC score by day to current axis
      
      [postOpDay,iDay] = sort(day,'ascend');
      pc_score = score(iDay);
      [g_day,u_day] = findgroups(postOpDay);
      
      pc_score_mu = splitapply(@(x)mean(x),pc_score,g_day);
      pc_score_err = splitapply(@(x)std(x)/sqrt(numel(x)),pc_score,g_day);
      col = col + rand(1,3)*0.05;
      str = char(animal(1));
      gfx__.plotWithShadedError(ax,u_day,pc_score_mu,pc_score_err,...
         'FaceAlpha',0.5,'FaceColor',col,...
         'DisplayName',str,...
         'Annotation','on',...
         'Tag',str);
   end

end