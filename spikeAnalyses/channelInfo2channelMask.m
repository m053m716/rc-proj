function ChannelMask = channelInfo2channelMask(ChannelInfo)
%% CHANNELINFO2CHANNELMASK  Helper function to infer channel mask from info
%
%  ChannelMask = CHANNELINFO2CHANNELMASK(ChannelInfo);
%
% By: Max Murphy  v1.0  2019-06-12  Original version (R2017a)

%%
p = [ChannelInfo.probe];
ch = [ChannelInfo.channel];

ChannelMask = false(32,1); % Starts with all 32 channels OFF

ch_idx = ch + (p-1).*16;  % Map the probe/channel combo to mask index

ChannelMask(ch_idx) = true; % Turn the corresponding channels ON


end