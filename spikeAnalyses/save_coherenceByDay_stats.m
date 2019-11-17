function T = save_coherenceByDay_stats(cxy,name,outpath)

if nargin < 3
   outpath = pwd;
end

if nargin < 2
   name = 'CoherenceByDayStats.xls';
else
   if ~strcmpi(name((end-3):end),'.xls')
      name = [name '.xls'];
   end
end

PODAY = (3:28)';
iIntact = 1:numel(PODAY);
iIschemia = (numel(PODAY)+1):size(cxy,1);
iGroup = {iIntact; ...
          iIschemia};
gName = {'Intact'; ...
         'Ischemia'};

T = utils.initEmpty;
% [T1,T2,T3,T4] = utils.initEmpty;
nRep = size(cxy,3);
nFreq = size(cxy,2);
[b,a] = butter(2,0.125,'low');
RepNum = ones(numel(PODAY),1) * (1:nRep);
RepNum = RepNum(:);

PODAY = repmat(PODAY,nRep,1);




for i = 1:numel(iGroup)
   c = cxy(iGroup{i},:,:);
   X = struct;
   for iF = 1:nFreq
      xtmp = squeeze(c(:,iF,:));
      if any(ismissing(xtmp(:,1)))
         xtmp = fillmissing(xtmp,'linear');
      end
      xtmp = filtfilt(b,a,xtmp);
      xtmp = xtmp(:);
      X.(sprintf('PC%g',iF)) = xtmp;
   end   
%    T1 = [T1; table(PODAY,repmat(gName(i),numel(PODAY),1),X.PC1,...
%          'VariableNames',{'PostOpDay','Group','PC1'})]; %#ok<*AGROW>
%    T2 = [T2; table(PODAY,repmat(gName(i),numel(PODAY),1),X.PC2,...
%          'VariableNames',{'PostOpDay','Group','PC2'})];
%    T3 = [T3; table(PODAY,repmat(gName(i),numel(PODAY),1),X.PC3,...
%          'VariableNames',{'PostOpDay','Group','PC3'})];
%    T4 = [T4; table(PODAY,repmat(gName(i),numel(PODAY),1),X.PC4,...
%          'VariableNames',{'PostOpDay','Group','PC4'})];
   rID = RepNum + (i-1)*nRep;
   T = [T; table(PODAY,repmat(gName(i),numel(PODAY),1),X.PC1,X.PC2,X.PC3,X.PC4,rID,...
           'VariableNames',{'PostOpDay','Group','PC1','PC2','PC3','PC4','ReplicateID'})]; %#ok<*AGROW>
end

if nargout < 1
%    writetable(T1,'CoherenceByDayStats_PC1.xls');
%    writetable(T2,'CoherenceByDayStats_PC2.xls');
%    writetable(T3,'CoherenceByDayStats_PC3.xls');
%    writetable(T4,'CoherenceByDayStats_PC4.xls');
   if exist(outpath,'dir')==0
      mkdir(outpath);
   end
   writetable(T,fullfile(outpath,name));
end

end