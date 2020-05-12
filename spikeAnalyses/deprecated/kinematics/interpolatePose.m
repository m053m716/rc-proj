function data = rlm_interpolatePose(pose,k,varargin)
%% RLM_INTERPOLATEPOSE  Interpolate pose struct for trial k
%
%  data = RLM_POSE2FEATURES(pose,k)
%  data = RLM_POSE2FEATURES(pose,k,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%    pose      :     Struct from RLM_ESTIMATEDEEPLABCUTPOSE.
%
%     k        :     Trial index.
%
%  varargin    :     (Optional) 'NAME', value input argument pairs.
%
%  --------
%   OUTPUT
%  --------
%    data      :     Struct containing interpolated kinematic marker data
%                    for a single trial, as well as the t-SNE results for
%                    each time point during the trial.
%
% By: Max Murphy  v1.0  07/24/2018  Original version (R2017b)

%% DEFAULTS
FRAME_RATE = 30000/1001; % Video sample rate (frames/sec)
N_INTERP = 400;          % (400 = bins of ~5 ms for -1 to +0.5 sec)
NUM_DIMENSIONS = 2;      % Number of t-SNE embedded dimensions
PERPLEXITY = 10;         % Perplexity parameter for t-SNE
EXAGGERATION = 4;        % Exaggeration parameter for t-SNE
MIN_DIM_PCT = 0.66;      % Number of dimensions needed to compute t-SNE
FC_LPF = 20;             % Low-pass filter cutoff (Hz)

ROI = nan;
ROI_TOL = 100;

EMBEDDING_TYPE = 't-SNE';

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% GET NAMES OF MARKERLESS TRACKING VARIABLES
v = fieldnames(pose);
v = v(3:end);
v(ismember(v,{'pellet_proximal_x'})) = [];
v(ismember(v,{'pellet_proximal_y'})) = [];
v(ismember(v,{'support_proximal_x'})) = [];
v(ismember(v,{'support_proximal_y'})) = [];
v(ismember(v,{'hand_proximal_x'})) = [];
v(ismember(v,{'hand_proximal_y'})) = [];

%% COMBINE INTO LARGE "FEATURE" MATRIX
t = pose(k).frame./FRAME_RATE;
tq = linspace(t(1),t(end),N_INTERP+1); % add 1 for bin edges

Z = nan(numel(tq),numel(v));
X = nan(numel(tq),numel(v));
warning('off','MATLAB:interp1:NaNstrip');
idx = true(numel(v),1);
for iV = 1:numel(v)
   z = pose(k).(v{iV});
   try
      x = rlm_LPF(z,FRAME_RATE,FC_LPF);
      Z(:,iV) = interp1(t,z,tq,'pchip');
      X(:,iV) = interp1(t,x,tq,'pchip');
   catch
      idx(iV) = false;
      fprintf(1,'\t\t-->\tMissing %s marker for trial %d.\n',v{iV},k);
   end
end
warning('on','MATLAB:interp1:NaNstrip');

%% "ZERO OUT" FEATURES THAT GO OUTSIDE OF THE ROI
if ~isnan(ROI(1))
         % [x, y, w, h]
   roi = [ROI(1) - ROI_TOL, ROI(2) - ROI_TOL, ...
          ROI(3) + 2*ROI_TOL, ROI(4) + 2*ROI_TOL];
       
   xvec = 1:2:size(Z,2);
   yvec = 2:2:size(Z,2);
   A = Z(:,xvec);
   B = Z(:,yvec);
   
   A(A < roi(1) | A > (roi(1) + roi(3))) = 0;
   B(B < roi(2) | B > (roi(2) + roi(4))) = 0;
   
   Z(:,xvec) = A;
   Z(:,yvec) = B;
       
end

%% REDUCE TIME POINTS TO LOW-DIMENSIONAL EMBEDDING
switch lower(EMBEDDING_TYPE)
   case 't-sne'
      if sum(idx) > (MIN_DIM_PCT * numel(v))
         z = tsne(Z(:,idx),...
               'NumDimensions',NUM_DIMENSIONS,...
               'Perplexity',PERPLEXITY,...
               'Exaggeration',EXAGGERATION);


      else
         EMBEDDING_TYPE = 'none';
         z = nan(numel(tq),2);
         disp('-----------------------------------------------------');
         warning('\t-->Insufficient markers to compute embeddings for trial %d.\n',k);
         disp('-----------------------------------------------------');
      end
   otherwise
      disp('-----------------------------------------------------');
      warning('\t-->EMBEDDING_TYPE [%s] not supported.\n',EMBEDDING_TYPE);
      disp('Switching to t-SNE instead.');
      disp('-----------------------------------------------------');
      if sum(idx) > (MIN_DIM_PCT * numel(v))
         EMBEDDING_TYPE = 't-SNE';
         z = tsne(Z(:,idx),...
               'NumDimensions',NUM_DIMENSIONS,...
               'Perplexity',PERPLEXITY,...
               'Exaggeration',EXAGGERATION);


      else
         EMBEDDING_TYPE = 'none';
         z = nan(numel(tq),2);
         disp('-----------------------------------------------------');
         warning('\t-->Insufficient markers to compute embeddings for trial %d',k);
         disp('-----------------------------------------------------');
      end
end
   
%% FORMAT OUTPUT
data = struct('interp',Z,...
              'filt_interp',X,...
              'embedded',z,...
              'embedding_type',EMBEDDING_TYPE,...
              't',tq.'-pose(k).ts,...
              'onset',pose(k).ts,...
              'fc',FC_LPF);

end
