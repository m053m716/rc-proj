function c = makeTrialCondition(data,T,times,allTimes,PCs,jPCs_highD,mu,norms)

if nargin < 7
   mu = zeros(size(data,2));
end

if nargin < 8
   norms = ones(size(data,2));
end

if isempty(data)
   c = [];
   return;
end

TOL = 10; %ms

pre_trial_norm = defaults.block('pre_trial_norm');
data = sqrt(abs(data));
data = (data - mean(data(pre_trial_norm,:),1))...
         ./(std(data(pre_trial_norm,:),[],1)+1);

filter_order = defaults.block('lpf_order');
fs = 1/(defaults.block('spike_bin_w')*1e-3);
cutoff_freq = defaults.block('lpf_fc');
if ~isnan(cutoff_freq)
   [b,a] = butter(filter_order,cutoff_freq/(fs/2),'low');
else
   b = nan; a = nan;
end
jpca_decimation_factor = defaults.jPCA('jpca_decimation_factor');
jpca_start_stop_times = defaults.jPCA('jpca_start_stop_times');

[~,iStart] = min(abs(T - jpca_start_stop_times(1)));
[~,iStop] = min(abs(T - jpca_start_stop_times(2)));
data = data(iStart:iStop,:);


Y = nan(ceil(size(data,1)/jpca_decimation_factor),size(data,2));
for iCh = 1:size(data,2)
   Y(:,iCh) = decimate(filtfilt(b,a,data(:,iCh)),jpca_decimation_factor);
end
T = linspace(T(iStart),T(iStop),size(Y,1));

idx_times = ismembertol(T,times,TOL,'DataScale',1);
idx_allTimes = ismembertol(T,allTimes,TOL,'DataScale',1);

c = struct(...
   'proj',{(Y(idx_times,:)./norms-repmat(mu,sum(idx_times),1)) * jPCs_highD},...
   'times',{times},...
   'projAllTimes',{(Y(idx_allTimes,:)./norms-repmat(mu,sum(idx_allTimes),1)) * jPCs_highD},...
   'allTimes',{allTimes},...
   'tradPCAproj',{(Y(idx_times,:)./norms-repmat(mu,sum(idx_times),1))*PCs},...
   'tradPCAprojAllTimes',{(Y(idx_allTimes,:)./norms-repmat(mu,sum(idx_allTimes),1))*jPCs_highD});

