function [avgRate,channelInfo,t] = getAvgNormRate(obj,align,outcome,ch,updateAreaModulations)
%GETAVGNORMRATE  Return (normalized) spike rate data and metadata
%
%  (Deprecated)
%
%  [avgRate,channelInfo,t] = obj.getAvgNormRate(align,outcome,ch);
%  [avgRate,channelInfo,t] = obj.getAvgNormRate(__,updateAreaModulations);
%
% avgRate : Rows are channels, columns are timesteps

if nargin < 5
   updateAreaModulations = false;
end
if nargin < 4
   ch = nan;
end
if nargin < 3
   outcome = 'Successful'; % 'Successful' or 'Unsuccessful' or 'All'
else
   if isstruct(outcome) % then it's includeStruct instead of outcome
      includeStruct = outcome;
      if ismember(includeStruct.Include,'Outcome')
         'Successful';
      elseif ismember(includeStruct.Exclude,'Outcome')
         'Unsuccessful';
      else
         outcome = 'All';
      end
   end
end
if nargin < 2
   align = 'Grasp'; % 'Grasp' or 'Reach'
end

if numel(obj) > 1
   avgRate = [];
   channelInfo = [];
   for ii = 1:numel(obj)
      [tmpRate,tmpCI,t] = getAvgNormRate(obj(ii),align,outcome,ch,updateAreaModulations);
      avgRate = [avgRate; tmpRate]; %#ok<*AGROW>
      channelInfo = [channelInfo; tmpCI];
   end
   return;
end

if isempty(obj.nTrialRecent)
   obj.initRecentTrialCounter;
end
obj.nTrialRecent.rate = 0;

if isnan(ch)
   ch = 1:numel(obj.ChannelInfo);
end

obj.HasAvgNormRate = false; % Reset flag to false each time method is run
avgRate = [];
channelInfo = [];
t = [];

if isfield(obj.Data,align)
   if isfield(obj.Data.(align),outcome)
      if isfield(obj.Data.(align).(outcome),'t')
         t = obj.Data.(align).(outcome).t;
      else
         fprintf('No %s trials for %s alignment for block %s.\n',...
            outcome,align,obj.Name);
         if updateAreaModulations
            obj.HasAreaModulations = false;
            obj.chMod = [];
         end
         return;
      end
   else
      fprintf('No %s rate extracted for %s alignment for block %s. Extracting...\n',...
         outcome,align,obj.Name);
      obj.updateSpikeRateData(align,outcome);
      if ~isfield(obj.Data.(align),outcome)
         fprintf('Invalid field for %s: %s\n',obj.Name,outcome);
         if updateAreaModulations
            obj.HasAreaModulations = false;
            obj.chMod = [];
         end
         return;
      end
   end
else
   obj.updateSpikeRateData(align,outcome);
   if ~isfield(obj.Data,align)
      fprintf('Invalid field for %s: %s\n',obj.Name,align);
      if updateAreaModulations
         obj.HasAreaModulations = false;
         obj.chMod = [];
      end
      return;
   elseif ~isfield(obj.Data.(align),outcome)
      fprintf('Invalid field for %s: %s\n',obj.Name,outcome);
      if updateAreaModulations
         obj.HasAreaModulations = false;
         obj.chMod = [];
      end
      return;
   else
      t = obj.Data.(align).(outcome).t;
   end
end

if ~isempty(t)
   if (max(abs(t)) < 10)
      t = t.*1e3; % Scale if it is not already scaled to ms
   end
end


avgRate = nan(numel(ch),numel(t));
channelInfo = [];
idx = 0;
fs = (1/(defaults.block('spike_bin_w')*1e-3))/defaults.block('r_ds');

for iCh = ch
   idx = idx + 1;
   channelInfo = [channelInfo; obj.ChannelInfo(iCh)];
   if obj.ChannelMask(iCh)
      x = obj.Data.(align).(outcome).rate(:,:,iCh);
      avgRate(idx,:) = obj.doSmoothOnly(x,fs);
   end
end

obj.nTrialRecent.rate = size(obj.Data.(align).(outcome).rate,1);
obj.HasAvgNormRate = true; % If the method returns successfully, set to true again

if updateAreaModulations
   obj.updateChMod(avgRate.',t,false);
end

end