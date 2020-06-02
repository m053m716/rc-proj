function checkInstalledRepos()
%CHECKINSTALLEDREPOS Utility to check that repos are installed correctly
%
%  Use
%  >> utils.checkInstalledRepos();
%
%  If required repos are not found on the current path, tries to add them. 
%     If the repos are still not on the current path, then throws an error.

paths = defaults.Repos();

f = fieldnames(paths);
for iF = 1:numel(f)
   pathname = fullfile(paths.(f{iF}));
   if ~contains(path,pathname)
      if exist(pathname,'dir')==0
         error(['RC:' mfilename ':BadRepoPath'],...
            ['\n\t->\t<strong>[MISSING REPO]:</strong> ' ...
             'Repo `%s` is missing or local value is incorrect\n',...
             '\t\t\t("%s")\n'],f{iF},pathname);
      end
      addpath(genpath(pathname));
   else
      if exist(fullfile(pathname,'.installed'),'file')==0
         error(['RC:' mfilename ':BadRepoPath'],...
            ['\n\t->\t<strong>[INVALID REPO]:</strong> ' ...
             'Folder at "%s" exists,\n\t\t\tbut it does not contain ' ...
             'a valid version of <strong>%s</strong>\n'],pathname,f{iF});
      end
   end
end
sounds__.play('bell',0.9,-1.5);
fprintf(1,'\n\t->\t<strong>Repos installed correctly</strong>\n');
end