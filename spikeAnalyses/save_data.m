%% SAVE ALL RELEVANT DATA OBJECTS

clc; tic;
fprintf(1,'Saving gData...');
save('gData.mat','gData','xPC','pcFitObj','-v7.3');
fprintf(1,'complete.\n-->\t');
toc;