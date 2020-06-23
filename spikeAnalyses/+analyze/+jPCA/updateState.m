function Projection = updateState(Projection,M,rot,fn)
%UPDATESTATE Update `state_rot` field of Projection data struct array
%
%  Projection = analyze.jPCA.updateState(Projection,M);
%     -> Apply projection matrix `M` to data in Projection.state
%  Projection = analyze.jPCA.updateState(Projection,M,'state'); 
%     -> Update 'state' field of Projection instead of 'proj_rot'
%  Projection = analyze.jPCA.updateState(Projection,M,rot);
%     -> Apply rotation matrix `rot` to M for projection
%  Projection = analyze.jPCA.updateState(Projection,M,rot,fn);
%
%  Inputs
%     Projection - Data struct array output from `analyze.jPCA.jPCA`
%     M          - Projection matrix (e.g. jPCs)
%     rot        - Rotation matrix to apply to `M` (if not supplied, just
%                    applies `M` directly to data using `rot` as identity
%                    matrix)
%     fn         - (Default: 'proj_rot'; name of field in `Projection` to
%                             store the output in)
%
%  Output
%     Projection - Updated data struct array with `state_rot` field for
%                    each array element that reflects the new "rotated"
%                    projection.

if nargin < 3
   rot = eye(size(M,2));
   fn = 'proj_rot';
elseif nargin < 4
   if ischar(rot)
      fn = rot;
      rot = eye(size(M,2));
   else
      fn = 'proj_rot';
   end   
end

scores = vertcat(Projection.state);
Mrot = (M * rot);
Mrot = Mrot ./ rms(Mrot,1) .* rms(M,1); % Scale to view on same axes
proj = real(scores * Mrot);

nTrial = numel(Projection);
[nRow,nCol] = size(Projection(1).state);
proj = mat2cell(proj,ones(1,nTrial).*nRow,nCol);
[Projection.(fn)] = deal(proj{:});

end