function repos = Repos()
%REPOS  List of repositories to add to path alongside analysis code

repos = struct;

f = local.defaults('LocalMatlabReposFolder');
repos.CBREWER_PATH = fullfile(f,'_import\cbrewer_tDCS');
repos.RAINCLOUDPLOTS_PATH = fullfile(f,'_import\RainCloudPlots_tDCS\tutorial_matlab');
repos.UTILITIES_PATH = fullfile(f,'Utilities');

end