function fig = plot_example_fit(G,T,k,figTag)
%PLOT_EXAMPLE_FIT Plot example of reconstructed Gaussian-pulse oscillation
%
%  fig = analyze.stat.plot_example_fit(G,T,k);
%  analyze.stat.plot_example_fit(G,T,k,figName);
%
% Inputs
%  G       - Table recovered using analyze.stat.get_fitted_table
%  T       - (Optional) Original table with all actual rate data. If not
%                       included, then the overlay is not included.
%  k       - (Optional) Row index of row from G (trial) to plot
%  figTag  - (Optional) Char array (tag) to add to filename of this figure
%                       -> If specified, invokes the "delete" and "save"
%                          behavior, even if figure handle is requested as
%                          output.
%
% Output
%  fig     - Figure handle object. If no output is requested, file is saved
%            and figure is deleted by default.
% 
% See also: analyze.stat.get_fitted_table, analyze.stat.fit_transfer_fcn,
%           analyze.stat.reconstruct_gauspuls


if nargin < 3
   k = randi(size(G,1),1,1); 
end

if nargin < 4
   figTag = '';
end

fig = figure('Name','Example of Gaussian Pulse fit',...
   'Color','w',...
   'Units','Normalized',...
   'Position',[0.2 0.2 0.4 0.4]); 
ax = axes(fig,...
   'XColor','k','YColor','k',...
   'FontName','Arial',...
   'LineWidth',1.25,'NextPlot','add');

t = G.Properties.UserData.t;
p = [G.PeakOffset(k),G.EnvelopeBW(k)./G.PeakFreq(k),G.PeakFreq(k)];
if nargin < 2
   r_hat = analyze.stat.reconstruct_gauspuls(nan,t,p,false);
   err = G.Error_SS(k);
else
   iOriginal = strcmp(T.Properties.RowNames,G.Properties.RowNames{k});
   r = T.Rate(iOriginal,:); 
   line(ax,t*1e3,r,...
      'LineWidth',1.5,'Color',[0.5 0.5 0.5],...
      'LineStyle',':','DisplayName','Original'); 
   [r_hat,err] = analyze.stat.reconstruct_gauspuls(r,t,p,true);
end
line(ax,t*1e3,r_hat,...
   'Color','b','LineWidth',2.5,'LineStyle','-',...
   'DisplayName','With Offset and Scaling');

% Add labels
thisAnimal = char(G.AnimalID(k));
thisDay = G.PostOpDay(k);
thisArea = char(G.Area(k));
thisCh = char(G.ChannelID(k));
thisPeak = G.PeakOffset(k) * 1e3;
thisEnvelope = G.EnvelopeBW(k);
thisFC = G.PeakFreq(k);
str = sprintf('%s_PostOp-%02d_%s_Ch-%s',...
   thisAnimal,thisDay,thisArea,thisCh);
title_str = [strrep(str,'_',' ') ...
   sprintf(' (\\tau_{peak} = %5.1f ms)',thisPeak)...
   newline ...
   sprintf(...
      ['f_{env} = %4.2f Hz | ' ...
       'f_{puls} = %4.2f Hz | \\Sigma\\epsilon^2 = %4.2f'],...
         thisEnvelope, thisFC, err)];
title(ax,title_str,'FontName','Arial','Color','k');
xlabel(ax,'Time (ms)','FontName','Arial','Color','k');
ylabel(ax,['Rate (a.u.)' blanks(6) sprintf('k == %d',k)],...
   'FontName','Arial','Color','k');
legend(ax,...
   'Location','best',...
   'TextColor','black',...
   'FontSize',12,...
   'FontName','Arial');

if (nargout < 1) || (nargin > 3)
   outpath = fullfile(defaults.files('stat_fit_fig_folder'),'Examples');
   analyze.stat.printFigs(fig,outpath,...
      [str '_Example-Reconstruction' figTag]);
end

end