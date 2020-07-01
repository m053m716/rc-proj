function out = combine_cells(in,d)
%COMBINE_CELLS Helper function used by analyze.stat.prep_for_raincloudplots
%
%  out = analyze.stat.combine_cells(in,d);
%
% Inputs
%  in  - Input data cell array
%  d   - Indexing vector
%
% Output
%  out - "Combined" data cell array
%
% See also: analyze.stat.prep_for_raincloudplots

out = cell(size(in{1}));
for ii = 1:numel(in)
   out(:,d(ii)) = in{ii}(:,d(ii));
end
out = {out'};
end