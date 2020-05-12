function rawData = plotBoxPlotsRotationPresence(C)
%% PLOTBOXPLOTSROTATIONPRESENCE  Plot box plots based on presence/absence of rotations
PRESENT = {'Absent';'Present'};

figure;
RotationsPresent = C.nUnsuccessful > 0;
C = [C,table(RotationsPresent)];
G = cell(size(C,1),1);
for ii = 1:size(C,1)
   G{ii} = strjoin([C.Group{ii},PRESENT(C.RotationsPresent(ii)+1)],'-');
end
boxplot(C.Score,G);
title('Behavioral Score by Rotational Presence','FontName','Arial','Color','k');
ylabel('Score','FontName','Arial','Color','k');
ylim([0 1]);

if nargout > 0
   uG = unique(G);
   rawData = cell(2,numel(uG));
   for iG = 1:numel(uG)
      rawData{1,iG} = C.Score(ismember(G,uG{iG}));
      rawData{2,iG} = C.PostOpDay(ismember(G,uG{iG}));
      rawData{3,iG} = find(ismember(G,uG{iG}));
   end
   rawData = cell2table(rawData);
   rawData.Properties.VariableNames = strrep(uG,'-','_');
   
   figure('Name','Rotatory Presence Screens Recovery Profile','Units','Normalized','Color','w','Position',[0.2 0.2 0.5 0.5]);
   varName = rawData.Properties.VariableNames;
   for ii = 1:4
      subplot(2,2,ii);
      for ij = 1:numel(rawData.(varName{ii}){1})
         scatter(rawData.(varName{ii}){2}(ij),rawData.(varName{ii}){1}(ij),20,'k','filled',...
            'MarkerFaceColor','k','MarkerEdgeColor','none',...
            'LineWidth',2,'MarkerEdgeAlpha',0.75,...
            'UserData',struct('isHighlighted',false,...
                              'metadata',C(rawData.(varName{ii}){3}(ij),:)),...
            'ButtonDownFcn',@showHideMetadata);
         hold on;
      end
      title(strrep(varName{ii},'_','-'),'Color','k','FontName','Arial');
      ylim([0 1]);
      ylabel('Behavioral Score','FontName','Arial','Color','k');
      xlabel('Post-Op Day','FontName','Arial','Color','k');
   end
end

   function showHideMetadata(src,~)
      srcProps = src.UserData;
      if srcProps.isHighlighted
         clc;
         src.MarkerFaceColor = 'k';
         src.MarkerEdgeColor = 'none';
         src.SizeData = 20;
      else
         src.MarkerFaceColor = 'b';
         src.MarkerEdgeColor = 'c';
         src.SizeData = 72;
         disp(srcProps.metadata);
      end
      src.UserData.isHighlighted = ~srcProps.isHighlighted;
   end
end