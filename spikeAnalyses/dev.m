%DEV  Script for developmental analysis tracking
%
% 2020-05-20 -- Current analysis package: +analyze/+nullspace

%% Load database table (if needed)
if exist('T','var')==0
   load('D:\MATLAB\Data\RC\T.mat','T');
end

%% Get (full) relevant subset of data
X = analyze.nullspace.get_subset(T);

%% Make toy dataset
x = X((X.AnimalID=='RC-05') & (X.PostOpDay==3),:);
r = x(x.Alignment=='Reach',:);
