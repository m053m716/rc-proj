function [out,bData] = decompRateData(rate,behaviorData,activeCh)
%% DECOMPRATEDATA    Decompose rate data and relate output to behavior
%
%  out = DECOMPRATEDATA(rate,behaviorData);
%
%  --------
%   INPUTS
%  --------
%    rate         :     Rate struct (should be '-All.mat' version)
%
%  behaviorData   :     Table of behavior times ('_Scoring.mat')
%
%  --------
%   OUTPUT
%  --------
%    out          :     Decomposed data with associated behavior metadata.
%
% By: Max Murphy  v1.0  2019-06-04  Original version (R2017a)

%%
t = linspace(-1.9995,0.9995,3000);
idx = (t>=-1.75) & (t <= 0.75);
tt = t(idx);

[b,a] = butter(4,60/(24414.0625/2),'low');


keepIdx = squeeze(var(rate.data(:,:,activeCh),[],2)>10);

if numel(keepIdx)~=size(behaviorData,1)
   behaviorData = behaviorData(~isinf(behaviorData.Grasp),:);
   if numel(keepIdx)~=size(behaviorData,1)
      behaviorData = behaviorData(~isnan(behaviorData.Outcome),:);
      if numel(keepIdx)~=size(behaviorData,1)
      
         fprintf(...
            'Could not match rate and behaviorData for %s.\n',...
            rate.info(1).file(1:16)); %#ok<*SPWRN>
         out = cell(size(rate.data,3),1);
         bData = behaviorData;
         return;
      end
   end
end

keepIdx = keepIdx & ~isnan(behaviorData.Outcome);

rate.data = rate.data(keepIdx,:,:);
bData = behaviorData(keepIdx,:);

out = cell(size(rate.data,3),1);
for iCh = 1:size(rate.data,3)
   x = rate.data(:,:,iCh).';
   y = filtfilt(b,a,double(x));
   [coeff,score] = pca(y(idx,:));
   if size(coeff,2)<3
      continue;
   end
   out{iCh}.coeff = coeff(:,1:3);
   out{iCh}.score = score(:,1:3);
   out{iCh}.t = tt;
   out{iCh}.Mdl = fitcsvm(coeff(:,1:3),bData.Outcome);
   
end

end