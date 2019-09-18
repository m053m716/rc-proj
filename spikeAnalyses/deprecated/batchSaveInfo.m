function batchSaveInfo(F)
%% GETSVMSTATS    Return table of all channel SVM discrimination data

tic;
for iF = 1:size(F,1)
   rat = F{iF,1};
   fprintf(1,'Saving channel info for %s...\n',rat);
   fname = fullfile(F{iF,2}(1).folder,[rat '_analyses'],...
      [rat '_RateByDay_020ms_Align-Grasp-All.mat']);
   if exist(fname,'file')==0
      continue;
   end
   load(fname,'rate');
   
   for iDay = 1:numel(rate)
      info = rate{iDay}.info; %#ok<*USENS>
      block = info(1).file(1:16);
      fname = fullfile(F{iF,2}(1).folder,block,[block '_ChannelInfo.mat']);
      save(fname,'info','-v7.3');
   end
end
toc;


end