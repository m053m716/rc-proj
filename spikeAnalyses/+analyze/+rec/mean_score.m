function score = mean_score(D)
%MEAN_SCORE  Return average PCA score of all components
%
%  score = analyze.rec.mean_score(D);
%  
%  -- Inputs --
%  D : Table returned from `D = analyze.nullspace.sample.grasp(x);`
%
%  -- Output --
%  score : Average PC score of all components (rows) across trials. Columns
%           are different time-series samples.

score = zeros(size(D,1),numel(D.Properties.UserData.t));
N = D.Properties.UserData.NTrial;
for iTrial = 1:N
   score = score + D.Score(:,D.Properties.UserData.TrialIndex==iTrial);
end
score = score ./ N;

end