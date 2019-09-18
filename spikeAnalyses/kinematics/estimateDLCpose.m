function pose = estimateDLCpose(P,tPellet,varargin)
%% ESTIMATEDLCPOSE    Estimate pose from DeepLabCut output table
%
%  pose = ESTIMATEDLCPOSE(P,tPellet);
%  pose = ESTIMATEDLCPOSE(P,tPellet,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%     P     :     Data table from THRESHOLDDEEPLABCUTLABELS.
%
%  tPellet  :     Vector of times for alignment from
%                 PLOTDEEPLABCUTTHRESHOLDEDOUTPUT.
%
%  varargin :     (Optional) 'NAME', value input argument pairs.
%
%  --------
%   OUTPUT
%  --------
%    pose   :     Data for different poses and their onset times.
%
% By: Max Murphy  v1.0  07/23/2018  Original version (R2017b)

%% DEFAULTS
E_PRE = 1;
E_POST = 0.5;
FRAME_RATE = 30000/1001;  % Video framerate

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% GET ALIGNMENT VECTOR
vec = round(-E_PRE*FRAME_RATE):round(E_POST*FRAME_RATE);

idx = nan(numel(tPellet),numel(vec));
for iT = 1:numel(tPellet)
   idx(iT,:) = vec + round(tPellet(iT)*FRAME_RATE);
end
tPellet(idx(:,1) < 1 | idx(:,end) > max(round(FRAME_RATE*P.t))) = [];
idx(idx(:,1) < 1 | idx(:,end) > max(round(FRAME_RATE*P.t)),:) = [];

%% LOOP AND GET PERIODS AROUND tPellet
v = fieldnames(P);
v = v(2:end);

varname = [];
X = [];
Y = [];
ii = 0;
for iV = 1:numel(v)
   l = fieldnames(P.(v{iV}));
   for iL = 1:numel(l)
      ii = ii + 1;
      varname{ii,1} = [v{iV} '_' l{iL}];  %#ok<*AGROW>
      X{ii,1} = P.(v{iV}).(l{iL}).x(idx);
      Y{ii,1} = P.(v{iV}).(l{iL}).y(idx);
   end
end

pose = [];

for iT = 1:numel(tPellet)
   p = struct;
   p.ts = tPellet(iT);
   p.frame = idx(iT,:);
   for iV = 1:numel(varname)
      p.([varname{iV} '_x']) = X{iV}(iT,:);
      p.([varname{iV} '_y']) = Y{iV}(iT,:);
   end
   pose = [pose; p];
end


end