function [Proj,offset] = zeroCenterPoints(Proj,iZero)
%ZEROCENTERPOINTS  Ensures that element "zero_index" starts at 0
%
% [Proj,offset] = analyze.jPCA.zeroCenterPoints(Proj,izero);
%
% Inputs
%  Proj   - Array element from `Projection` struct array, or a data matrix
%              where times are rows and columns are channels (or variables)
%  iZero  - Index corresponding to time to use as "zero center" for rest of
%              array.
%
% Output
%  Proj        - Matrix or struct with `'proj'` field, which has been
%                 offset to be centered about some "state" which is one of
%                 the time-sample values for each channel (column)
%  offset      - Amount that `proj` was offset by

if isstruct(Proj)
   if ~isscalar(Proj)
      if isscalar(iZero)
         iZero = repelem(iZero,numel(Proj));
      end
      offset = nan(numel(Proj),size(Proj(1).proj,2));
      for iProj = 1:numel(Proj)
         [Proj(iProj),offset(iProj,:)] = analyze.jPCA.zeroCenterPoints(...
            Proj(iProj),iZero(iProj));
      end
      return;
   end
   if isnan(iZero)
      offset = ones(1,size(Proj.proj,2));
      return;
   end
   Proj.traj_offset = Proj.proj(iZero,:);
   Proj.proj = Proj.proj - repmat(Proj.traj_offset,size(Proj.proj,1),1);
   
else
   if isnan(iZero)
      offset = ones(1,size(Proj,2));
      return;
   end
   offset = Proj(iZero,:);
   Proj = Proj - repmat(offset,size(Proj,1),1);
end

end