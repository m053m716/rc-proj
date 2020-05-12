function batch_set_channel_masks
%BATCH_SET_CHANNEL_MASKS    Initialize channel masks based on prior score
%
%  BATCH_SET_CHANNEL_MASKS;

[tank,mask_loc,mask_tag] = defaults.files('tank',...
   'channel_mask_loc','channel_mask_tag');
if exist(mask_loc,'dir')==0
   mkdir(mask_loc);
end
R = dir(fullfile(tank,'RC*'));

for iR = 1:numel(R)
   B = dir(fullfile(tank,R(iR).name,[R(iR).name '_201*']));   
   [chIdx_keep,chIdx_all] = getChannelIndex(B);
   
   for ii = 1:numel(B)
      ChannelMask = ismember(chIdx_all{ii},chIdx_keep);
      save(fullfile(mask_loc,[B(ii).name mask_tag]),...
         'ChannelMask','-v7.3');
   end
   
end

   function [chIdx_keep,chIdx_all] = getChannelIndex(B,chIdx_keep,spikeFolderTag)
      if nargin < 2
         chIdx_keep = 1:32;
      end
      
      if nargin < 3
         spikeFolderTag = defaults.files('spike_folder_tag');
      end
      
      if numel(B) > 1
         chIdx_all = cell(numel(B),1);
         for iB = 1:numel(B)
            [chIdx_keep,chIdx_all{iB}] = getChannelIndex(B(iB),chIdx_keep,spikeFolderTag);
         end
         return;
      end 

      pname = fullfile(B.folder,B.name,[B.name spikeFolderTag]);
      F = dir(fullfile(pname,'*ptrain*.mat'));
      chIdx_all = nan(numel(F),1);
      for iF = 1:numel(F)
         [~,fname,~] = fileparts(F(iF).name);
         tmp = strsplit(fname,'_');
         pNum = str2double(tmp{end-2}(end));
         chIdx_all(iF) = str2double(tmp{end}) + 16*(pNum-1);
      end     
      chIdx_keep = intersect(chIdx_keep,chIdx_all);

   end

end