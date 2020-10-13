clearvars -except D E E2

% D = utils.loadTables('multi');
% E = analyze.dynamics.exportTable(D);
% E2 = analyze.dynamics.exportSubTable(D);

%% Show ability to reconstruct using PCs
fig = kal.showPCAreconstruction(D,116);
outPath = fullfile(defaults.files('reach_extension_figure_dir'),'testbenches');
if exist(outPath,'dir')==0
   mkdir(outPath);
end
saveas(fig,fullfile(outPath,'FigS10 - Rate PCA Reconstruction - Full.png'));
savefig(fig,fullfile(outPath,'FigS10 - Rate PCA Reconstruction - Full.fig'));
delete(fig);

% z ~ Rates  (observations; measurements)
% x ~ Scores (states)
%
%  z = H*x + v
%
% v ~ Noise
%
% Since we only use 12 components, we should show what the noise is when we
% use the top 12 components for H. 


fig = kal.showPCAreconstruction(D,116,12); % Using only top-12 (as was done)
saveas(fig,fullfile(outPath,'FigS10 - Rate PCA Reconstruction - Top-12.png'));
savefig(fig,fullfile(outPath,'FigS10 - Rate PCA Reconstruction - Top-12.fig'));
delete(fig);

%% Now, use Kalman formulation to discuss PCs as state with respect to Rate

