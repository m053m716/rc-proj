function fig = view_coeffs(C)
%VIEW_COEFFS  Make figures showing each row of `C` table of coefficients
%
%  fig = analyze.successful.view_coeffs(C);
%
%  -- Inputs --
%  C : Table returned by `[P,C] = analyze.successful.pca_table(T,K);`
%     -> Where `K` is number of principal components to return.
%
%  -- Output --
%  fig : Figure handle or array of figure handles (depending on groupings,
%           which are the same thing as rows of `C`)

if size(C,1) > 1
   fig = [];
   for i = 1:size(C,1)
      if nargout > 0
         fig = [fig; analyze.complete.view_coeffs(C(i,:))]; %#ok<AGROW>
      else
         analyze.complete.view_coeffs(C(i,:));
      end
   end
   return;
end

coeffs = C.PC_Coeffs{1};
e = C.PC_Explained{1};
nFactor = size(coeffs,2);
t = C.Properties.UserData.t(C.Properties.UserData.t_mask);

str = sprintf('%s - %s - %s',...
   char(C.Group),char(C.Alignment),char(C.Area));
ox = randn(1)*0.05;
oy = randn(1)*0.05;
fig = figure('Name',sprintf('PCA Coeffs (Completed Trials): %s',str),...
   'Units','Normalized',...
   'NumberTitle','off',...
   'Color','w',...
   'Position',[0.2+ox,0.2+oy,0.4,0.4]);
nRow = floor(sqrt(nFactor));
nCol = ceil(nFactor/nRow);

cols = C.Properties.UserData.color_order;
factor_names = defaults.fails_analyses('factor_names');
for i = 1:nFactor
   subplot(nRow,nCol,i);
   plot(t,coeffs(:,i),...
      'Color',cols(i,:),...
      'LineWidth',2);
   xlim([t(1) t(end)]);
   ylim([-1 1]);
   f = strrep(factor_names{i},'_','-');
   title(sprintf('%s (%3.3g%%)',f,e(i)),...
      'FontName','Arial','Color',cols(i,:),'FontSize',14);
end
suptitle(str);

if nargout==0
   [path,expr] = defaults.files('success_fig_dir','success_view_figs');
   if exist(path,'dir')==0
      mkdir(path);
   end
   savefig(fig,fullfile(path,[sprintf(expr,str,nFactor) '.fig']));
   saveas(fig,fullfile(path,[sprintf(expr,str,nFactor) '.png']));
   delete(fig);
end

end