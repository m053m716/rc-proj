function fig = plotRates(J,rowIdx,ch,align,outcome)
%% PLOTRATES  Plot rates for a given channel, alignment, and outcome
%
%  fig = PLOTRATES(J,rowIdx,ch,align,outcome);
%
% By: Max Murphy  v1.0  2019-06-14  Original version (R2017a)

%%

if nargin < 5
   outcome = 'All';
end

if nargin < 4
   align = 'Grasp';
end

%%
rate = J.Data(rowIdx).(align).(outcome).rate(:,:,ch);

chInfo = J.ChannelInfo{rowIdx}(ch);
chan = chInfo.channel;
probe = chInfo.probe;

%%
fig = figure('Name',sprintf('%s: Rate: Channel %g-%g %s %s',...
                     J.Name{rowIdx},probe,chan,outcome,align),...
            'Color','w',...
            'Units','Normalized',...
            'Position',[0.1 0.1 0.8 0.8]);

t = linspace(-2000,1000,size(rate,2));

plot(t,rate,...
   'Color',[0.94 0.94 0.94],...
   'LineWidth',2,...
   'ButtonDownFcn',@lineCallback);
xlim([-250 250]);

end