function [fig_matrix,fig_overlay,xc,i_new] = compare_factors(t,h0,hnew,orig_tag,new_tag,forceSave)
%COMPARE_FACTORS  Plot factor comparison between two NNMF factor sets
%
%  [fig_matrix,fig_overlay] = analyze.nnm.compare_factors(t,h0,hnew);
%     -> Create figures to compare factors in `h0` and `hnew`
%
%  [...] = analyze.nnm.compare_factors(t,h0,hnew,orig_tag,new_tag);
%     -> Specify tags for h0 and hnew
%
%  [fig_matrix,fig_overlay,xc,i_new] = analyze.nnm.compare_factors(__,forceSave);
%     -> Return xc matrix and i_new indexing to overlay factors
%
%  -- Inputs --
%  t     :  Times corresponding to columns of h0 and hnew
%  h0    :  Factor coefficients (NNMF_Coeffs); each row is a new factor
%  hnew  :  Factor coefficients to compare to originals (NNMF_Coeffs, from
%              a different table "slice")
%
%  orig_tag : Tag associated with h0 (optional)
%  new_tag  : Tag associated with hnew (optional)
%  forceSave : Default: false; set true to auto-save (if nargout == 0,
%              deletes figures after save by when this is true)
%
%  -- Output --
%  fig_matrix : Figure handle to "matrix" figure
%  fig_overlay : Figure handle to "overlay" figure
%
%  (Optional) 
%     xc : Factor matrix (shown in `fig_matrix`)
%     i_new : Mapping of `hnew` factors into `h0` order (shown in
%                 `fig_overlay`)

% % Check inputs % %

nFactor = size(h0,1);
nNew = size(hnew,1);
if nNew ~= nFactor
   error(['RC:' mfilename ':BadSize'],...
      ['\n\t->\t<strong>[COMPARE_FACTORS]:</strong>\n' ...
       '\t\t\tBad input size: h0 has %g rows, but hnew has %g rows.\n'...
       '\t\t\t(They should have equal number of rows)\n'],nFactor,nNew);
end

if nargin < 4
   orig_tag = '';
end

if nargin < 5
   new_tag = '';
end

if nargin < 6
   forceSave = false;
else
   [nnmf_mat_fig,nnmf_overlay_fig] = ...
      defaults.files('nnmf_mat_fig','nnmf_overlay_fig');
end

if nargout < 1
   close all force;
end

% % Specify default parameters % %
[color_order,n_subplot_row,...
   fig_params_mat,fig_params_overlay,ax_params,...
   title_params,label_params,legend_params] = ...
      defaults.nnmf_analyses(...
         'color_order','n_subplot_row',...
         'fig_params_mat','fig_params_overlay','ax_params',...
         'title_params','label_params','legend_params');

% % Get factor correlations % %
[xc,i_new] = analyze.factor_pairs(h0,hnew);

% % Make figure for matrix of cross-correlations % %
fig_matrix = figure(fig_params_mat{:});
ax = axes(fig_matrix,ax_params{:},'XTick',1:nFactor,'YTick',1:nFactor);
imagesc(ax,1:nFactor,1:nFactor,xc);
title(ax,'NNMF Factor Correlations',title_params{:});
if isempty(orig_tag)
   xlabel(ax,'Row of h_0',label_params{:});
else
   xlabel(ax,sprintf('Row of h_0 (%s)',orig_tag),label_params{:});
end
if isempty(new_tag)
   ylabel(ax,'Row of h_{new}',label_params{:});
else
   ylabel(ax,sprintf('Row of h_{new} (%s)',new_tag),label_params{:});
end
colBar = colorbar;
colBar.Label.FontSize = 12; 
colBar.Ticks = [0.25 0.5 0.75]; 
colBar.Label.FontName = 'Arial'; 
colBar.Label.String = 'Correlation';

if forceSave
   fname_base = sprintf(nnmf_mat_fig,orig_tag,new_tag);
   p = fileparts(fname_base);
   if exist(p,'dir')==0
      mkdir(p);
   end
   savefig(fig_matrix,[fname_base '.fig']);
   saveas(fig_matrix,[fname_base '.png']);
   if (nargout < 1)
      delete(fig_matrix);
   end
end
% % Make figure for overlay of new factors onto correlated originals % %
fig_overlay = figure(fig_params_overlay{:});
nCol = ceil(nFactor/n_subplot_row);
for i = 1:nFactor
   subplot(nFactor,nCol,i);
   plot(t,h0(i,:),...
      'DisplayName','h_0',...
      'Tag',orig_tag,...
      'Color',color_order(i,:),...
      'LineWidth',2);
   hold on;
   plot(t,hnew(i_new(i),:),...
      'DisplayName','h_{new}',...
      'Tag',new_tag,...
      'Color',color_order(i_new(i),:),...
      'LineWidth',1.75);
   legend(legend_params{:});
   title(sprintf('Factor %g',i),title_params{:});
   ylabel('Amplitude',label_params{:});
   if i == 5
      xlabel('Time (ms)',label_params{:});
   end
   ylim([0 1]);
   xlim([min(t) max(t)]);
end

if ~isempty(new_tag) && ~isempty(orig_tag)
   suptitle(sprintf('%s (original) vs %s (new)',orig_tag,new_tag));
end

if forceSave
   fname_base = sprintf(nnmf_overlay_fig,orig_tag,new_tag);
   p = fileparts(fname_base);
   if exist(p,'dir')==0
      mkdir(p);
   end
   savefig(fig_overlay,[fname_base '.fig']);
   saveas(fig_overlay,[fname_base '.png']);
   if (nargout < 1)
      delete(fig_overlay);
   end
end

end