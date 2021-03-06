function batch_set_channel_info
%BATCH_SET_CHANNEL_INFO    Initialize channel info for all blocks
%
%  batch_set_channel_info;

tank = defaults.files('tank');
addpath('libs');
R = dir(fullfile(tank,'RC*'));

for iR = 1:numel(R)
   B = dir(fullfile(tank,R(iR).name,[R(iR).name '_201*']));   
%    [~,chIdx_all] = getChannelIndex(B);
   
   getChannelInfo(R(iR).name,tank);
%    for ii = 1:numel(B)
%       chInfName = fullfile(B(ii).folder,B(ii).name,[B(ii).name '_ChannelInfo.mat']);
%       if exist(chInfName,'file')~=0
%          continue;
%       end     
      
%       ChannelInfo = RatChannelInfo(chIdx_all{ii});
%       save(chInfName,'ChannelInfo','-v7.3');            
%    end
   
end

%    function [chIdx_keep,chIdx_all] = getChannelIndex(B,chIdx_keep)
%       if nargin < 2
%          chIdx_keep = 1:32;
%       end
%       
%       if numel(B) > 1
%          chIdx_all = cell(numel(B),1);
%          for iB = 1:numel(B)
%             [chIdx_keep,chIdx_all{iB}] = getChannelIndex(B(iB),chIdx_keep);
%          end
%          return;
%       end 
% 
%       pname = fullfile(B.folder,B.name,[B.name '_wav-sneo_CAR_Spikes']);
%       F = dir(fullfile(pname,'*ptrain*.mat'));
%       chIdx_all = nan(numel(F),1);
%       for iF = 1:numel(F)
%          [~,fname,~] = fileparts(F(iF).name);
%          tmp = strsplit(fname,'_');
%          pNum = str2double(tmp{end-2}(end));
%          chIdx_all(iF) = str2double(tmp{end}) + 16*(pNum-1);
%       end     
%       chIdx_keep = intersect(chIdx_keep,chIdx_all);
% 
%    end

end