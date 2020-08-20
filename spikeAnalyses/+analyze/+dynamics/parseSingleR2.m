function SS = parseSingleR2(Projection,et)
%PARSESINGLER2  Used to update R^2 estimate for adjusted R^2 etc using proj
%
%  SS = analyze.dynamics.parseSingleR2(Projection);
%
% Inputs
%  Projection - See analyze.jPCA, analyze.jPCA.jPCA
%
% Output
%  SS         - See analyze.jPCA.recover_explained_variance
%              -> Struct containing sum-of-squares info and R^2 values
%
% This is just to do a quick batch run and estimate R^2 adjusted for each
% data point in table `D` used in
% `population_firstorder_mls_regression_stats.m`

if nargin < 2
   et = Projection(1).SS.best.explained_pcs;
end

analyzeIndices = true(size(Projection(1).state,1),1);
tt = Projection(1).times;
scores = vertcat(Projection.state);
numTrials = numel(Projection);

% Apply masks to get and later times within each condition
dt = mode(diff(tt)) * 1e-3; % Convert to seconds
% these are used to take the derivative
T1 = [true(sum(analyzeIndices)-1,1); false];
T2 = [false; true(sum(analyzeIndices)-1,1)];
maskT1 = repmat(T1,numTrials,1);  % skip the last time for each condition
maskT2 = repmat(T2,numTrials,1);  % skip the first time for each condition


[~,~,~,~,~,SS] = analyze.jPCA.get_projection_matrix(scores,maskT1,maskT2,dt,et,0);



end