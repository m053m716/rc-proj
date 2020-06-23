function G = batch_estimate_reconstruction_error(G,T,subset)
%BATCH_ESTIMATE_RECONSTRUCTION_ERROR Redo reconstruction error estimate
%
%  G = analyze.stat.batch_estimate_reconstruction_error(G,T);
%  G = analyze.stat.batch_estimate_reconstruction_error(G,T,subset);
%
% Inputs
%  G      - Table recovered using analyze.stat.get_fitted_table
%  T      - Original table where each row is a trial rate
%  subset - (Optional) Vector of indices (rows) to do estimation on. If not
%                       specified, default is all rows of `G`
%
% Output
%  G      - Updated table with correct error estimates

if nargin < 3
   subset = 1:size(G,1);
else
   subset = reshape(subset,1,numel(subset));
end

P = [G.PeakOffset, G.PeakFreq, G.EnvelopeBW ./ G.PeakFreq];
t = G.Properties.UserData.t;

for iRow = subset
   iOriginal = strcmp(T.Properties.RowNames,G.Properties.RowNames{iRow});
   [~,G.Error_SS(iRow)] = analyze.stat.reconstruct_gauspuls(...
      T.Rate(iOriginal,:),t,P(iRow,:),true);
end

end