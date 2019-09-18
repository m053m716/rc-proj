function P = thresholdDLClabs(T,varargin)
%% THRESHOLDDLCLABS  Pare down DeepLabCut data based on likelihood
%
%  P = THRESHOLDDLCLABS(T);
%  P = THRESHOLDDLCLABS(T,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%     T        :     Table extracted using RLM_IMPORTDEEPLABCUTLABELING
%
%  varargin    :     (Optional) 'NAME', value input argument pairs.
%  --------
%   OUTPUT
%  --------
%     P        :     Struct that has converted data with thresholds from
%                    marker likelihoods estimated by DeepLabCut.
%
% By: Max Murphy  v1.0  07/23/2018  Original version (R2017b)

%% DEFAULTS
MARKER_THRESH = 0.00;         % Exclude markers below this threshold
SUPPORT_THRESH = 0.95;        % Exclude support hand if it's below this
PELLET_THRESH = 0.99;         % Exclude pellet if it's below this
FRAME_RATE = 30000/1001;      % Video framerate
DELIM = '_';                  % Delimiter for different variable name info

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% GET TIME VECTOR
t = T.frame ./ FRAME_RATE;

%% GET VARIABLE NAMES TO ORGANIZE INTO DATA STRUCTURE
v = T.Properties.VariableNames(2:end);

%% LOOP THROUGH SETS OF 3 (X, Y, LIKELIHOOD; REPEAT)
P = struct('t',t);
for ii = 1:3:numel(v)
   name = strsplit(v{ii},DELIM);
   switch numel(name)
      case 2
         marker = name{1};
         location = 'proximal';
      case 3
         marker = name{1};
         if strcmp(name{2},'p')
            location = 'proximal';
         else
            location = 'distal';
         end
      otherwise
         error('Unknown naming convention. Check DELIM (currently: %s)',...
            DELIM);
   end
   p = T.(v{ii+2});
   y = T.(v{ii+1});
   x = T.(v{ii});
   if strcmp(v{ii},'pellet')
      y(p < PELLET_THRESH) = nan;
      x(p < PELLET_THRESH) = nan;
      p(p < PELLET_THRESH) = nan;
   elseif strcmp(v{ii},'support')
      y(p < SUPPORT_THRESH) = nan;
      x(p < SUPPORT_THRESH) = nan;
      p(p < SUPPORT_THRESH) = nan;
   else
      y(p < MARKER_THRESH) = nan;
      x(p < MARKER_THRESH) = nan;
      p(p < MARKER_THRESH) = nan;
   end
   
   if isfield(marker,P)
      P.(marker) = struct(location, struct('x',x,'y',y,'p',p));
   else
      P.(marker).(location) = struct('x',x,'y',y,'p',p);
   end
   
end

end