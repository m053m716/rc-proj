function Projection = updateState(Projection,M,rot)
%UPDATESTATE Update `state_rot` field of Projection data struct array
%
%  Projection = analyze.jPCA.updateState(Projection,M,rot);
%
%  Inputs
%     Projection - Data struct array output from `analyze.jPCA.jPCA`
%     M          - Projection matrix (e.g. jPCs)
%     rot        - Rotation matrix to apply to `M` (if not supplied, just
%                    applies `M` directly to data using `rot` as identity
%                    matrix)
%
%  Output
%     Projection - Updated data struct array with `state_rot` field for
%                    each array element that reflects the new "rotated"
%                    projection.

if nargin < 3
   rot = eye(size(M,2));
end

scores = vertcat(Projection.state);
Mrot = (M * rot);
Mrot = Mrot ./ rms(Mrot,1) .* rms(M,1);
proj = real(scores * Mrot);

nTrial = numel(Projection);
[nRow,nCol] = size(Projection(1).state);
proj = mat2cell(proj,ones(1,nTrial).*nRow,nCol);
[Projection.proj_rot] = deal(proj{:});

end