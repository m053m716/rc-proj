function [avgRate,channelInfo] = getAvgSpikeRate(obj,align,outcome,ch)
%GETAVGSPIKERATE   Return spike rate data and associated metadata
%
%  (deprecated)
%
%  [avgRate,channelInfo] = obj.getAvgSpikeRate(align,outcome,ch);

if nargin < 4
   ch = nan;
end
if nargin < 3
   outcome = 'Successful'; % 'Successful' or 'Unsuccessful' or 'All'
end
if nargin < 2
   align = 'Grasp'; % 'Grasp' or 'Reach'
end

if numel(obj) > 1
   avgRate = [];
   channelInfo = [];
   for ii = 1:numel(obj)
      [tmpRate,tmpCI] = getAverageSpikeRate(obj(ii),align,outcome,ch);
      avgRate = [avgRate; tmpRate]; %#ok<*AGROW>
      channelInfo = [channelInfo; tmpCI];
   end
   return;
end

if isnan(ch)
   ch = 1:numel(obj.ChannelInfo);
end

obj = obj([obj.HasData]);
avgRate = [];
channelInfo = [];
filter_order = defaults.block('lpf_order');
fs = defaults.block('fs');
cutoff_freq = defaults.block('lpf_fc');
if ~isnan(cutoff_freq)
   [b,a] = butter(filter_order,cutoff_freq/(fs/2),'low');
end

avgRate = nan(numel(ch),numel(obj.T));
channelInfo = [];
idx = 0;
for iCh = ch
   idx = idx + 1;
   channelInfo = [channelInfo; obj.ChannelInfo(iCh)];
   if obj.ChannelMask(iCh)
      if isfield(obj.Data,align)
         if isfield(obj.Data.(align),outcome)
            x = obj.Data.(align).(outcome).rate(:,:,iCh);
         else
            fprintf('No %s rate extracted for %s alignment for block %s. Extracting...\n',...
               outcome,align,obj.Name);
            obj.updateSpikeRateData(align,outcome);
            if ~isfield(obj.Data.(align),outcome)
               continue;
            end
            x = obj.Data.(align).(outcome).rate(:,:,iCh);
         end
      else
         fprintf('No %s rate extracted for block %s. Extracting...\n',...
            align,obj.Name);
         obj.updateSpikeRateData(align,outcome);
         if ~isfield(obj.Data,align)
            continue;
         elseif ~isfield(obj.Data.(align),outcome)
            continue;
         end
         x = obj.Data.(align).(outcome).rate(:,:,iCh);
      end
      
      mu = mean(x,1); %#ok<*PROPLC,*PROP>
      
      if isnan(cutoff_freq)
         avgRate(idx,:) = mu;
      else
         avgRate(idx,:) = filtfilt(b,a,mu);
      end
   end
end

end