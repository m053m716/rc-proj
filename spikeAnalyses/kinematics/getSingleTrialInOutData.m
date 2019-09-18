function trialData = getSingleTrialInOutData(T,data,name,day,k)
%% GETSINGLETRIALINOUTDATA   Get "input" (rate) and "output" (kinematic) data for trial k.
%
%  trialData = GETSINGLETRIALINOUTDATA(T,data);
%  trialData = GETSINGLETRIALINOUTDATA(T,data,name,day,k);
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
%     k     :     Trial index. If not specified, selected randomly (for
%                 debug/visualization.
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
DEC_FACTOR = 5;
MODEL = {{'CFA','RFA'}; ...
   {'CFA'}; ...
   {'RFA'}};

USE = 1:16;

M_NAME = {'d1_d_x';'d1_d_y';'d1_p_x';'d1_p_y'; ...
   'd2_d_x';'d2_d_y';'d2_p_x';'d2_p_y'; ...
   'd3_d_x';'d3_d_y';'d3_p_x';'d3_p_y'; ...
   'd4_d_x';'d4_d_y';'d4_p_x';'d4_p_y'};

FC = 10;            % Lowpass filter cutoff for rate estimate
FS_RATE = 1000;     % 1/BIN_WIDTH for rate data bins
FS_KIN = 200;
FS_TARGET = 50;

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

if nargin < 5
   k = randi(numel(data),1);
end
data = data{k};

%% PRE-ALLOCATE AND LOOP
y_o = data.filt_interp(2:end,:);
y = nan(size(y_o,1)/(FS_KIN/FS_TARGET),size(y_o,2));
for ii = 1:numel(USE)
   y(:,ii) = decimate(y_o(:,ii),FS_KIN/FS_TARGET);
end

trialData = cell(numel(MODEL),1);

u_ch = unique(T.Channel);
u = nan(size(y,1),numel(u_ch));
   
Ts = 1/FS_TARGET;
in_name = cell(numel(u_ch),1);
in_area = cell(numel(u_ch),1);

for ii = 1:numel(u_ch)
   C = T(ismember(T.Channel,u_ch(ii)),:);
   
   tmp = C.rate{k};
   tmp = rlm_LPF(tmp,FC,FS_RATE);
   
   u(:,ii) = decimate(tmp,FS_RATE/FS_TARGET);
   in_name{ii} = sprintf('Channel_%02g_%s',C.Channel(1),C.Area{1});
   
   in_area{ii} = strsplit(C.Area{1},'-');
   in_area{ii} = in_area{ii}{2};
end

for iM = 1:numel(MODEL)

   ch_idx = ismember(in_area,MODEL{iM});
   
   trialData{iM} = iddata(y,u(:,ch_idx),Ts, ...
      'Name',sprintf('%s - Day %02g - Trial %g - %s',...
      name,day,k,strjoin(string(MODEL{iM}),'-')),...
      'TStart',data.t(2),...
      'Domain','Time',...
      'OutputName',M_NAME(USE),...
      'OutputUnit',repmat({'pixels'},numel(M_NAME(USE)),1),...
      'InputName',in_name(ch_idx),...
      'InputUnit',repmat({'spikes/s'},numel(in_name(ch_idx)),1),...
      'UserData',C.Outcome(k),...
      'Notes',{sprintf('Outcome: %g',C.Outcome(k)); ...
      sprintf('Group: %s',C.Group{k})});
end

end