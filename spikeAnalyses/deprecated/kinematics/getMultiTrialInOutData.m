function trialData = getMultiTrialInOutData(T,data,name,day)
%% GETMULTITRIALINOUTDATA   Get "input" (rate) and "output" (kinematic) mean data for all trials.
%
%  trialData = GETMULTITRIALINOUTDATA(T,data);
%  trialData = GETMULTITRIALINOUTDATA(T,data,name,day);
%
%  --------
%   INPUTS
%  --------
%     T     :     Table of rate estimates estimated in step 3.
%
%    data   :     Kinematic tracking estimated for a single recording
%                 session in step 5.
%
%    name   :     Name of animal for this recording. If not specified,
%                 selected randomly (for debug/visualization).
%
%    day    :     Recording day, relative to implant. If not specified,
%                 selected randomly (for debug/visualization).
%
%  --------
%   OUTPUT
%  --------
%  trialData :    Cell array with 3 cells. Each cell element contains:
%                 Matlab iddata object, with "inputs" and "outputs" for a
%                 given trial at a matched sample rate based on the
%                 interpolation of kinematic markers (outputs).
%
%                 trialData{1} - Full model
%                 trialData{2} - CFA model
%                 trialData{3} - RFA model
%
% By: Max Murphy v1.0   08/01/2018  Original version (R2017b)

%% DEFAULTS
MODEL = {{'CFA','RFA'}; ...
   {'CFA'}; ...
   {'RFA'}};

% USE = 4:4:16; % Actual markers to use
USE = 1:16;

FC = 10;            % Lowpass filter cutoff for rate estimate
FS_RATE = 1000;     % 1/BIN_WIDTH for rate data bins
FS_KIN = 200;
FS_TARGET = 50;

M_NAME = {'d1_d_x';'d1_d_y';'d1_p_x';'d1_p_y'; ... % Marker names
   'd2_d_x';'d2_d_y';'d2_p_x';'d2_p_y'; ...
   'd3_d_x';'d3_d_y';'d3_p_x';'d3_p_y'; ...
   'd4_d_x';'d4_d_y';'d4_p_x';'d4_p_y'};

% KNOTS = [1,50,100,150,200,250,500,550,600]; % Breakpoints for detrending
KNOTS = [1,20,120,150];

%% PARSE INPUT
if nargin < 3
   name = unique(T.Name);
   name = name{randi(numel(name),1)};
end
T = T(ismember(T.Name,name),:);

if nargin < 4
   day = unique(T.Day);
   day = day(randi(numel(day),1));
end
T = T(ismember(T.Day,day),:);


%% PRE-ALLOCATE AND LOOP

trialData = cell(numel(MODEL),1);

y_o = nan(size(data{1}.filt_interp,1)-1,numel(USE));
y = nan(size(y_o,1)/(FS_KIN/FS_TARGET),size(y_o,2));
for ii = 1:numel(USE)
   y_o(:,ii) = nanmean(cell2mat(...
      vertcat(cellfun(@(x) x.filt_interp(2:end,USE(ii)), ...
      data,'UniformOutput',false)).'),2);
   y_o(:,ii) = rlm_LPF(y_o(:,ii),FC,FS_KIN);
   y(:,ii) = decimate(y_o(:,ii),FS_KIN/FS_TARGET);
end


Ts = 1/FS_TARGET;

u_ch = unique(T.Channel);
u = nan(size(y,1),numel(u_ch));
   
in_name = cell(numel(u_ch),1);
in_area = cell(numel(u_ch),1);

for ii = 1:numel(u_ch)
   C = T(ismember(T.Channel,u_ch(ii)),:);
   
   tmp = nanmean(cell2mat(C.rate),1);
   tmp = rlm_LPF(tmp,FC,FS_RATE);
   
   u(:,ii) = decimate(tmp,FS_RATE/FS_TARGET);
   in_name{ii} = sprintf('Channel_%02g_%s',C.Channel(1),C.Area{1});
   
   in_area{ii} = strsplit(C.Area{1},'-');
   in_area{ii} = in_area{ii}{2};
end

for iM = 1:numel(MODEL)

   ch_idx = ismember(in_area,MODEL{iM});
   trendData = iddata(y,u(:,ch_idx),Ts, ...
      'Name',sprintf('%s - Day %02g - Means - %s',...
      name,day,strjoin(string(MODEL{iM}),'-')),...
      'TStart',data{1}.t(2),...
      'Domain','Time',...
      'OutputName',M_NAME(USE),...
      'OutputUnit',repmat({'pixels'},numel(M_NAME(USE)),1),...
      'InputName',in_name(ch_idx),...
      'InputUnit',repmat({'spikes/s'},numel(in_name(ch_idx)),1),...
      'Notes',sprintf('Group: %s',C.Group{1}));
   
   trialData{iM} = detrend(trendData,1,KNOTS);
end

end