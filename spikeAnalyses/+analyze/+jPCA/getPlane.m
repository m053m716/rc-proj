function [p,pTrials,Mplane] = getPlane(data,i,varargin)
%GETPLANE Return plane `i` from data struct or matrix
%
% p = analyze.jPCA.getPlane(data,i);
% [p,pTrials,Mplane] = analyze.jPCA.getPlane(data,i);
% [__] = analyze.jPCA.getPlane(data,i,'Name',value,...);
%
% Inputs
%  data    - Can be either 
%              * A data matrix where rows are time-samples and columns are 
%                (projected) jPC scores 
%                 + (i.e. PC scores transformed by Mskew from jPCA)
%  
%              * Struct array with `proj` field, each element representing
%                an individual trial (`Projection` output from `jPCA`)
%  i       - Index of plane to recover
%              * If not provided, defaults to return primary plane
%  <'Name',value> - Pairs of parameter arguments:
%                    * 'DataField' (default: 'proj') -- Determines field of
%                       `data` to use for retrieving projection data.
% Output
%  p       - nSamples x 2 array corresponding to plane i
%  pTrials - struct array with `plane` field, where each element is a
%              single trial (similar to struct format of input). Requires
%              that input is given as struct array.
%  Mplane  - Projection matrix for rotations specific to this plane.

pars = struct;
pars.DataField = 'proj';
pars.PrimaryPlaneDefault = 1;

fn = fieldnames(pars);
for iV = 1:2:numel(varargin)
   idx = ismember(fn,lower(varargin{iV}));
   if sum(idx) == 1
      pars.(fn{idx}) = varargin{iV+1};
   end
end

if nargin < 2
   i = pars.PrimaryPlaneDefault;
end

% Format data
if isstruct(data)
   P = vertcat(data.(pars.DataField));
else
   P = data;
end

% Retrieve plane
p = P(:,[2*(i-1)+1, 2*i]);
if (nargout < 2) || ~isstruct(data)
   pTrials = struct('plane',p);
   return;
end

nSample = size(data(1).proj,1);
nTrial = numel(data);
nCol = size(p,2);
plane = mat2cell(p,ones(1,nTrial).*nSample,nCol);
pTrials = data;
[pTrials.plane] = deal(plane{:});

% Recover mask vector to prevent issue with taking difference of first and
% last sample of consecutive trials:
T1 = repmat([true(nSample-1,1); false],nTrial,1);
T2 = repmat([false; true(nSample-1,1)],nTrial,1);

% Get "state" and difference in state:
state = (p(T2,:) + p(T1,:)) / 2;
dstate = p(T2,:) - p(T1,:);

Mplane = analyze.jPCA.skewSymRegress(dstate,state)';

SStot = sum(sum(bsxfun(@minus,dstate,mean(dstate,1)).^2));
SSreg = sum(bsxfun(@minus,state*Mplane,mean(dstate,1)).^2);
R2 = SSreg./SStot;

err_orig = rms(dstate-state,1);
err_recon = rms(dstate-(state * Mplane),1);

fprintf(1,'<strong>Original Error RMS</strong>:\n');
fprintf(1,'->\t%7.5f\t%7.5f\n',err_orig);
fprintf(1,'<strong>Reconstruction Error RMS</strong>:\n');
fprintf(1,'->\t%7.5f\t%7.5f\n',err_recon);
fprintf(1,'<strong>Coefficient of Determination</strong>:\n');
fprintf(1,'->\t%7.5f\t%7.5f\n',R2);

plane_proj = p * Mplane;

state = mat2cell(state,ones(1,nTrial).*(nSample-1),nCol);
[pTrials.state_plane] = deal(state{:});

dstate = mat2cell(dstate,ones(1,nTrial).*(nSample-1),nCol);
[pTrials.dstate_plane] = deal(dstate{:});

plane_proj = mat2cell(plane_proj,ones(1,nTrial).*nSample,nCol);
[pTrials.plane_proj] = deal(plane_proj{:});

end