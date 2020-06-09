function keepIndex = recover_align_index(Data,keepTime)
%RECOVER_ALIGN_INDEX Get indices of alignment for individual trials
%
%  keepIndex = analyze.jPCA.recover_align_index
%
%  Inputs
%     Data - Array of projection data (`Projection` struct)
%     keepTime  - Time (ms) to keep (scalar or vector)
%                 -> If vector, provide as [lower_bound, upper_bound]
%
%  Output
%     keepIndex     - Cell containing index of indices matching `keepTime`,
%                      which is specific to this trial. Size of output
%                      depends on whether keepTime is a scalar or range
%                      (note that lower bound is inclusive, upper bound is
%                      exclusive).

if isnan(keepTime(1)) || isinf(keepTime(1))
   keepIndex = {nan(size(keepTime))};
   return;
end

if isscalar(keepTime)
   [~,keepIndex] = min(abs(Data.times-keepTime));
   return;
end

keepIndex = {find((Data.times >= keepTime(1)) & (Data.times <keepTime(2)))};
end