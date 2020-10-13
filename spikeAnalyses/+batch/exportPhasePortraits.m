function exportPhasePortraits(E3,n,outPath)
%EXPORTPHASEPORTRAITS Batch export phase portrait for top Linearized Plane
%
%  batch.exportPhasePortraits(E3);
%  batch.exportPhasePortraits(E3,n,outPath);
%
% Inputs
%  E3      - Table with linearized dynamics info and fixed point classifications
%  n       - (Optional) # of random sub-samples to export (default: 10)
%              -> Set to inf to export all
%  outPath - (Optional) name of directory where figures will be saved.
%
% Output
%  Batch save of figures to specified directory of `outPath`. Iterates on
%  each row of E3 for which FP_Dim == 2
%
% See also: Contents, population_firstorder_mls_regression_stats,
%              analyze.dynamics

if nargin < 2
   n = 10;
end

if nargin < 3
   outPath = 'D:\MATLAB\Data\RC\2020_FIXED-POINTS_CLASSIFICATIONS\Phase Portraits';
end

if exist(outPath,'dir')==0
   mkdir(outPath);
end

E3 = E3(E3.FP_Dim==2,:);

if isinf(n)
   vec = 1:size(E3,1);
else
   vec = randsample(size(E3,1),n);
end

if iscolumn(vec)
   vec = vec';
end

for iRow = vec
   titlestr = [sprintf('%s Day-%02d %s: %s',...
                  E3.AnimalID(iRow),...
                  E3.PostOpDay(iRow),...
                  E3.Alignment(iRow),...
                  E3.FP_Classification(iRow)), newline, ...
               sprintf('(R^2 = %0.2f | Score = %5.2f%%)',...
                  E3.FP_VarCapt(iRow)./100,...
                  100*(atanh(E3.Performance(iRow)./(2*pi))+0.5))];
   fname = fullfile(outPath,sprintf('Example FP - %s - %s Day-%02d %s',...
            E3.FP_Classification(iRow),...
            E3.AnimalID(iRow),...
            E3.PostOpDay(iRow),...
            E3.Alignment(iRow)));
   analyze.dynamics.plotPhaseQuiver(E3.FP_M{iRow},...
      'Title',titlestr,'FileName',fname);
   
end


end