%% EXPORTNNMFFIGS   Batch script to export non-negative matrix factorization figures
% 
% Not organized well yet, since may not be included.

%% CHANGE HERE
OUTPATH = 'G:\Lab Member Folders\Max Murphy\Writing\_MANUSCRIPTS\2019-11-12_RC_Nat-Comms\Figures\NNMF';

%% KEEP THIS
if exist('Wrfa','var')==0
   load('NNMF_data.mat','t','Wrfa','Wcfa','Hrfa','Hcfa');
end

save_NNMF_fig(t,Wrfa,Hrfa,'Intact RFA NNMF',OUTPATH);
save_NNMF_fig(t,Wcfa,Hcfa,'Intact CFA NNMF',OUTPATH);