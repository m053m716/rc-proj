function [locs_C,locs_D,D,mu,exclusions] = get_exclusions(C,exclusions)
%GET_EXCLUSIONS  Get locations (indices) for excluded NNMF Blocks
%
%  [locs_C,locs_D,D,mu,exclusions] = analyze.nnm.get_exclusions(C);
%
%  -- Inputs --
%  C : Second output arg from `[N,C] = analyze.nnm.nnmf_table(T);`
%
%  -- Output --
%  locs_C : "Locations" (indices) of indices (blocks) to exclude from C
%           -> Based on cross-correlation of factor with `h0`
%  locs_D : Same as above, but based on RMS difference of NNMF fit
%  D      : Main diagonal values as columns for each index of C in terms of
%              cross-correlation matrices for h0 match
%  mu     : Average of D (mean(D,1))
%  exclusions : Struct with exclusions info

[TH_CORR,TH_D] = defaults.nnmf_analyses(...
   'corr_threshold','rms_diff_threshold');

if nargin < 2
   exclusions = struct; % Allows you to append to existing exclusions
end

D = cellfun(@diag,C.NNMF_XCorr,'UniformOutput',false);
D = horzcat(D{:});
mu = mean(D,1);

[pks_C,locs_C] = findpeaks(-(mu-1),'MinPeakHeight',1-TH_CORR);
[~,iPk] = sort(pks_C,'descend');
locs_C = locs_C(iPk);

[pks_D,locs_D] = findpeaks(C.NNMF_D,'MinPeakHeight',TH_D);
[~,iPk] = sort(pks_D,'descend');
locs_D = locs_D(iPk);


exclusions.Factor_Cross_Correlation = struct(...
   'Threshold',TH_CORR,...
   'N',numel(locs_C),...
   'Indices',locs_C...
   );
exclusions.RMS_Diff = struct(...
   'Threshold',TH_CORR,...
   'N',numel(locs_D),...
   'Indices',locs_D...
   );

locs_total = union(locs_C,locs_D);
exclusions.Total = struct(...
   'N',numel(locs_total),...
   'Indices',locs_total...
   );


end