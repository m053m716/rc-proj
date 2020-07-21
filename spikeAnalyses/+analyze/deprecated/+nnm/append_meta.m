function C = append_meta(N,C,varsToAppend)
%APPEND_META  Append metadata to `C` from `N` table
%
%  C = analyze.nnm.append_meta(N,C);
%  C = analyze.nnm.append_meta(N,C,varsToAppend);
%
%  -- Inputs --
%  N  : 1st output argument from `[N,C] = analyze.nnm.nnmf_table(T);`
%  C  : 2nd output from `[N,C] = analyze.nnm.nnmf_table(T);`
%
%  varsToAppend (optional) : Cell array of variable names in N to add to C
%
%  -- Output --
%  C  : Same as input `C`, but with appended variables containing metadata

if nargin < 3
   varsToAppend = {'Group','AnimalID','BlockID','PostOpDay','Alignment'};
end

[tmp,ileft] = outerjoin(C,N,...
   'MergeKeys',true,...
   'Type','left',...
   'Key','NNMF_Key',...
   'LeftVariables',1:(size(C,2)),...
   'RightVariables',varsToAppend);

[~,iU] = unique(ileft);
C = tmp(iU,:);

end