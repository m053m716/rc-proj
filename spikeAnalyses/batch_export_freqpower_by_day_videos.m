%% BATCH_EXPORT_FREQPOWER_BY_DAY_VIDEOS


%%
if exist('gData','var')==0
   group.loadGroupData;
end

%%
exportSkullPlotMovie(gData);
exportSkullPlotMovie(gData,2); % Use 2-Hz band for "low-frequency oscillations"
exportSkullPlotMovie(gData,9); % Use 9-Hz band for "high-frequency oscillations" (terrible name)