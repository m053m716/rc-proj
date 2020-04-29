function doBinSmoothing(obj,w)
%DOBINSMOOTHING  Smooth spike rates
%
%  doBinSmoothing(obj,w); (deprecated)
%  --> If `w` not specified, uses value in
%        `defaults.block('spike_smoother_w');
%
%   -> Note: This smooths the histogram data and applies a
%              square-root transformation to the smoothed data in
%              order to help with the distribution skew.

W = defaults.block('spike_bin_w');
if nargin < 2 % Smooth width, in bin indices
   w = round(defaults.block('spike_smoother_w')/W);
end

[ALIGN,EVENT] = defaults.block('all_alignments','all_events');
outpath = obj.getPathTo('spikerate');
spikeRateExpr = defaults.files('spike_rate_expr');

for iE = 1:numel(EVENT)
   for iA = 1:size(ALIGN,1)
      savename = sprintf(...
         spikeRateExpr,obj.Name,w,...
         EVENT{iE},ALIGN{iA,1});
      
      if (exist(fullfile(outpath,savename),'file')==0) || ...
            defaults.block('overwrite_old_spike_data')
         
         [data,t] = obj.loadBinnedSpikes(EVENT{iE},ALIGN{iA,1},W); %#ok<ASGLU>
         if isempty(data)
            continue;
         end
         for iCh = 1:numel(obj.ChannelInfo)
            data(:,:,iCh) = fastsmooth(sqrt(data(:,:,iCh)),w,'pg',1,1)./mode(diff(obj.T));
         end
         
         if exist(outpath,'dir')==0
            mkdir(outpath);
         end
         save(fullfile(outpath,savename),'data','t');
         fprintf(1,'-->\tSaved %s\n',savename);
      end
   end
end


end
