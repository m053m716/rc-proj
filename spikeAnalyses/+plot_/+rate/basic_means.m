function fig = basic_means(stats,G,T)
%BASIC_MEANS  Function to plot basic means of spike rate trajectories
%  
%  fig = plot_.rate.basic_means(stats,G);
%  --> Plot according to grouping variables in G (names of variables in T
%           to use for groupings).
%
%  fig = plot_.rate.basic_means(stats,G,T);
%  --> Override default times of each column of spike rate data

if nargin < 3
   T = defaults.experiment('t_ds');
end

if iscell(G)
   groupIdx = ismember(stats.Properties.VariableNames,G);
   [G,TID] = findgroups(stats(:,groupIdx));
elseif ischar(G)
   [vals,G] = unique(stats.(G));
   TID = table(vals,'VariableNames',{G});
elseif istable(G)
   [G,TID] = findgroups(G); % Table is already narrowed down; find groups
else
   error('Bad input class for groupings variable: ''%s'' not accepted\n',...
      class(G));
end

fig = figure(...
   'Name','Plot: Basic Means',...
   'Color','w',...
   'Units','Normalized',...
   'Position',[0.2 0.2 0.4 0.4]...
   );
idx = find(ismember(stats.Properties.VariableNames,'normRate'),1,'first');
mu = splitapply(@(x)nanmean(x,1),stats(:,idx),G);
sd = splitapply(@(x)std(x,[],1),stats(:,idx),G);
ax = ui__.panelizeAxes(fig,size(mu,1));
ax = flipud(ax);
x = T;
axLab = cell(size(TID,1));
for i = 1:size(TID,1)
   axLab{i} = '';
   for ii = 1:size(TID,2)
      val = TID.(TID.Properties.VariableNames{ii})(i);
      if ischar(val)
         axLab{i} = [axLab{i}, sprintf(' %s: %s ',...
            TID.Properties.VariableNames{ii},val)];
      elseif iscell(val)
         axLab{i} = [axLab{i}, sprintf(' %s: %s ',...
            TID.Properties.VariableNames{ii},val{:})];
      else
         axLab{i} = [axLab{i}, sprintf(' %s: %s ',...
            TID.Properties.VariableNames{ii},char(val))];
      end   
   end
end
for i = 1:numel(ax)
   y = mu(i,:);
   err = sd(i,:);
   gfx__.plotWithShadedError(ax(i),x,y,err);
   xlim(ax(i),[-1000 500]);
   ylim(ax(i),[-1 1]);
   title(ax(i),axLab{i},'FontName','Arial','Color','k');
end
suptitle(sprintf('%s: %s',stats.Properties.UserData.align,...
   stats.Properties.UserData.outcome));

end