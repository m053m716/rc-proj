function repos = Repos()
%REPOS  List of repositories to add to path alongside analysis code

repos = struct;

[f,u] = local.defaults(...
   'LocalMatlabReposFolder','LocalMatlabUtilitiesRepo');
repos.MATLAB_UTILITIES = fullfile(f,u);

end