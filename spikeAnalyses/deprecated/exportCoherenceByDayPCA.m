if exist('x','var')==0
   load('All-Days-Successful-Grasp-All-Groups-All-Channels-xPCobj.mat',...
      'x','y');
end

if exist('cxy','var')==0
%    load('Cross-Days-Coherence_Data.mat','cxy','ff','iPC_m','iPC_b');
   [cxy,ff,iPC_m,iPC_b] = getChildCoherenceData(x,1000,1);
end

save_coherenceByDay_fig(cxy,'PC Coherence By Day 1000 reps Non-Matched PCs');
save_coherenceByDay_stats(cxy,'CoherenceByDayStats_x1000.xls');