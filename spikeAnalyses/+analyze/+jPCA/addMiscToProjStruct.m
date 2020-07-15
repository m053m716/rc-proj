function P = addMiscToProjStruct(P,SS,PCs,Mskew,Mbest)
%ADDMISCTOPROJSTRUCT Add `misc` field to the main output data struct array
%
%  P = analyze.jPCA.addMiscToProjStruct(P,SS,PCs,Mskew);
%
% Inputs
%  P     - Main output (struct array) from analyze.jPCA.jPCA
%  SS    - "Sum-of-squares" struct from analyze.jPCA.jPCA output `S`
%  PCs   - `coeff` From built-in pca: the principal component coefficients
%  Mskew - Skew-symmetric projection matrix recovered for jPCA
%  
% Output
%  P     - Same output struct array, but with `misc` filled out for each
%           "trial" (condition)
%
% See also: analyze.jPCA, analyze.jPCA.jPCA, 
%  analyze.jPCA.get_projection_matrix

if nargin < 5
   Mbest = SS.best.info.M;
end

if nargin < 4
   Mskew = SS.skew.info.M;
end

% SS is a struct (see analyze.jPCA.get_projection_matrix)
misc = SS;

% PCs are just the PCA coefficients matrix, such that if we are recovering
% dX = M * X, then
% original_rates = X * PCs' + repmat(mean(original_rates,1),nSamples,1);
misc.PCs = PCs;

% Mskew is the skew-symmetric projection matrix, which has been transposed,
% so that
% dX' = X' * M;
% Where X is the principal components of the original rate data
misc.Mskew = Mskew;
misc.Mbest = Mbest;
misc = repmat({misc},numel(P),1);
[P.misc] = deal(misc{:});

end