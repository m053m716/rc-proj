function renameFiles(F,matFileExtsIn,matFileExtsOut,varargin)
%% RENAMEFILES    Rename files if present within a BLOCK
%
%	RENAMEFILES(F,matFileExtsIn,matFileExtsOut);
%	RENAMEFILES(F,matFileExtsIn,matFileExtsOut,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%     F           :     Data struct in 'RC-tmp.mat'. nAnimals x 2 cell
%                          array. Column 1 is just the animal name. Column
%                          2 is an array of structs that are returned by
%                          doing dir('animal-name*') in the animal
%                          directory.
%
%  matFileExtsIn   :     Cell array of block name extensions (e.g.
%                          {'_1_Scoring.mat'; ...
%                           '_Digital$_1_VideoAlignment.mat'}
%                          etc. These will be renamed. Note, delimiter
%                          specified by DELIM (here, '$') splits into
%                          entries that are appended for different
%                          sub-folder levels.
%
%  matFileExtsIn   :     Cell array of block name extensions (e.g.
%                          {'_Scoring.mat'; ...
%                           '_Digital$_VideoAlignment.mat'}, etc.) 
%                          These are the new names, to replace old ones.
%
%  --------
%   OUTPUT
%  --------
%  Moves every file matching matFileExts in the main Block folder of F into
%  the corresponding array element subfolder in subFolderExts.
%
% By: Max Murphy  v1.0  12/28/2018  Original Version (R2017a)

%% DEFAULTS
DELIM = '$';

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% PARSE INPUT
if numel(matFileExtsIn)~=numel(matFileExtsOut)
   error('Dimension mismatch. matFileExtsIn and matFileExtsOut should match.');
end

%% LOOP THROUGH F AND MOVE FILES
fprintf('Transferring...%03g%%\n',0);
for iA = 1:size(F,1)
   b = F{iA,2};
   a = b(1).folder;
   
   for iB = 1:size(b,1)
      name = b(iB).name;
      block = fullfile(a,name);
      
      for ii = 1:numel(matFileExtsIn)
         str = strsplit(matFileExtsIn{ii},DELIM);
         fnameOld = [];
         for iS = 1:numel(str)
            fnameOld = fullfile(fnameOld,[name str{iS}]);
         end
         
         str = strsplit(matFileExtsOut{ii},DELIM);
         fnameNew = [];
         for iS = 1:numel(str)
            fnameNew = fullfile(fnameNew,[name str{iS}]);
         end
         
         [newDest,~,~] = fileparts(fullfile(block,fnameNew));
         
         if (exist(fullfile(block,fnameOld),'file')==0) 
            warning('%s not found.',fullfile(block,fnameOld));
            fprintf('Transferring...%03g%%\n',floor((iA-1)/size(F,1)*100));
            continue;
         elseif (exist(newDest,'dir')==0)
            warning('%s not found. Making new directory.',newDest);
            mkdir(newDest);
         end
         movefile(fullfile(block,fnameOld),...
                  fullfile(block,fnameNew),'f');
      end
      
   end   
   fprintf('\b\b\b\b\b%03g%%\n',floor(iA/size(F,1)*100));
end


end