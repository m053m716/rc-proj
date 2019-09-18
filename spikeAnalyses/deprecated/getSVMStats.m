function T = getSVMStats(F,alignment)
%% GETSVMSTATS    Return table of all channel SVM discrimination data

if nargin < 1
   alignment = 'Grasp';
end

for iF = 1:size(F,1)
   rat = F{iF,1};
   fname = fullfile(F{iF,2}(1).folder);
   load(fname,'rate');
   info = rate{1,1}.info; %#ok<*USENS>
   clear rate
   for iDay = 1:size(F{iF,2},1)
      name = F{iF,2}(iDay).name;
      block = fullfile(F{iF,2}(iDay).folder,name);
      fname = fullfile(block,[name '_' alignment '-decompData.mat']);
      if exist(fname,'file')==0
         fprintf(1,'%s not found. Skipped.\n',fname);
         continue;
      end
      
      for iCh = 1:size(info,1)
         
      end
   end
end



end