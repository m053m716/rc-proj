%% BATCH_EXPORT_PC_COHERENCE  Batch script to execute cross-day coherence on PCs analysis

%% CHECK FOR CORRECT VARIABLES AND LOAD IF NEEDED
if exist('gData','var')==0
   load('gData.mat','gData');
end
group = {gData.Name}.';
poDay = 3:28;

if exist('x','var')==0
   fprintf(1,'Loading xPCobj (x)...\n');
%    [x,y] = build_xPCobj(gData,poDay); % Alternatively, build it
%    save('All-Days-Successful-Grasp-All-Groups-All-Channels-xPCobj.mat','x','y','-v7.3');
   load('All-Days-Successful-Grasp-All-Groups-All-Channels-xPCobj.mat','x','y');
   clc;
   fprintf(1,'\t-->\tx loaded successfully\t<--\n');
end

%%