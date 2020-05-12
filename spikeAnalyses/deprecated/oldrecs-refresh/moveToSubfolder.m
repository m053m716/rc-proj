function moveToSubfolder(F,matFileExts,subFolderExts)
%% MOVETOSUBFOLDER  Move files to a sub-folder within a BLOCK
%
%	MOVETOSUBFOLDER(F,matFileExts,subFolderExts);
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
%  matFileExts    :     Cell array of block name extensions (e.g.
%                          {'_Scoring.mat';'_Paw.mat'}, etc.) These will be
%                          moved.
%
%  subFolderExts  :     Cell array of block name extensions for sub-folders
%                          within the block to move things to. (e.g.
%                          {'_Digital'; '_Digital'} would match the
%                          previous.
%
%  --------
%   OUTPUT
%  --------
%  Moves every file matching matFileExts in the main Block folder of F into
%  the corresponding array element subfolder in subFolderExts.
%
% By: Max Murphy  v1.0  12/28/2018  Original Version (R2017a)

%% PARSE INPUT
if numel(matFileExts)~=numel(subFolderExts)
   error('Dimension mismatch. matFileExts and subFolderExts should match.');
end

%% LOOP THROUGH F AND MOVE FILES
fprintf('Transferring...%03g%%\n',0);
for iA = 1:size(F,1)
   b = F{iA,2};
   a = b(1).folder;
   
   for iB = 1:size(b,1)
      name = b(iB).name;
      block = fullfile(a,name);
      
      for ii = 1:numel(matFileExts)
         fnameToMove = [name matFileExts{ii}];
         blockDest = fullfile(block,[name subFolderExts{ii}]);
         
         if (exist(fullfile(block,fnameToMove),'file')==0) 
            warning('%s not found.',fnameToMove);
            fprintf('Transferring...%03g%%\n',floor((iA-1)/size(F,1)*100));
            continue;
         elseif (exist(blockDest,'dir')==0)
            warning('%s not found.',blockDest);
            fprintf('Transferring...%03g%%\n',floor((iA-1)/size(F,1)*100));
            continue;
         else
            movefile(fullfile(block,fnameToMove),...
               fullfile(blockDest,fnameToMove),'f');
         end
      end
      
   end   
   fprintf('\b\b\b\b\b%03g%%\n',floor(iA/size(F,1)*100));
end


end