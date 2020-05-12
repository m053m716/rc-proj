%% CHECK FOR CORRECT VARIABLES AND LOAD IF NEEDED
if exist('gData','var')==0
   load('gData.mat','gData');
end
% Use the first week to relate the rest of the signal
poDay = 3:28;
[x,y] = build_xPCobj(gData,poDay,false);

%%
fprintf(1,'Computing coherence...\n');
[cxy,ff,iPC_m,iPC_b] = getChildCoherenceData(x,100,1);
fprintf(1,'-->\tcomplete.\n');

%%
save_coherenceByDay_fig(cxy,'Cross-Day Coherence - All Rats - All Channels',...
      'G:\Lab Member Folders\Max Murphy\Writing\_MANUSCRIPTS\2019-11-12_RC_Nat-Comms\Figures\PCA\Cross-Day-Coherence',...
      [],poDay);