%% CHECK FOR CORRECT VARIABLES AND LOAD IF NEEDED
if exist('gData','var')==0
   load('gData.mat','gData');
end
% Use the first week to relate the rest of the signal
[x,y] = build_xPCobj(vertcat(gData.Children),7:14);

%%
fprintf(1,'Computing coherence...\n');
[cxy,ff,iPC_m,iPC_b] = getChildCoherenceData(x,1000,1);
fprintf(1,'-->\tcomplete.\n');

%%
r = vertcat(gData.Children);
for i = 1:numel(x)
   save_coherenceByDay_fig(cxy{i},...
      [r(i).Name ' Cross-Day PC Coherence'],...
      'G:\Lab Member Folders\Max Murphy\Writing\_MANUSCRIPTS\2019-11-12_RC_Nat-Comms\Figures\PCA\Cross-Day-Coherence\By Rat',...
      [],vertcat(x(i).Children.StartDay));
end
