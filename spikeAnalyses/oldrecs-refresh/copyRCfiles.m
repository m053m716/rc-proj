function copyRCfiles(F,matFileExtsIn,matFileExtsOut,tankIn,tankOut,varargin)
%% COPYRCFILES    Copy files if present within a BLOCK
%
%	COPYRCFILES(F,matFileExtsIn,matFileExtsOut,tankIn,tankOut);
%	COPYRCFILES(___,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%     F           :     Data struct in 'info.mat' @ TANK level. 
%                          nAnimals x 2 cell array. Column 1 is animal 
%                          name. Column 2 is an array of structs returned 
%                          by doing dir('animal-name*') in the animal
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
%  tankIn          :     String of input tank where files to be copied
%                          reside.
%
%  tankOut         :     String of output tank location where copied files
%                          will go.
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
DELAY_FOR_READING = 0.1; % (sec) to pause to let user see warnings

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
   a = F{iA,1};
   
   for iB = 1:size(b,1)
      name = b(iB).name;
      blockIn = fullfile(tankIn,a,name);
      
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
         
         blockOut = fullfile(tankOut,a,name);
         [newDest,~,~] = fileparts(fullfile(blockOut,fnameNew));
         
         % Make sure the original file exists
         if (exist(fullfile(blockIn,fnameOld),'file')==0) 
            warning('%s not found.',fullfile(blockIn,fnameOld));
            pause(DELAY_FOR_READING); % to read
            fprintf('Transferring...%03g%%\n',floor((iA-1)/size(F,1)*100));
            continue;
         end
         
         % Make sure there is a place that can be written
         if (exist(newDest,'dir')==0)
            mkdir(newDest);
         end
         
         % Copy the file
         copyfile(fullfile(blockIn,fnameOld),...
                  fullfile(blockOut,fnameNew),'f');
      end
      
   end   
   fprintf('\b\b\b\b\b%03g%%\n',floor(iA/size(F,1)*100));
end


end